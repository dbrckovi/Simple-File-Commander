package sfc

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:sort"
import "core:strings"
import "core:time"
import "errors"
import fs "filesystem"

FilePanel :: struct {
	arena:             mem.Arena,
	arena_buffer:      []byte,
	allocator:         runtime.Allocator,
	current_dir:       string,
	files:             [dynamic]SfcFileInfo,
	first_file_index:  int,
	sort_column:       FilePanelColumn,
	sort_direction:    SortDirection,
	focused_row_index: int, //focused row counting from line below column header (first visible file is 0)
}

/*
	Holds single file data
*/
SfcFileInfo :: struct {
	selected: bool,
	file:     os.File_Info,
}

FilePanelColumn :: enum {
	name,
	size,
	date,
	attributes,
}

SortDirection :: enum {
	ascending,
	descending,
}

AdvanceFocusMode :: enum {
	none,
	up,
	down,
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
File_Mode_Sym_Link :: os.File_Mode(1 << 13)

/*
	Initializes file panel's memory and fields
*/
initialize_file_panel :: proc(panel: ^FilePanel, initial_directory: string) {
	panel.arena_buffer = make([]byte, mem.Megabyte * 1, context.allocator)
	mem.arena_init(&panel.arena, panel.arena_buffer)
	panel.allocator = mem.arena_allocator(&panel.arena)

	panel.current_dir = strings.clone(initial_directory, panel.allocator)
	panel.files = make([dynamic]SfcFileInfo, 100, panel.allocator)
	reload_file_panel(panel)
}

/*
	Frees all memory used by the panel and re-initializes containers which used the old memory
*/
reset_file_panel_memory :: proc(panel: ^FilePanel) {
	current_dir_backup := strings.clone(panel.current_dir, context.temp_allocator)
	mem.arena_free_all(&panel.arena)
	panel.current_dir = strings.clone(current_dir_backup, panel.allocator)
	panel.files = make([dynamic]SfcFileInfo, 0, 100, panel.allocator)
}

/*
	Reloads files in current directory of specified panel
*/
reload_file_panel :: proc(panel: ^FilePanel, preserve_selection: bool = true) {
	previous_selection: [dynamic]string //TODO: Maybe use normal array instead

	if preserve_selection {
		previous_selection = make([dynamic]string, 0, 0, context.temp_allocator)

		for file in panel.files {
			if file.selected {
				append(&previous_selection, strings.clone(file.file.name, context.temp_allocator))
			}
		}
	}

	files, err := fs.get_files_in_directory(panel.current_dir, context.temp_allocator)
	//TOOD: this error is not handled


	reset_file_panel_memory(panel)

	parent_dir_info: SfcFileInfo = {
		selected = false,
		file = {
			//TODO: get this data from sys call
			fullpath = filepath.dir(panel.current_dir, panel.allocator),
			name     = strings.clone("..", panel.allocator),
			size     = 0,
			mode     = os.File_Mode_Dir,
			is_dir   = true,
		},
	}

	append(&panel.files, parent_dir_info)

	FILE_LOOP: for f in files {

		if !_settings.show_hidden_files && strings.starts_with(f.name, ".") {
			continue FILE_LOOP
		}

		file_info_copy := copy_file_info(f, panel.allocator)

		newItem: SfcFileInfo = {
			selected = preserve_selection && contains(&previous_selection, file_info_copy.name),
			file     = file_info_copy,
		}

		append(&panel.files, newItem)
	}
	sort_files(panel)
}

sort_files :: proc(panel: ^FilePanel) {
	compare_proc: proc(_: SfcFileInfo, _: SfcFileInfo) -> int

	if panel.sort_column == .date {
		compare_proc =
			panel.sort_direction == .ascending ? compare_file_info_by_date_asc : compare_file_info_by_date_desc
	} else if panel.sort_column == .size {
		compare_proc =
			panel.sort_direction == .ascending ? compare_file_info_by_size_asc : compare_file_info_by_size_desc
	} else {
		//name (and fallback for when I fuck up something)
		compare_proc =
			panel.sort_direction == .ascending ? compare_file_info_by_name_asc : compare_file_info_by_name_desc
	}

	sort.quick_sort_proc(panel.files[:], compare_proc)
}

/*
	Switches the sort mode to the specified column for the focused panel.
	@param panel: panel whose sorting will be affected
	@param column: column to which the sorting will be set (all except attributes)
	@param direction: sort direction to set. If null, sort direction will be automatically set
	@param reload: if true, panels will be automatically refreshed
*/
set_sort_column :: proc(
	panel: ^FilePanel,
	column: FilePanelColumn,
	direction: Maybe(SortDirection) = nil,
	reload: bool = true,
) {
	assert(column != .attributes) //I don't sort by this column

	dir, direction_specified := direction.?
	if direction_specified {
		panel.sort_direction = dir
	} else {
		if column == panel.sort_column {
			toggle_sort_direction(panel)
		} else {
			panel.sort_column = column
		}
	}

	panel.sort_column = column

	if reload {
		reload_file_panel(_focused_panel)
		_focused_panel.first_file_index = 0
		_focused_panel.focused_row_index = 0
	}
}

toggle_sort_direction :: proc(panel: ^FilePanel) {
	if panel.sort_direction == .ascending {
		panel.sort_direction = .descending
	} else {
		panel.sort_direction = .ascending
	}
}

enforce_directories_first :: proc(a, b: SfcFileInfo) -> (int, bool) {
	if a.file.name == ".." {
		return -1, true
	}

	if b.file.name == ".." {
		return 1, true
	}

	if a.file.is_dir && !b.file.is_dir {
		return -1, true
	}

	if b.file.is_dir && !a.file.is_dir {
		return 1, true
	}

	return 0, false
}

/*
	Selects or deselects focused file in a focused panel
	@param advance_focus: if true, next file will be focused after selection
*/
toggle_selection_focused_file :: proc(advance_focus: AdvanceFocusMode = .none) {
	file := get_focused_file_info()
	set_file_selected(file, !file.selected)

	#partial switch (advance_focus) {
	case .down:
		move_file_focus(1)
	case .up:
		move_file_focus(-1)
	}
}

select_all :: proc() {
	for &file in _focused_panel.files {
		set_file_selected(&file, true)
	}
}

deselect_all :: proc() {
	for &file in _focused_panel.files {
		set_file_selected(&file, false)
	}
}

/*
	Sets 'selected' field on the specified file if possible
	(example: [..] directory many not be selected)
*/
set_file_selected :: proc(file: ^SfcFileInfo, selected: bool) {
	if file.file.name != ".." {
		file.selected = selected
	}
}

compare_file_info_by_name_asc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return compare_file_names(a.file.name, b.file.name)
}

compare_file_info_by_name_desc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return -compare_file_names(a.file.name, b.file.name)
}

compare_file_info_by_date_asc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return compare_dates(a.file.modification_time, b.file.modification_time)
}

compare_file_info_by_date_desc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return -compare_dates(a.file.modification_time, b.file.modification_time)
}

compare_file_info_by_size_asc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return compare_sizes(a.file.size, b.file.size)
}

compare_file_info_by_size_desc :: proc(a, b: SfcFileInfo) -> int {
	ret, enforce := enforce_directories_first(a, b)
	if enforce {
		return ret
	}

	return -compare_sizes(a.file.size, b.file.size)
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

get_focused_file_info :: proc() -> ^SfcFileInfo {
	index := get_focused_file_index()
	return &_focused_panel.files[index]
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

is_hidden :: proc(info: ^SfcFileInfo) -> bool {
	return strings.starts_with(info.file.name, ".")
}

is_executable :: proc(info: ^SfcFileInfo) -> bool {
	return(
		File_Mode_Owner_Execute & info.file.mode > 0 ||
		File_Mode_Group_Execute & info.file.mode > 0 ||
		File_Mode_Other_Execute & info.file.mode > 0 \
	)
}

is_link :: proc(info: ^SfcFileInfo) -> bool {
	return File_Mode_Sym_Link & info.file.mode > 0
}

/*
	Returns file's modification or creation date as string
*/
get_file_date_string :: proc(info: os.File_Info) -> string {

	value: time.Time = info.modification_time //TODO: take creating time if settings says so
	//TODO: develop and apply formatting from settings

	y, M, d := time.date(value)
	h, m, s := time.clock(value)

	return fmt.tprintf("%2d.%2d.%4d %2d:%2d", d, M, y, h, m)
}


get_file_permissions_string :: proc(info: os.File_Info) -> string {
	sb := strings.builder_make(context.temp_allocator)

	switch _settings.attribute_format {
	case .octal:
		perms := u32(info.mode) & 0o777
		strings.write_string(&sb, fmt.tprintf("%03o", perms))
	case .symbolic:
		binary_string := fmt.tprintf("%b", info.mode)
		binary_slice := binary_string[len(binary_string) - 9:]
		chars: [3]rune = {'r', 'w', 'x'}
		char_index := 0

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
	}
	return strings.to_string(sb)
}


toggle_show_hidden_files :: proc() {
	//TODO: preserve focused file if possible
	//Double commander either keeps the same file selected, or the same focus
	//If either is not possible, probably selects the last file in the list
	_settings.show_hidden_files = !_settings.show_hidden_files
	reload_file_panel(&_left_panel)
	reload_file_panel(&_right_panel)
	_left_panel.first_file_index = 0
	_left_panel.focused_row_index = 0
	_right_panel.first_file_index = 0
	_right_panel.focused_row_index = 0
}

/*
	Creates and shows a file copy dialog and gives it selected files and destination directory
*/
init_copy_process :: proc() {
	source_panel := _focused_panel
	dest_panel := _focused_panel == &_left_panel ? &_right_panel : &_left_panel
	selected_files := make([dynamic]SfcFileInfo)

	if strings.equal_fold(source_panel.current_dir, dest_panel.current_dir) {
		_current_dialog = create_messagebox(
			"Source and destination directories may not be the same",
			"Error",
		)
		return
	}

	for file in source_panel.files {
		if file.selected {
			append(&selected_files, file)
		}
	}

	if len(selected_files) == 0 {
		focused_file := get_focused_file_info()
		if focused_file.file.name != ".." {
			focused_file.selected = true
			append(&selected_files, focused_file^)
		}
	}

	if len(selected_files) > 0 {
		dlg, err := create_file_copy_box(selected_files, dest_panel.current_dir, context.allocator)
		if err != {} {
			destroy_file_copy_box(&dlg)
			show_error_message(err)
		} else {
			_current_dialog = dlg
		}
	} else {
		_current_dialog = create_messagebox(
			"At least one file or directory must be selected or focused.\nParent directory may not be copied from within itself.",
			"Error",
		)
	}
}

/*
	Deletes currently selected items in foucsed panel 
	If nothing is selected a focused item is taken if possible
*/
perform_delete :: proc() {
	dest_panel := &_left_panel == _focused_panel ? _right_panel : _left_panel

	//TODO: rewrite this because now it only copies files, and doesn't fall back to focused file if nothing is selected

	for file in _focused_panel.files {
		if file.selected && !file.file.is_dir {
			err := fs.delete_file(file.file)
			if err != {} {
				show_error_message(err)
			}
		}
	}

	reload_file_panel(&_left_panel)
	reload_file_panel(&_right_panel)
}

/*
	Sets command bar as current dialog
*/
goto_command_mode :: proc() {
	assert(_current_dialog == nil)
	_current_dialog = create_command_bar()
}

