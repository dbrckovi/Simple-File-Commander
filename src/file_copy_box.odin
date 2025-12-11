package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sync"
import "errors"
import fs "filesystem"

FileCopyBox :: struct {
	panel:      BoxWithTitle,
	started:    bool, //specifies whether the copy operation has started (TODO: maybe merge with copy_token.run?)
	copy_token: FileCopyToken, //struct for communication with the copy thread
}

create_file_copy_box :: proc(
	source_files: [dynamic]SfcFileInfo, //array of items which were selected in the source panel.
	destination: string, //destination directory. Set by caller thread
	allocator := context.allocator,
) -> (
	FileCopyBox,
	errors.SfcException,
) {
	box: FileCopyBox
	box.panel.title = strings.clone("Preparing to copy", allocator)
	box.panel.border = .double

	using box.copy_token.progress
	//TODO: this doesn't make much sense here because options are modified later in GUI
	for info in source_files {
		if info.file.is_dir {
			count, size, count_error := fs.count_files(info.file.fullpath, true)
			if count_error != {} {
				return {}, count_error
			}
			total_count += count
			total_size += size
		} else {
			total_count += 1
			total_size += info.file.size
		}
	}

	perform_file_copy_box_layout(&box)

	//TODO: source_files must be deleted probably even before the main copy thread starts

	return box, {}
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
	if box.started do return

	switch i in input {
	case t.Keyboard_Input:
		if i.key == .F {
			toggle_maybe_bool(&box.copy_token.overwrite_files)
		}
		if i.key == .Enter {
			panic("Not implemented")
		}
	case t.Mouse_Input:
	}
}

draw_file_copy_box :: proc(box: ^FileCopyBox) {
	draw_box_with_title(&box.panel)

	left := uint(box.panel.rectangle.x + 2)
	top := uint(box.panel.rectangle.y + 1)

	str_file_count := fmt.tprint(sync.atomic_load(&box.copy_token.total_count))
	files_size := sync.atomic_load(&box.copy_token.total_size)
	str_total_size := get_bytes_with_units(files_size)

	draw_label_with_value({left + 6, top}, "Files:", str_file_count, 14)
	draw_label_with_value({left + 6, top + 2}, "Total size:", str_total_size, 14)

	using box.copy_token
	draw_file_copy_check_box({left, top + 4}, "f", "Overwrite files", overwrite_files)

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

