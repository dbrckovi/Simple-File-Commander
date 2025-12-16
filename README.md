# Simple-File-Commander

Two-panel TUI file manager inspired by Norton/Total/Midnight/Double Commander, but with completely rebindable keys and some "modal" aspects.

All existing two-panel managers that I tried use arrow keys for navigation.
Typing single letters, either types to a command bar or filters the view.
In short, it's impossible to use keys other than arrows for navigation.
This is annoying when switching from modal text editor to file manager because it forces you to move your hand to arrow keys.

Idea of Simple File Commander is to allow all functions to be bound to single key, or simple combinations with modifiers.
More complex actions can be performed by typing commands in command bar (invokable by single key), or by following keyboard-navigable dialogs.

I barely started development and I have no idea where this will end.
This is a personal project I use to learn Odin and "low-level" systems programming.

# Screenshot

![Screenshot goes here](Screenshot.png)

# Reminder TODO:

 - [ ] Figure out how to trigger dialog to handle thread request
 - [ ] Keep it !!! SIMPLE !!!
 - [ ] Keys idea:
      - a - selects all files and directories
      - A - selects all items of focused type (if dir is focused, select all dirs)
      - d - deselects all files and directories
      - D - deselects all items of focused type (if dir is focused, deselect all dirs)
 - [ ] Navigating to /home/lost+found returns EBADF error
 - [ ] rewrite messagebox and text viewer to use slices instead of cloning strings
 - [ ] CommandBar.builder is convoluted. read TODO
 - [ ] Decide if Control will be bindable because gnome terminal intercepts C-j, C-l, C-o, etc.
       or try to update TermCL
 - [ ] Make key mapper (load from file, default if not found)
 - [ ] decide if mod keys will be strict or flexible
       maybe...
       x = execute when x is pressed regardless of modifiers
       N-x = execute only when x is pressed alone
       A-x = execute only when Alt+x is pressed
       S-x = execute only when Shift+x is pressed
       C-x = execute only when Ctrl+x is pressed
       A-C-x = execute only when Ctrl+Alt+x is pressed
 - [ ] Make command sub-system (parser, executor, show results/errors)
 - [ ] Make dialog popup subsystem
     - [ ] Current settings (read-only)
     - [ ] Keybindings (read-only)
     - [ ] Command reference
     - [ ] Copy file(s)
     - [ ] Move file(s)
     - [ ] Delete file(s)
     - [ ] Create file(s)
     - [ ] Create directory(s)
     - [ ] Space menu commands (for advanced features)
     - [ ] File filter mask
     - [ ] Select files mask
 - [ ] Make commands which can be called from key mapper or from command sub-system
 - [ ] Execute file and show output somewhere
 - [ ] show/hide hidden items
 - [ ] remember "last session" (directories, panels, hidden files etc)
 - [ ] file "icons" left of the file/directory
 - [ ] color coded file and directory names based on pattern
 - [+] file attributes
       - [+] draw file attributes with different color for each permission set
       - [ ] draw file attributes in octal mode
 - [+] get file attributes from parent directory
 - [ ] handle system files
 - [ ] detect if file was cropped, and draw it differently (probably using "icon" column)
 - [ ] hex_to_rgb is ignoring errors
 - [ ] symbolic links
        - differentiate links to directories and files
        - follow them on enter
        - show target in status area if focused file is link
        - paint links based on target 'stat' (icon_link_to_directory is now unused)
   
# Cleanup TODO:

 - refactor 'compare' procedures. There are too many doing very similar thing
 - Make drawing procedures consistent
    - some take temp_clor, some don't
    - some take colors, some don't
