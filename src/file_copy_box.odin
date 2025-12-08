package sfc

import "core:strings"

FileCopyBox :: struct {
	panel:      BoxWithTitle,
	started:    bool, //specifis whether the copy operation has started
	copy_token: FileCopyToken, //struct for communication with the copy thread
}

create_file_copy_box :: proc(
	text, title: string,
	border: BorderStyle = .double,
	allocator := context.allocator,
	source_files: ^[dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination: string, //destination directory. Set by caller thread
) -> FileCopyBox {
	assert(len(text) > 0)
	box: FileCopyBox
	box.panel.title = len(title) > 0 ? strings.clone(title, allocator) : {}
	box.panel.border = border

	perform_file_copy_box_layout(&box)

	return box
}

destroy_file_copy_box :: proc(box: ^FileCopyBox) {

}

perform_file_copy_box_layout :: proc(box: ^FileCopyBox) {

}

