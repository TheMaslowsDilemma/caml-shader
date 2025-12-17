open Metal

type shader_library = (string, Metal.ComputePipelineState.t) Hashtbl.t

type shader_library_state = {
  library : shader_library;
  active : Metal.ComputePipelineState.t;
}

let build_shader_library n : shader_library = Hashtbl.create n

(* compiles a shaders source code and adds its pipeline to library by name *)
let add_shader library device name source =
  try
    let compile_options = CompileOptions.init () in
    let metal_lib =
      Library.on_device device ~source compile_options
    in
    let shader = Library.new_function_with_name metal_lib name in
    let pipeline_state, _ =
      ComputePipelineState.on_device_with_function device
        shader
    in
    Hashtbl.replace library name pipeline_state;
    Ok ()
  with e -> Error (Printexc.to_string e)

(* loads the default shader into a new library & state *)
let build_default_library_state device = 
  let library = build_shader_library 16 in
  match add_shader library device Default_shader.name Default_shader.source with
  | Error err -> 
    Printf.printf "error creating default shader: %s" err;
    None
  | Ok () -> 
    let active = Hashtbl.find library Default_shader.name in
    Some { library; active }

(* switches active pipeline in the shader library state *)
let update_active_shader state name =
  if Hashtbl.mem state.library name then begin
    let active = Hashtbl.find state.library name in 
    Some { state with active }
  end
  else begin
    Printf.printf "failed to update shader: '%s' not found in library" name;
    None
  end
