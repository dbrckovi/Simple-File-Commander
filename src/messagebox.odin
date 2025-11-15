package sfc

import t "../lib/TermCL"

MessageBoxData :: struct {
	text: string,
}

messagebox_create :: proc(text, title: string) {
	assert(_current_dialog == {})

	_current_dialog = {
		appearance = {
			location = WidgetLocation_Center{height = 4},
			border_style = .single,
			title = title,
			main_color = _current_theme.dialog_main,
			title_color = _current_theme.dialog_main,
		},
		procedures = {
			handle_input = messagebox_handle_input,
			draw_content = messagebox_draw_content,
		},
		data = MessageBoxData{text = text},
	}
}

messagebox_destroy :: proc() {
	data, ok := _current_dialog.data.(MessageBoxData)
	if !ok {
		panic("Widget is not a Messagebox")
	}

	widget_destroy()
	delete(data.text)
	_current_dialog = {}
}

messagebox_handle_input :: proc(input: t.Input) {
	#partial switch i in input {
	case t.Keyboard_Input:
		if i.key == .Escape {
			messagebox_destroy()
		}
	}
}

messagebox_draw_content :: proc() {
	background_drawn := widget_draw_background()
	if background_drawn {
		//TODO: draw content
	}
}

