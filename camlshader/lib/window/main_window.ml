open Tsdl

let start_window name width height = 
  match Sdl.init Sdl.Init.(video + events) with
  | Error (`Msg e) -> Sdl.log "init SDL error: %s" e; 1
  | Ok () ->
    match Sdl.create_window ~w: width ~h: height name Sdl.Window.opengl with
    | Error (`Msg e) -> Sdl.log "create window error: %s" e; 1
    | Ok w ->
    Sdl.pump_events ();
    Sdl.delay 3000l;
    Sdl.destroy_window w;
    Sdl.quit ();
    0