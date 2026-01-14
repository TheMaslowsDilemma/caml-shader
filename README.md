# Caml Shader

Caml Shader is an experimental SDF ray marching environment written in OCaml, with shaders implemented in Metal Shader Language. The project renders signed distance function scenes in real-time, compiling Metal shaders at runtime and displaying them through SDL.

## Overview

The ray marcher renders 3D scenes defined by signed distance functions. The current default scene constructs a repeating village of simple houses, complete with roofs and chimneys. The implementation draws heavily from Inigo Quilez's research on SDF composition and soft shadow techniques.

Shaders are stored in the `camlshader/shaders` directory and compiled dynamically when the application runs. This allows for rapid iteration on shader code without rebuilding the entire project.

## Running

The project uses Dune as its build system. To compile and run:

```
dune exec camlshader
```

## Dependencies

The project relies on the following OCaml libraries: `metal` for GPU compute via Apple's Metal API, `tsdl` for cross-platform windowing and input handling through SDL2, and `owl` for numerical computing.

## Architecture

The shader receives several inputs from the host application: image dimensions, thread position in the compute grid, camera position and direction, and light positions. Camera control logic is handled entirely on the OCaml side, with the shader operating within a constrained 3D field.

The scene data is currently passed to the shader as a float pointer, though this interface is a candidate for future reorganization to support multiple light sources and more complex scene descriptions.

## Development Notes

Work began in December 2025 with the goal of creating an interactive SDF rendering environment. Early development focused on establishing basic interactivity through mouse position and time inputs, with plans for more complex scene-level inputs in the future.

One area of ongoing interest is the dynamic composition of signed distance functions from user-defined scenes. Research from Facebook's DeepSDF and NVIDIA's NGLOD projects demonstrates neural network approaches to approximating SDFs from meshes and point clouds, though these methods introduce performance considerations that require further investigation.

The shader has undergone several iterations to achieve correct SDF repetition for the village scene, with soft shadows implemented following Quilez's articles. Some visual artifacts remain around ray-surface intersections and building geometry that need attention.

Future work includes implementing bounding volume hierarchies such as KD-trees or octrees to optimize ray marching performance, as well as potential integration with linear algebra visualization for rendering vectors and matrices. There is also interest in exploring shader composition, where multiple shaders handling different dimensional data could be layered together.

## References

The implementation draws from Inigo Quilez's extensive documentation on signed distance functions and ray marching techniques. The neural SDF research referenced during development can be found at the DeepSDF and NGLOD repositories on GitHub.