package sfc

import t "../lib/TermCL"
import "core:strings"

MessageBoxData :: struct {
	text: string,
}

/*
	Creates and returns a MessageBox widget
	@params text: text to be shown by the messagebox.
			String is cloned using context.allocator.
	@params title: title of the messagebox.
			String is cloned using context.allocator.
*/
messagebox_create :: proc(text, title: string, allocator := context.allocator) -> Widget {
	effective_text: string = len(text) > 0 ? strings.clone(text, allocator) : {}
	effective_title: string = len(title) > 0 ? strings.clone(title, allocator) : {}

	return Widget {
		location = WidgetLocation_Center {
			height = 4, //TODO: measure string
		},
		data = MessageBoxData{text = effective_text},
		title = effective_title,
		border_style = .double,
	}
}

draw_messagebox_content :: proc(data: MessageBoxData, rect: Rectangle) {
	write_cropped(data.text, {uint(rect.x), uint(rect.y)}, uint(rect.w) + uint(rect.x))
}

