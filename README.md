# SpriteSheetToSpriteFrames
A Godot plugin to streamline the conversion of a sprite sheet with animations from Aseprite to Godot's SpriteFrames resource


## Step by step
1. First you must export the necessary sprite sheet of the .aseprite file you want that has the animations.
![alt text](/screenshots/AsepriteExport1.png)
2. In the output options, "JSON Data" must be enabled and "Tags" must be enabled (The "Tags" option and everything else should be set by default, without having to change any options when enabling "JSON Data").
![alt text](/screenshots/AsepriteExport2.png)

3. Set the JSON and sprite sheet into your project.
4. After enabling the plugin, copy the path of your sprite sheet and JSON and place them into their appropriate text fields.
![alt text](/screenshots/Plugin1.png)
### Creating a SpriteFrames Resource
- Simply fill out the export folder path within the project for where you want the resource to be created in.
- (Optional) You can also name your resource but **DON'T** add the resource extension.
- Click convert after entering all fields, and your SpriteFrames resource should now be created!

### Appending to an existing SpriteFrames resource
- This is for instances where you have a SpriteFrames resource and wish to append more from a sprite sheet.
- Simply fill out the SpriteFrames resource path you want to append more animations to.
- The append button will enable itself after filling the fields, and now you can append to your existing resource!

![alt text](/screenshots/Plugin2.png)
## Notes
- "Overwrite FPS" sets FPS of every animation to that exact frame rate, regardless of what you had set in the in your original .aseprite file.

- "Overwrite Animations" Updates any existing animation within the SpriteFrames resource you are appending to
