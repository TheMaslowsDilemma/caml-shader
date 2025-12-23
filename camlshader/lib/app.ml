open App_utils

let build_default_app () =
  let name = "caml shader" in
  let width = 800 in
  let height = 640 in
  let scenes = Scene_utils.build_default_scene () in
  match Sdl_utils.build_default_sdl_state name width height with
  | None -> None
  | Some sdls -> (
      let gpus = Metal_utils.build_gpu_state width height scenes in
      match Shader_utils.build_default_library_state gpus.devc with
      | None ->
          Sdl_utils.destroy_sdl_state sdls;
          None (* todo: destroy_gpu_state *)
      | Some shaders -> Some { scenes; sdls; shaders; gpus; running = true })

(*** Handle Events ***)
let handle_event state event =
  let open Tsdl in
  let open Sdl.Event in
  let event_type_id = get event typ in
  match enum event_type_id with
  | `Quit -> { state with running = false }
  | `Key_down ->
      let keycode = get event keyboard_keycode in
      if keycode = Sdl.K.escape then { state with running = false }
      else begin
        let sdls = Sdl_utils.handle_keydown state.sdls keycode in
        { state with sdls }
      end
  | `Key_up ->
      let keycode = get event keyboard_keycode in
      let sdls = Sdl_utils.handle_keyup state.sdls keycode in
      { state with sdls }
  | `Mouse_motion ->
      let dx = get event mouse_motion_xrel in
      let dy = get event mouse_motion_yrel in
      state.sdls.mouse_delta := (dx, dy);
      state
  | `Window_event -> (
      let eid = get event window_event_id in
      match window_event_enum eid with
      | `Resized -> (
          let w, h = Sdl.get_window_size state.sdls.win in
          match Sdl_utils.resize_texture state.sdls w h with
          | None -> { state with running = false }
          | Some sdls ->
              let gpus = Metal_utils.resize_state_buffers state.gpus w h in
              { state with gpus; sdls })
      | _ -> state)
  | _ -> state

let apply_step state =
  let updated_state =
    App_utils.(
      apply_mouse_actions (apply_keyboard_actions state default_actions))
  in
  let gpus = Metal_utils.update_scn_buff state.gpus state.scenes in
  { updated_state with gpus }

let destroy_app state =
  Sdl_utils.destroy_sdl_state state.sdls (* todo: destroy_gpu_state *)
