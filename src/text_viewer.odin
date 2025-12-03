package sfc

import "core:strings"

TextViewer :: struct {
	panel:     BoxWithTitle,
	text:      string,
	word_wrap: bool,
}

create_text_viewer :: proc(
	text, title: string,
	border: BorderStyle = .double,
	wrap: bool = true,
	allocator := context.allocator,
) -> TextViewer {
	assert(len(text) > 0)
	box: TextViewer
	box.text = len(text) > 0 ? strings.clone(text, allocator) : {}
	box.panel.title = len(title) > 0 ? strings.clone(title, allocator) : {}
	box.panel.border = border
	box.word_wrap = wrap
	perform_text_viewer_layout(&box)
	return box
}

destroy_text_viewer :: proc(box: ^TextViewer) {
	delete_text_viewer_lines(box)
	if len(box.panel.title) > 0 {
		delete(box.panel.title)
	}
	if len(box.text) > 0 {
		delete(box.text)
	}
}

delete_text_viewer_lines :: proc(box: ^TextViewer) {
	//TODO: delete lines (look at messagebox)
}

perform_text_viewer_layout :: proc(box: ^TextViewer) {
	EDGE_DISTANCE_H :: 2
	EDGE_DISTANCE_V :: 1

	box.panel.rectangle.x = EDGE_DISTANCE_H
	box.panel.rectangle.y = EDGE_DISTANCE_V
	box.panel.rectangle.w = int(_screen.size.w) - EDGE_DISTANCE_H * 2
	box.panel.rectangle.h = int(_screen.size.h) - EDGE_DISTANCE_V * 2

	delete_text_viewer_lines(box)
	//TODO: regenerate lines based on word wrap
}

draw_text_viewer :: proc(box: ^TextViewer) {
	draw_box_with_title(&box.panel)

	//TODO: draw the text
	// rect := box.panel.rectangle
	// rect = {rect.x + 1, rect.y + 1, rect.w - 2, rect.h - 2}

	// max_width := uint(rect.w) + uint(rect.x)
	// for line, i in box.lines {
	// 	x := uint(rect.w - strings.rune_count(line)) / 2 + uint(rect.x)
	// 	y := uint(rect.y + i)
	// 	if y < uint(rect.h + rect.y) {
	// 		write(line, {x, y})
	// 	}
	// }
}

