package sfc

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sort"
import "core:strings"

FilePanel :: struct {
	current_dir:       string,
	files:             [dynamic]os.File_Info,
	first_file_index:  int,
	sort_column:       SortColumn,
	sort_direction:    SortDirection,
	focused_row_index: int, //focused row counting from line below column header (first visible file is 0)
}

SortColumn :: enum {
	name,
	size,
	date,
}

SortDirection :: enum {
	ascending,
	descending,
}

/*
	Reloads files in current directory of specified panel
*/
reload_file_panel :: proc(panel: ^FilePanel) {

	handle, error := os.open(panel.current_dir, os.O_RDONLY, 0)

	if error != nil {
		_last_error = error
		defer os.close(handle)
	}

	fi, err := os.read_dir(handle, 1024, context.temp_allocator)
	if err != 0 {
		_last_error = err
	}

	defer delete(fi)

	clear(&panel.files)

	parent_dir_info: os.File_Info = {
		fullpath = filepath.dir(panel.current_dir, context.allocator),
		name     = strings.clone("..", context.allocator),
		size     = 0,
		mode     = os.File_Mode_Dir,
		is_dir   = true,
	}
	append(&panel.files, parent_dir_info)

	for f in fi {
		//deep copy strngs because they are allocated internally by os.read_dir
		//originally I just replaced the strings in &f, but AI convinced me that creating a new 'file_info_copy' variable here is safer
		//TODO: ask somone on forums what is better and why
		//Reasoning: f was created by os.read_dir and it's strings are allocated on temp allocator
		//If I re-allocate the strings on f variable, I'm changing the memory that I don't "own" and that's dangerous (no concrete reason)
		//So creating a new variable which holds cloned strings is "better practice".
		file_info_copy := f
		file_info_copy.name = strings.clone(f.name, context.allocator)

		if strings.starts_with(f.fullpath, "//") {
			//workaround for what seems to be a bug on os package. For some reason it returns double // in root directory.
			// TODO: investigate or report
			file_info_copy.fullpath = strings.clone(f.fullpath[1:], context.allocator)
		} else {
			file_info_copy.fullpath = strings.clone(f.fullpath, context.allocator)
		}
		append(&panel.files, file_info_copy)
	}

	sort_files(panel)
}


/*
	Changes current directory of specified panel one level up
*/
cd_up :: proc(panel: ^FilePanel) {
	parent_dir := filepath.dir(panel.current_dir, context.allocator)

	if strings.equal_fold(parent_dir, panel.current_dir) {
		return
	}

	max_visible_files := get_max_visible_files()
	max_visible_index := max_visible_files - 1
	came_from_dir := strings.clone(panel.current_dir)
	error := cd(panel, parent_dir)

	loop: for file, index in panel.files {
		if strings.equal_fold(file.fullpath, came_from_dir) {
			if index <= max_visible_index {
				panel.focused_row_index = index
			} else {
				panel.focused_row_index = max_visible_index
				panel.first_file_index = index - max_visible_files + 1
			}

			break loop
		}
	}

	//TODO: Ensure that directory from where we came from is now visible and focused

	if error != os.General_Error.None {
		_last_error = error
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

	delete(panel.current_dir)
	panel.current_dir = directory

	reload_file_panel(panel)
	panel.first_file_index = 0
	panel.focused_row_index = 0

	return os.General_Error.None
}


sort_files :: proc(panel: ^FilePanel) {
	// TODO: Implement sort
	// AI suggests this:
	/*
		import "core:sort"

		SortContext :: struct {
		    sort_column: SortColumn,
		    sort_direction: SortDirection,
		}

		compare_proc :: proc(a, b: os.File_Info, ctx: rawptr) -> int {
		    context.user_ptr = ctx
		    sc := cast(^SortContext)ctx
		    if a.is_dir != b.is_dir {
		        return sc.sort_direction == .Ascending ? (a.is_dir && !b.is_dir ? -1 : 1) : (a.is_dir && !b.is_dir ? 1 : -1)
		    }
		    switch sc.sort_column {
		    case .Name:
		        return sc.sort_direction == .Ascending ? cmp(a.name, b.name) : cmp(b.name, a.name)
		    case .Size:
		        return sc.sort_direction == .Ascending ? cmp(a.size, b.size) : cmp(b.size, a.size)
		    }
		    return 0
		}

		cmp :: proc(a, b: $T) -> int where intrinsics.type_is_ordered(T) {
		    return a < b ? -1 : (a > b ? 1 : 0)
		}

		sort_files :: proc(panel: ^FilePanel) {
		    ctx := SortContext{panel.sort_column, panel.sort_direction}
		    sort.quick_sort_proc_context(panel.files[:], compare_proc, &ctx)
		}
	*/
}

/*
	Moves file focused_row_index of currently active panel up or down.
	Takes care not to overshoot.
	- amount: how many places to move. negative moves up. 0 is ignored
*/
move_file_focus :: proc(amount: int) {
	if amount == 0 do return


	max_files := get_max_visible_files()
	max_focus_index := max_files - 1
	_focused_panel.focused_row_index += amount
	files_below_line := len(_focused_panel.files) - max_files - _focused_panel.first_file_index
	if files_below_line < 0 {
		files_below_line = 0
	}

	if _focused_panel.focused_row_index < 0 {
		// when focus moves up below 0
		overshoot := -_focused_panel.focused_row_index
		_focused_panel.first_file_index -= overshoot
		if _focused_panel.first_file_index < 0 {
			_focused_panel.first_file_index = 0
		}
		_focused_panel.focused_row_index = 0
	} else if _focused_panel.focused_row_index > len(_focused_panel.files) - 1 {
		//when focus moves below last file index
		_focused_panel.focused_row_index = len(_focused_panel.files) - 1
	} else if (_focused_panel.focused_row_index > max_focus_index) {
		//when focus moves down below bottom and and there
		if files_below_line > 0 {
			overshoot := _focused_panel.focused_row_index - max_focus_index
			if overshoot > files_below_line {
				overshoot = files_below_line
			}

			_focused_panel.first_file_index += overshoot
		}
		_focused_panel.focused_row_index = max_focus_index
	}

}

get_focused_file_index :: proc() -> int {
	return _focused_panel.focused_row_index + _focused_panel.first_file_index
}

get_focused_file_info :: proc() -> os.File_Info {
	index := get_focused_file_index()
	return _focused_panel.files[index]
}


/*
	Adjusts first_file_index and focused_row_index of specified panel.
	Used after resolution change to ensure:
	 - focus line must be inside panel and on a file
	 - there must not be space above first file
	 - there must not be free space at the bottom if there are files above 0 line
	 - if possible, keep the focus on the same file
*/
recalculate_indexes :: proc(panel: ^FilePanel) {

	/*
	There are 2 possible cases:

	1 panel is now larger, there are files above the 0 line, but there is available space below
	 -> move files and focus row down by the same amount

	2 panel is now smaller and focus line is outside panel (below)
	 -> move focus line and all files up by the missing amout
	*/

	/*
	first_file_index:  int,
	focused_row_index: int,
	*/

	max_visible_files := get_max_visible_files()
	max_focus_index := max_visible_files - 1

	if max_focus_index < 0 do return //special case when files don't fit on screen

	if panel.first_file_index > 0 &&
	   len(panel.files) - panel.first_file_index < max_visible_files {
		//case 1: panel is larger (read above)
		amount_to_move := max_visible_files - (len(panel.files) - panel.first_file_index)
		if amount_to_move > panel.first_file_index {
			amount_to_move = panel.first_file_index
		}
		panel.first_file_index -= amount_to_move
		panel.focused_row_index += amount_to_move
	}

	if panel.focused_row_index > max_focus_index {
		//case 2: panel is smaller (read above)
		amount_to_move := panel.focused_row_index - max_focus_index
		panel.first_file_index += amount_to_move
		panel.focused_row_index = max_focus_index
	}
}

swap_focused_panel :: proc() {
	_focused_panel = _focused_panel == &_left_panel ? &_right_panel : &_left_panel
}

