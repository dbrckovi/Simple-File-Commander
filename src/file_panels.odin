package sfc

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:sort"
import "core:strings"

FilePanel :: struct {
	arena:             mem.Arena,
	arena_buffer:      []byte,
	allocator:         runtime.Allocator,
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

//Additional File_Mode values that are missing in core:os
File_Mode_Other_Execute :: os.File_Mode(1 << 0)
File_Mode_Other_Write :: os.File_Mode(1 << 1)
File_Mode_Other_Read :: os.File_Mode(1 << 2)
File_Mode_Group_Execute :: os.File_Mode(1 << 3)
File_Mode_Group_Write :: os.File_Mode(1 << 4)
File_Mode_Group_Read :: os.File_Mode(1 << 5)
File_Mode_Owner_Execute :: os.File_Mode(1 << 6)
File_Mode_Owner_Write :: os.File_Mode(1 << 7)
File_Mode_Owner_Read :: os.File_Mode(1 << 8)

/*
	Initializes file panel's memory and fields
*/
initialize_file_panel :: proc(panel: ^FilePanel, initial_directory: string) {
	panel.arena_buffer = make([]byte, mem.Megabyte * 1, context.allocator)
	mem.arena_init(&panel.arena, panel.arena_buffer)
	panel.allocator = mem.arena_allocator(&panel.arena)

	panel.current_dir = strings.clone(initial_directory, panel.allocator)
	panel.files = make([dynamic]os.File_Info, 100, panel.allocator)
	reload_file_panel(panel)
}

/*
	Frees all memory used by the panel and re-initializes containers which used the old memory
*/
reset_file_panel_memory :: proc(panel: ^FilePanel) {
	current_dir_backup := strings.clone(panel.current_dir, context.temp_allocator)
	mem.arena_free_all(&panel.arena)
	panel.current_dir = strings.clone(current_dir_backup, panel.allocator)
	panel.files = make([dynamic]os.File_Info, 0, 100, panel.allocator)
}

/*
	Reloads files in current directory of specified panel
*/
reload_file_panel :: proc(panel: ^FilePanel) {
	handle, error := os.open(panel.current_dir, os.O_RDONLY, 0)
	defer os.close(handle)

	if error != nil {
		_last_error = error
	}

	files, err := os.read_dir(handle, 1024, context.temp_allocator)
	if err != 0 {
		_last_error = err
	}

	reset_file_panel_memory(panel)

	parent_dir_info: os.File_Info = {
		fullpath = filepath.dir(panel.current_dir, panel.allocator),
		name     = strings.clone("..", panel.allocator),
		size     = 0,
		mode     = os.File_Mode_Dir,
		is_dir   = true,
	}

	append(&panel.files, parent_dir_info)

	for f in files {
		file_info_copy := f
		file_info_copy.name = strings.clone(f.name, panel.allocator)
		if strings.starts_with(f.fullpath, "//") {
			//workaround for what seems to be a bug on os package. For some reason it returns double // in root directory.
			// TODO: investigate or report
			file_info_copy.fullpath = strings.clone(f.fullpath[1:], panel.allocator)
		} else {
			file_info_copy.fullpath = strings.clone(f.fullpath, panel.allocator)
		}
		append(&panel.files, file_info_copy)
	}

	sort_files(panel)
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

	//focus directory from which we came
	loop: for file, index in panel.files {
		if strings.compare(file.fullpath, came_from_dir) == 0 {
			if index <= max_visible_index {
				panel.focused_row_index = index
			} else {
				panel.focused_row_index = max_visible_index
				panel.first_file_index = index - max_visible_files + 1
			}

			break loop
		}
	}

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

	// delete(panel.current_dir)
	panel.current_dir = strings.clone(directory, context.temp_allocator)

	reload_file_panel(panel)
	panel.first_file_index = 0
	panel.focused_row_index = 0

	return os.General_Error.None
}

sort_files :: proc(panel: ^FilePanel) {
	compare_proc := compare_file_info_by_name_asc
	if panel.sort_direction == .descending {
		compare_proc = compare_file_info_by_name_desc
	}

	sort.quick_sort_proc(panel.files[:], compare_proc)
}

/*
			if 'A' <= c && c <= 'Z' {
				c += 'a' - 'A'
			}
*/

enforce_directories_first :: proc(a, b: os.File_Info) -> (int, bool) {
	if a.name == ".." {
		return -1, true
	}

	if b.name == ".." {
		return 1, true
	}

	if a.is_dir && !b.is_dir {
		return -1, true
	}

	if b.is_dir && !a.is_dir {
		return 1, true
	}

	return 0, false
}

compare_file_info_by_name_asc :: proc(a, b: os.File_Info) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return compare_file_name(a.name, b.name)
}

compare_file_info_by_name_desc :: proc(a, b: os.File_Info) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return -compare_file_name(a.name, b.name)
}


compare_file_info_by_date :: proc(a, b: os.File_Info) -> int {
	panic("Unimplemented")
}

compare_file_info_by_size :: proc(a, b: os.File_Info) -> int {
	panic("Unimplemented")
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

is_hidden :: proc(info: os.File_Info) -> bool {
	return strings.starts_with(info.name, ".")
}

is_executable :: proc(info: os.File_Info) -> bool {
	return(
		File_Mode_Owner_Execute & info.mode > 0 ||
		File_Mode_Group_Execute & info.mode > 0 ||
		File_Mode_Other_Execute & info.mode > 0 \
	)
}

get_permissions_string :: proc(info: os.File_Info) -> string {
	binary_string := fmt.tprintf("%b", info.mode)
	binary_slice := binary_string[len(binary_string) - 9:]
	chars: [3]rune = {'r', 'w', 'x'}
	char_index := 0

	sb := strings.builder_make(context.temp_allocator)

	for r, i in binary_slice {
		if r == '1' {
			strings.write_rune(&sb, chars[char_index])
		} else {
			strings.write_rune(&sb, '-')
		}
		char_index += 1
		if char_index > 2 {
			char_index = 0
		}
	}

	return strings.to_string(sb)
}

