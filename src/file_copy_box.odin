package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:strings"

FileCopyBox :: struct {
	panel:      BoxWithTitle,
	started:    bool, //specifis whether the copy operation has started
	copy_token: FileCopyToken, //struct for communication with the copy thread
}

create_file_copy_box :: proc(
	source_files: ^[dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination: string, //destination directory. Set by caller thread
	allocator := context.allocator,
) -> FileCopyBox {
	box: FileCopyBox
	box.panel.title = strings.clone("Preparing to copy", allocator)
	box.panel.border = .double

	perform_file_copy_box_layout(&box)

	return box
}

destroy_file_copy_box :: proc(box: ^FileCopyBox) {
	//TODO: this leaks heavily
	if len(box.panel.title) > 0 {
		delete(box.panel.title)
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
		if i.key == .F {
			toggle_maybe_bool(&box.copy_token.overwrite_files)
		}
		if i.key == .D {
			toggle_maybe_bool(&box.copy_token.overwrite_dirs)
		}
		if i.key == .C {
			toggle_maybe_bool(&box.copy_token.continue_on_error)
		}
		if i.key == .H {
			toggle_maybe_bool(&box.copy_token.copy_hidden)
		}

	//TODO: Enter starts the thread
	case t.Mouse_Input:
	}
}

draw_file_copy_box :: proc(box: ^FileCopyBox) {
	draw_box_with_title(&box.panel)

	left := uint(box.panel.rectangle.x + 2)
	top := uint(box.panel.rectangle.y + 1)

	draw_label_with_value({left + 6, top}, "Files:", "122", 14)
	draw_label_with_value({left + 6, top + 1}, "Directories:", "13", 14)
	draw_label_with_value({left + 6, top + 2}, "Total size:", "14.6 Mb", 14)

	using box.copy_token
	draw_file_copy_check_box({left, top + 4}, "f", "Overwrite files", overwrite_files)
	draw_file_copy_check_box({left, top + 5}, "d", "Overwrite directories", overwrite_dirs)
	draw_file_copy_check_box({left, top + 6}, "c", "Continue on error", continue_on_error)
	draw_file_copy_check_box({left, top + 7}, "h", "Copy hidden items", copy_hidden)

	draw_key_with_function({left, top + 9}, "Enter", "Start", 10)
	draw_key_with_function({left, top + 10}, "Esc", "Cancel", 10)
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

