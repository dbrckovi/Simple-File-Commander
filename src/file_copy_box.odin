package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sync"
import "errors"
import fs "filesystem"

FileCopyBoxState :: enum {
	preparation = 0, // Allows user to specifiy copy settings or cancel, before copying starts
	progress    = 1, // Shows copy progress and allows cancellation
	question    = 2, // When thread needs user's feedback
}

FileCopyBox :: struct {
	panel:      BoxWithTitle,
	state:      FileCopyBoxState,
	copy_token: FileCopyToken, //struct for communication with the copy thread
}

/*
	Creates a FileCopyBox and sends it a list of files and some initial values
*/
create_file_copy_box :: proc(
	source_files: [dynamic]SfcFileInfo, //array of items which were selected in the source panel.
	destination_dir: string, //destination directory. Set by caller thread
	allocator := context.allocator,
) -> (
	FileCopyBox,
	errors.SfcException,
) {
	box: FileCopyBox
	box.panel.title = strings.clone("Preparing to copy", allocator)
	box.panel.border = .double

	file_infos := extract_file_infos(source_files[:], context.temp_allocator)
	count, size, count_error := fs.count_files_in_array(file_infos[:], true)

	if count_error != {} {
		return box, count_error
	}

	using box.copy_token
	source_file_infos = source_files
	destination_dir = strings.clone(destination_dir, allocator)
	total_count = count
	total_size = size

	perform_file_copy_box_layout(&box)
	return box, {}
}

destroy_file_copy_box :: proc(box: ^FileCopyBox) {
	if len(box.panel.title) > 0 {
		delete(box.panel.title)
	}

	if len(box.copy_token.source_file_infos) > 0 {
		delete(box.copy_token.source_file_infos)
	}

	if len(box.copy_token.destination_dir) > 0 {
		delete(box.copy_token.destination_dir)
	}
}

perform_file_copy_box_layout :: proc(box: ^FileCopyBox) {
	box.panel.rectangle.w = 40
	box.panel.rectangle.h = 13
	box.panel.rectangle.x = (int(_screen.size.w) - box.panel.rectangle.w) / 2
	box.panel.rectangle.y = (int(_screen.size.h) - box.panel.rectangle.h) / 2
}

handle_input_file_copy_box :: proc(box: ^FileCopyBox, input: t.Input) {
	switch i in input {
	case t.Keyboard_Input:
		if box.state == .preparation {
			if i.key == .F {
				toggle_maybe_bool(&box.copy_token.overwrite_files, true)
			}
			if i.key == .Enter {
				box.state = .progress
				change_box_with_title_title(&box.panel, "Copying files")
				// start_file_copy_thread(&box.copy_token)
			}
		}
	case t.Mouse_Input:
	}
}

draw_file_copy_box :: proc(box: ^FileCopyBox) {
	draw_box_with_title(&box.panel)

	left := uint(box.panel.rectangle.x + 2)
	top := uint(box.panel.rectangle.y + 1)

	finished_count := sync.atomic_load(&box.copy_token.finished_count)
	finished_size := sync.atomic_load(&box.copy_token.finished_size)

	str_total_count := fmt.tprint(box.copy_token.total_count)
	str_total_size := get_bytes_with_units(box.copy_token.total_size)
	str_finished_count := fmt.tprint(finished_count)
	str_finished_size := fmt.tprint(finished_size)

	switch box.state {
	case .progress:
		draw_label_with_value({left + 6, top + 1}, "Files:", str_total_count, 14)

	case .preparation:
		draw_label_with_value({left + 6, top + 1}, "Files:", str_total_count, 14)
		draw_label_with_value({left + 6, top + 2}, "Total size:", str_total_size, 14)

		using box.copy_token
		draw_file_copy_check_box({left, top + 5}, "f", "Overwrite files", overwrite_files)

		draw_key_with_function({left, top + 9}, "Enter", "Start", 10)
		draw_key_with_function({left, top + 10}, "Esc", "Cancel", 10)
	case .question:
	//TODO: do
	}
}

/*
	Draws checkbox with keyboard shortcur for file-copy dialog
*/
draw_file_copy_check_box :: proc(
	location: [2]uint,
	key: string,
	text: string,
	value: Maybe(bool),
) {
	str_value := "ask"
	if bool_value, ok := value.?; ok {
		str_value = bool_value ? "yes" : "no"
	}

	set_color_pair(_current_theme.dialog_key)
	write(key, location)

	set_color_pair(_current_theme.dialog_main)
	write(text, {location.x + 6, location.y})

	set_color_pair(_current_theme.dialog_main)
	write("[   ]", {location.x + 30, location.y})
	set_color_pair(_current_theme.dialog_value)
	write(str_value, {location.x + 31, location.y})
}

