open Camlshader
open Tsdl

let event = Sdl.Event.create ()

let rec loop state =
  if not state.App_utils.running then ()
  else begin
    if Sdl.poll_event (Some event) then loop App.( apply_step (handle_event state event) )
    else begin
      let pxls, pitch =
        Metal_utils.run_compute_pipeline state.gpus state.shaders.active
      in
      Sdl_utils.render_texture state.sdls pxls pitch;
      loop (App.apply_step state)
    end
  end

let () =
  match App.build_default_app () with
  | None ->
      Printf.printf "app build failed, shutting down.";
      ()
  | Some state ->
      loop state;
      App.destroy_app state;
      Sdl.quit ();
      ()
