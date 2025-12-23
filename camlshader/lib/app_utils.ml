type app_state = {
  scenes : Scene_utils.scene_state;
  sdls : Sdl_utils.sdl_state;
  gpus : Metal_utils.gpu_state;
  shaders : Shader_utils.shader_library_state;
  running : bool;
}

(* eventually could have key combinations *)
type keyboard_action = { key : Tsdl.Sdl.keycode; act : app_state -> app_state }

let default_actions =
  let open Tsdl in
  let open Scene_utils in
  [
    {
      key = Sdl.K.w;
      act =
        (fun state ->
          { state with scenes = translate_camera Forward 0.06 state.scenes });
    };
    {
      key = Sdl.K.a;
      act =
        (fun state ->
          { state with scenes = translate_camera Left 0.06 state.scenes });
    };
    {
      key = Sdl.K.s;
      act =
        (fun state ->
          { state with scenes = translate_camera Backward 0.06 state.scenes });
    };
    {
      key = Sdl.K.d;
      act =
        (fun state ->
          { state with scenes = translate_camera Right 0.06 state.scenes });
    };
    {
      key = Sdl.K.e;
      act =
        (fun state ->
          { state with sdls = Sdl_utils.toggle_grab_mouse state.sdls });
    };
  ]

let rec apply_keyboard_actions state key_actions =
  match key_actions with
  | [] -> state
  | ka :: kas ->
      if Sdl_utils.is_pressed state.sdls ka.key then
        apply_keyboard_actions (ka.act state) kas
      else apply_keyboard_actions state kas

let apply_mouse_actions state =
  let dx, dy = !(state.sdls.mouse_delta) in
  if dx != 0 || dy != 0 then begin
    let dxf = float_of_int dx in
    let dyf = float_of_int dy in
    state.sdls.mouse_delta := (0, 0);
    (* CAUTION: this is sort of not safe ... .. . *)
    { state with scenes = Scene_utils.rotate_camera state.scenes dxf dyf }
  end
  else state
