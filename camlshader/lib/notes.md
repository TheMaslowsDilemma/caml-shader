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
