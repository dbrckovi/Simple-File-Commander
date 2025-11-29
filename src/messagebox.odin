package sfc

import "core:strings"

MessageBox :: struct {
	panel: BoxWithTitle,
	text:  string,
	lines: [dynamic]string,
}

/*
	Creates and returns a MessageBox widget
	@params text: text to be shown by the messagebox.
			String is cloned using context.allocator.
	@params title: title of the messagebox.
			String is cloned using context.allocator.
	@params border: defines border style for messagebox
*/
create_messagebox :: proc(
	text, title: string,
	border: BorderStyle = .double,
	allocator := context.allocator,
) -> MessageBox {
	assert(len(text) > 0)
	box: MessageBox
	box.text = len(text) > 0 ? strings.clone(text, allocator) : {}
	box.panel.title = len(title) > 0 ? strings.clone(title, allocator) : {}
	box.panel.border = border
	perform_messagebox_layout(&box)
	return box
}

destroy_messagebox :: proc(box: ^MessageBox) {
	delete_messagebox_lines(box)
	if len(box.panel.title) > 0 {
		delete(box.panel.title)
	}
	if len(box.text) > 0 {
		delete(box.text)
	}
}

/*
	(Re)wraps the messagebox text and size based on current screen size
*/
perform_messagebox_layout :: proc(box: ^MessageBox) {
	EDGE_DISTANCE_H :: 2
	EDGE_DISTANCE_V :: 1

	max_width := int(_screen.size.w) - EDGE_DISTANCE_H * 2
	max_height := _screen.size.h - EDGE_DISTANCE_V * 2

	delete_messagebox_lines(box)
	box.lines = wrap_text(box.text, max_width - 2)

	box.panel.rectangle.x = EDGE_DISTANCE_H
	box.panel.rectangle.w = max_width
	box.panel.rectangle.h = len(box.lines) + 2
	if box.panel.rectangle.h > int(max_height) {
		box.panel.rectangle.h = int(max_height)
	}
	box.panel.rectangle.y = (int(_screen.size.h) - box.panel.rectangle.h) / 2
}

delete_messagebox_lines :: proc(box: ^MessageBox) {
	if len(box.lines) > 0 {
		for line in box.lines {
			delete(line)
		}
		delete(box.lines)
	}
}

draw_messagebox :: proc(box: ^MessageBox) {
	draw_box_with_title(&box.panel)

	rect := box.panel.rectangle
	rect = {rect.x + 1, rect.y + 1, rect.w - 2, rect.h - 2}

	max_width := uint(rect.w) + uint(rect.x)
	for line, i in box.lines {
		x := uint(rect.w - strings.rune_count(line)) / 2 + uint(rect.x)
		y := uint(rect.y + i)
		if y < uint(rect.h + rect.y) {
			write(line, {x, y})
		}
	}
}

