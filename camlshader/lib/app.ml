
type app_state = {
	sdls : Sdl_utils.sdl_state;
	shaders : Shader_utils.shader_library_state;
	gpus : Metal_utils.gpu_state;
  running : bool;
}

let build_default_app () = 
	let name = "caml shader" in
	let width = 800 in
	let height = 640 in
	match Sdl_utils.build_default_sdl_state name width height with
	| None -> None
	| Some sdls -> (
		let gpus = Metal_utils.build_gpu_state width height in
		match Shader_utils.build_default_library_state gpus.devc with
		| None -> Sdl_utils.destroy_sdl_state sdls; (* todo: destroy_gpu_state *) None
		| Some shaders -> Some { sdls; shaders; gpus; running=true }
	)

let destroy_app state = Sdl_utils.destroy_sdl_state state.sdls (* todo: destroy_gpu_state *)

(*** event handlers ***)

let handle_event state event = 
	let open Tsdl in
	let open Sdl.Event in
  let event_type_id = get event typ in
  match enum event_type_id with
  | `Quit -> { state with running=false }
  | `Key_down ->
		let keycode = get event keyboard_keycode in
	  if keycode = Sdl.K.escape then { state with running=false }
		else begin 
			let sdls = Sdl_utils.handle_keydown state.sdls keycode in
			{ state with sdls }
		end
  | `Key_up ->
		let keycode = get event keyboard_keycode in
		let sdls = Sdl_utils.handle_keyup state.sdls keycode in
		{ state with sdls }
  | `Mouse_motion ->
	  let x = get event mouse_motion_x in
	  let y = get event mouse_motion_y in
	  state.sdls.mouse := (x, y); (* i think this usage of ref is okay *)
	  let gpus = Metal_utils.incr_tk state.gpus in
	  { state with gpus }
  | `Window_event -> (
		let eid = get event window_event_id in
	  match window_event_enum eid with
	  | `Resized -> (
	      let w, h = Sdl.get_window_size state.sdls.win in
	      match Sdl_utils.resize_texture state.sdls w h with
	      | None -> { state with running=false }
	      | Some sdls ->
		      let gpus = Metal_utils.resize_state_buffers state.gpus w h in
					{ state with gpus; sdls }
				)
	  | _ -> state
  )
  | _ -> state


