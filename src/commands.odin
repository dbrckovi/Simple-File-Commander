package sfc

//TODO: move logic for parsing and executing ':' commands here

/*
	File comands:

	- copy
	- move
	- delete
	- create file
	- create directory
	- rename
	- execute (activate)
	- call (show output)

	Sorting:

	- switch sort direction
	- sort by (col, col, col)

	Filtering:

	- set_filter
	- clear_filter

	Selection:

	- select_focused
	- deselect_focused
	- select_all
	- deselect_all
	- toggle_selection_on_focused
	- select_pattern
	- deselect_pattern

	Clipboard:

	- clopboard copy current directory
	- clopboard copy selected file names
	- clopboard copy selected file full paths

	Varoous:
	
	- compare focused files
	- compare directories
	- change theme


*/


/*
	Performs the default action on currently focused file or directory.
	Action depends on the type of the item
*/
activate_focused_file_info :: proc() {
	file_info := get_focused_file_info()
	if file_info.file.is_dir {
		if file_info.file.name == ".." {
			cd_up(_focused_panel)
		} else {
			cd(_focused_panel, file_info.file.fullpath)
		}
	}
}

