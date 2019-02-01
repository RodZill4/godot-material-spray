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

## Why I started this project?

It is all [@Bauxitedev](https://github.com/Bauxitedev)'s fault ! ;)

I really wanted his [godot-texture-painter](https://github.com/Bauxitedev/godot-texture-painter) to be integrated in Godot, so I forked his repository, and tried and ~~failed~~ gave up. I then decided to start my own implementation, with a slightly different approach (although I "borrowed" lots of code from his shaders), and here it is!
