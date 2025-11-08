# Simple-File-Commander
Orthodox TUI file manager inspired by Helix editor motions. 

!!!Barely started development!!!


# Important TODO:

 - [-] Make key mapper (load from file, default if not found)
 - [-] Make command sub-system (parser, executor, show results/errors)
 - [-] Make text viewer "popup"
 - [-] Make commands which can be called from key mapper or from command sub-system
 - [-] Execute file and show output somewhere
 - [-] show/hide hidden items
 - [-] remember "last session" (directories, panels, hidden files etc)
 - [-] file "icons" left of the file/directory
 - [-] color coded file and directory names based on pattern
 - [+] file attributes
   - [-] draw file attributes with different color for each permission set
   - [-] draw file attributes in octal mode
 - [+] get file attributes from parent directory
 - [-] handle system files
 - [-] handle symbolic links
 - [-] selection
 - [-] detect if file was cropped, and draw it differently (probably using "icon" column)
 
# Cleanup TODO:

 - Make drawing procedures consistent
    - some take temp_clor, some don't
    - some take colors, some don't

# Screenshot

![Screenshot goes here](Screenshot.png)