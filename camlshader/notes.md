### Caml Shader Notes

--

**log: Dec 18, 2025**
the app need to have some interactivity. two forms of input
come to mind: basic input and scene input. the basics are
`mouse (x,y)` and `time t`. the scene would be more complex
objects like 3d points and can wait.
git 
the other thing to explore is how to form building blocks
that can be parsed into metal shader language. this would
include both the inputs to shaders and its behavior. the
current shaders are not well defined at all. the only input
is the dimension of the image and the thread_position_in_grid.


**log: Dec 19, 2025**
it would be fun to use this with the linear algebra studies.
for instance, rendering vectors and matricies could be done
using the shaders.

it may also be possible to render one shader result ontop of
another. For examlpe if two shaders handling 2D and 3D vectors
could be combined.

another area to explore is the construction of signed distance
functions. Consider a dynamic scene that, that can be modified
by a user. How can a distance function be constructed from
some input scene, and how do we constrain the scene so it can
be done? How is a SDF composed and how can we pass that to a
shader (could it be done in a metal kernel)?

pursuing the most interesting idea, would mean becoming familiar
with SDFs, understanding how they are composed, and consider if
and how they are a function of a scene. then to find out how to
build that function.

**log: Dec 23, 2025**
just to note about the previous ideas. there actually have been
efforts by researchers to compose SDFs from meshes and point
clouds. Notably from Facebook and NVIDIA.
 - facebooks: https://github.com/facebookresearch/DeepSDF
 - nvidias: https://github.com/nv-tlabs/nglod/tree/main
these methods use neural networks to approximate a function. they
seem slow but will have to look at it.

between now and the last log, I have added the ability to input
the camera direction and position into the shader buffer. this
constrains the shader to operate within a 3D field, so maybe there
should be a catagorization of this particular shader which operates
in a 3D field with a camera. the controll logic for the camera is
all handled outside the shader.
additionally I added the light position to the shader buffer, although
this could be expaneded to hold multiple light positions and
could have better organization instead of just a float pointer `scene`

the shader itself has been improved to have a repeating scene with
soft shadows (taken from Inigo Quilez articles). there is some strange
artifacts with rays not hitting objects and gaps and distorted buildings
for example which still needs to be fixed.


**log: Dec 24, 2025**
after reading Inigo Quilez article on repeating sdfs, the shader correctly
repeates the houses. I added a roof and a chimminy. I would like to next,
do some machine learning. It need to be improved before going to a ML

**log: Dec 29, 2025**

