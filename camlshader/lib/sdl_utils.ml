open Tsdl

type keyboard_state = (Sdl.keycode, bool) Hashtbl.t
type mouse_state = (int * int) ref

type sdl_state = {
  win : Sdl.window;
  ren : Sdl.renderer;
  txt : Sdl.texture;
  keys : keyboard_state;
  mouse_delta : mouse_state;
  grab_mouse : bool;
}

(* Initializes SDL with video and event options *)
let start_sdl () =
  match Sdl.init Sdl.Init.(video + events) with
  | Error (`Msg e) ->
      Sdl.log "failed to initialize SDL: %s" e;
      false
  | Ok () -> true

(* builds a resizable metal window *)
let build_window name w h =
  match
    Sdl.create_window ~w ~h name
      Sdl.Window.(shown + resizable + metal + allow_highdpi)
  with
  | Error (`Msg e) ->
      Sdl.log "failed to create window: %s" e;
      None
  | Ok win ->
      Sdl.pump_events ();
      Some win

let build_renderer win =
  match
    Sdl.create_renderer win ~index:0
      ~flags:Sdl.Renderer.(accelerated + presentvsync)
  with
  | Error (`Msg e) ->
      Sdl.log "failed to create renderer : %s" e;
      None
  | Ok ren -> Some ren

let build_texture ren w h =
  match
    Sdl.create_texture ren Sdl.Pixel.format_abgr8888
      Sdl.Texture.access_streaming ~w ~h
  with
  | Error (`Msg e) ->
      Sdl.log "failed to create texture : %s" e;
      None
  | Ok texture -> Some texture

let resize_texture state w h =
  match build_texture state.ren w h with
  | None -> None
  | Some txt -> Some { state with txt }

let build_keys n : keyboard_state = Hashtbl.create n
let build_mouse () : mouse_state = ref (0, 0)

let toggle_grab_mouse state =
  ignore (Sdl.set_window_grab state.win (not state.grab_mouse));
  ignore (Sdl.set_relative_mouse_mode (not state.grab_mouse));
  { state with grab_mouse = not state.grab_mouse }

let build_default_sdl_state name w h =
  let keys = build_keys 16 in
  (* default to 16 keys ... *)
  let mouse_delta = build_mouse () in
  if not (start_sdl ()) then None
  else
    match build_window name w h with
    | None ->
        Sdl.quit ();
        None
    | Some win -> (
        match build_renderer win with
        | None ->
            Sdl.destroy_window win;
            Sdl.quit ();
            None
        | Some ren -> (
            match build_texture ren w h with
            | None ->
                Sdl.destroy_renderer ren;
                Sdl.destroy_window win;
                Sdl.quit ();
                None
            | Some txt ->
                Some { win; ren; txt; keys; mouse_delta; grab_mouse = false }))

let destroy_sdl_state state =
  Sdl.destroy_texture state.txt;
  Sdl.destroy_renderer state.ren;
  Sdl.destroy_window state.win

let render_texture state pxls pitch =
  match Sdl.update_texture state.txt None pxls pitch with
  | Error (`Msg e) ->
      Sdl.log "failed to update texture: %s" e;
      ()
  | Ok () ->
      ignore (Sdl.render_clear state.ren);
      ignore (Sdl.render_copy state.ren state.txt);
      Sdl.render_present state.ren

(*** Keyboard Utilities ***)
let is_pressed state keycode =
  Hashtbl.find_opt state.keys keycode |> function
  | Some true -> true
  | _ -> false

let handle_keydown state keycode =
  Hashtbl.replace state.keys keycode true;
  state

let handle_keyup state keycode =
  Hashtbl.replace state.keys keycode false;
  state
