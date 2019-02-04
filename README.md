Material Spray is a small addon for the Godot engine that can be used to paint meshes.

![screenshot](/addons/material_spray/doc/screenshot.png)

To use it:
1. clone or download this repository and copy the **addons/material_spray** directory into your Godot project
2. enable the MaterialSpray extension in your project (using the **Extensions** tab in the **Project->Parameters** window)
3. select a MeshInstance in any scene of the project and use the MaterialSpray button (see image below) above the 3D view. This will open the MaterialSpray window
4. in the bottom right corner, the brush can be configured. The channels to be modified can be selected (albedo, metallic and roughness) as well as their color/values. A texture can be selected for albedo (click on the image to be prompted for it) as well as the way it will be used (no texture, stamp and pattern).
5. select a tool in the top left corner (freehand painting, line, linestrip)
6. adjust the brush size and hardness by holding the **Shift** key and moving the mouse (left-right for size, up-down for hardness). When in **stamp** mode, up-down rotates the texture. When in **pattern** mode, the pattern can be resized and rotated by holding the **Control** key
7. and finally, start painting directly your mesh with the left mouse button. The mesh can be rotated with the right mouse button or the arrow keys.

![button](/addons/material_spray/doc/button.png)

## Known problems and limitations

* Only the first surface of a mesh will be painted. Meshs with more than one surface are not tested.
* The position of the brush is not accurate, espescially on the left and top of the window. This will be fixed once I find out how to use the **keep_3d_linear** Viewport parameter.

## Why I started this project?

It is all [@Bauxitedev](https://github.com/Bauxitedev)'s fault ! ;)

I really wanted his [godot-texture-painter](https://github.com/Bauxitedev/godot-texture-painter) to be integrated in Godot, so I forked his repository, and tried and ~~failed~~ gave up. I then decided to start my own implementation, with a slightly different approach (although I "borrowed" lots of code from his shaders), and here it is!

## How it works

This plugin is based on intermediate textures that are generated before painting and used by the paint shader.

### The seams texture

When loading the mesh, the plugin generated the **seams** texture, that is used to paint "beyond" seams in texture space so seams cannot be seen. The texture just contains, for pixels that are close to painted areas, the UV offset to be applied to get to the closest painted point.

![screenshot](/addons/material_spray/doc/seams.png)

The seams texture is generated in 2 passes:
* the first pass is generated in a 3d view with an isometric camera, and a shader that uses the UV coordinates as vertex coordinates. The result is an UV map where useful parts of the texture are white and the rest is black
* the second pass is the result of a 2d shader that takes the UV map as input and finds the offset to the nearest "useful" pixel for "useless" pixels

This **seams** texture is only used in the final paint shader

### The view-to-texture texture

This texture is a copy of the painting view shown to the user, but where the colors of the object are its UVs. It is generated in a 3d viewport containing a copy of the mesh and camera, and a very simple shader.

![screenshot](/addons/material_spray/doc/v2t.png)

This texture is generated whenever the view angle is modified and only used in the following step.

### The texture-to-view textures

This is basically the opposite of the view-to-texture texture, an UV map where the color is the position of the corresponding point in the user view (in the red and green channels). This texture is generated using the same setup^as the first pass of the seams texture (isometric camera, UV as vertex coordinates) and calculate the position in the user view using a function I borrowed from [@Bauxitedev](https://github.com/Bauxitedev)'s project.

The blue channel contains a multiplier that will be used when painting (only pixels whose blue channel is higher than 0 will be painted), and it is calculated from:
* the normal of the surface compared to the viewer's position
* the color of the corresponding pixel in the view-to-texture texture (if the pixel does not have the current UV coordinates as color, the corresponding part of the texture is hidden and should not be painted)

As a consequence, only blueish parts of the texture shown below will be painted (which correspond to the visible parts of the mesh on the user's view).

![screenshot](/addons/material_spray/doc/t2v.png)

And since the user's view coordinates are too big to fit in an 8 bits per channel texture, another texture-to-view texture is generated to hold least significant bits of those values.

![screenshot](/addons/material_spray/doc/t2vlsb.png)

Both texture-to-view textures are only used when painting which is the final step.

### The painting shader

This shader actually paints textures and is used in 4 viewports in parallel to modify 4 textures:
* Albedo
* Metallic and Roughness
* Emission
* Depth (the Normal texture is generated from this one)

This painting shader **just** paints the texture in 2D, and uses the following inputs:
* the **seams** input is used to find the nearest useful pixel of the texture
* the **texture-to-view** inputs are used to find the corresponding coordinates in the user view
* the brush parameters are used to calculate the distance from the painted pixel to the brush, and then the color it should be painted and the corresponding alpha. The result then is applied to the current textures.

When using the tool, you can use the choice boxes in the bottom left corner of the window to show 2 of those generated textures (this was really handy when debugging :D).
