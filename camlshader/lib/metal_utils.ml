open Metal
open Ctypes

type pixel = int * int * int * int

type gpu_state = {
  w : int;
  h : int;
  tk : int;
  pxl_buff : Buffer.t;
  dim_buff : Buffer.t;
  devc : Device.t;
  cmdq : CommandQueue.t;
}

(*** Initialization Functions ***)
let build_default_device () = Device.create_system_default ()
let build_command_queue device = CommandQueue.on_device device

(*
  Updates the size of pixel_buffer = width * height * 4 
  Updates the dim buffer with new width and height
*)

let set_i32 bptr x pos = bptr +@ pos <-@ Signed.Int32.of_int x

let set_i32_xyz buffer x y z =
  let bptr = Buffer.contents buffer |> coerce (ptr void) (ptr int32_t) in
  set_i32 bptr x 0;
  set_i32 bptr y 1;
  set_i32 bptr z 2;
  buffer

let build_pxl_buff devc w h =
  Buffer.on_device devc ~length:(w * h * 4) ResourceOptions.storage_mode_shared

let build_dim_buff devc w h tk =
  let buffer =
    Buffer.on_device devc
      ~length:(sizeof uint32_t * 3)
      ResourceOptions.storage_mode_shared
  in
  set_i32_xyz buffer w h tk

let build_gpu_state w h =
  let devc = build_default_device () in
  let cmdq = build_command_queue devc in
  let pxl_buff = build_pxl_buff devc w h in
  let dim_buff = build_dim_buff devc w h 0 in
  { w; h; tk = 0; devc; cmdq; pxl_buff; dim_buff }

let resize_state_buffers state w h =
  let pxl_buff = build_pxl_buff state.devc w h in
  let dim_buff = build_dim_buff state.devc w h 0 in
  { state with w; h; tk = 0; pxl_buff; dim_buff }

(* Creates a big array from Metal Buffer of uchar4 *)
let bigarray_of_uchar4 pixel_buffer w h =
  let elmsize = 4 in
  (* uchar4 contains 4 unsigned chars -- NOTE im leaving this as char because it compiles... *)
  let count = w * h * elmsize in
  let pxls_ptr = Buffer.contents pixel_buffer |> coerce (ptr void) (ptr char) in
  bigarray_of_ptr Ctypes.array1 count Bigarray.Char pxls_ptr

let incr_tk state = { state with tk = state.tk + 1 }

(***
  Encodes a new command buffer with state details
  and commits the command to metal. Returns a
  bigarray of type char
***)
let run_compute_pipeline state pipeline =
  let cmd_buff = CommandBuffer.on_queue state.cmdq in
  let cmp_encr = ComputeCommandEncoder.on_buffer cmd_buff in

  (*** TODO: move this hack ***)
  let bptr =
    Buffer.contents state.dim_buff |> coerce (ptr void) (ptr int32_t)
  in
  set_i32 bptr state.tk 2;

  ComputeCommandEncoder.set_compute_pipeline_state cmp_encr pipeline;
  ComputeCommandEncoder.set_buffer cmp_encr state.pxl_buff ~index:0;
  ComputeCommandEncoder.set_buffer cmp_encr state.dim_buff ~index:1;

  let w_group = 16 in
  let h_group = 16 in

  ComputeCommandEncoder.dispatch_threadgroups cmp_encr
    ~threadgroups_per_grid:
      {
        width = (state.w + w_group - 1) / w_group;
        height = (state.h + h_group - 1) / h_group;
        depth = 1;
      }
    ~threads_per_threadgroup:{ width = w_group; height = h_group; depth = 1 };

  ComputeCommandEncoder.end_encoding cmp_encr;
  CommandBuffer.commit cmd_buff;
  CommandBuffer.wait_until_completed cmd_buff;
  let pxls = bigarray_of_uchar4 state.pxl_buff state.w state.h in
  (pxls, state.w * 4)
