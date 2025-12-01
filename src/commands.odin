package sfc

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import err "errors"

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
	//TODO: open current file, follow link, etc
}

/*
	If currently focused item is a directory, navigates to it
*/
navigate_focused_directory :: proc() {
	file_info := get_focused_file_info()
	if file_info.file.is_dir {
		if file_info.file.name == ".." {
			cd_up(_focused_panel)
		} else {
			cd(_focused_panel, file_info.file.fullpath)
		}
	}
}

/*
	Changes current directory of specified panel one level up
*/
cd_up :: proc(panel: ^FilePanel) {
	parent_dir := filepath.dir(panel.current_dir, context.temp_allocator)

	if strings.equal_fold(parent_dir, panel.current_dir) {
		return
	}

	max_visible_files := get_max_visible_files()
	max_visible_index := max_visible_files - 1
	came_from_dir := strings.clone(panel.current_dir, context.temp_allocator)
	error := cd(panel, parent_dir)

	if error != os.General_Error.None {
		message := fmt.tprint("Error changing directory", error)
		show_error_message(err.create_exception(.os_error, message))
	} else {
		//focus directory from which we came
		loop: for file, index in panel.files {
			if strings.compare(file.file.fullpath, came_from_dir) == 0 {
				if index <= max_visible_index {
					panel.focused_row_index = index
				} else {
					panel.focused_row_index = max_visible_index
					panel.first_file_index = index - max_visible_files + 1
				}

				break loop
			}
		}
	}

}

/*
	Changes current directory of specified panel to what ever was passed in
*/
cd :: proc(panel: ^FilePanel, directory: string) -> os.Error {
	if !os.exists(directory) {
		return os.General_Error.Not_Exist
	}
	if !os.is_dir(directory) {
		return os.General_Error.Not_Dir
	}

	same_directory := strings.compare(directory, panel.current_dir)
	panel.current_dir = strings.clone(directory, context.temp_allocator)
	reload_file_panel(panel, same_directory == 0)
	panel.first_file_index = 0
	panel.focused_row_index = 0

	return os.General_Error.None
}

