open Owl

type scene_state = {
  camera_pos : Mat.mat;
  camera_dir : Mat.mat;
  light_pos : Mat.mat;
}

type translation_dir = Forward | Backward | Left | Right | None

let vec_of_3 x y z = Mat.of_array [| x; y; z |] 3 1
let scene_up_dir = vec_of_3 0. 1. 0.

let build_default_scene () =
  {
    camera_pos = vec_of_3 0. (-20.) 0.;
    camera_dir = vec_of_3 0. 0. 1.;
    light_pos = vec_of_3 (-50.) (-50.) 50.;
  }

let normalize v =
  let n = Linalg.D.norm v in
  Mat.(v /$ n)

let cross a b =
  let x =
    (Mat.get a 1 0 *. Mat.get b 2 0) -. (Mat.get a 2 0 *. Mat.get b 1 0)
  in
  let y =
    (Mat.get a 2 0 *. Mat.get b 0 0) -. (Mat.get a 0 0 *. Mat.get b 2 0)
  in
  let z =
    (Mat.get a 0 0 *. Mat.get b 1 0) -. (Mat.get a 1 0 *. Mat.get b 0 0)
  in
  Mat.of_array [| x; y; z |] 3 1

let rotate_camera state dx dy =
  let sensitivity = 0.003 in
  let forward = state.camera_dir in
  let left = normalize (cross scene_up_dir forward) in
  let yaw = dx *. sensitivity in
  let pitch = dy *. sensitivity in
  let rot_vec = Mat.((scene_up_dir *$ yaw) + (left *$ pitch)) in
  let new_dir = Mat.(forward + cross forward rot_vec) |> normalize in

  { state with camera_dir = new_dir }

let translate_camera dir speed state =
  if dir = None then state
  else
    let forward = state.camera_dir in
    let movement =
      match dir with
      | Forward -> forward
      | Backward -> Mat.(neg forward)
      | Left -> Mat.(neg (normalize (cross forward scene_up_dir)))
      | Right -> normalize (cross forward scene_up_dir)
      | None -> Mat.zeros 3 1
    in
    let delta_pos = Mat.(movement *$ speed) in
    let new_pos = Mat.(state.camera_pos + delta_pos) in
    { state with camera_pos = new_pos }
