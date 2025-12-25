package sfc

import t "../lib/TermCL"

Widget :: union {
	MessageBox,
	CommandBar,
	TextViewer,
	FileCopyBox,
}

/*
	Enumerates possible locations for dialogs
*/
WidgetLocation :: enum {
	full_screen,
	middle,
	bottom_line,
}

BorderStyle :: enum {
	none,
	single,
	double,
}

handle_widget_input :: proc(widget: ^Widget, input: t.Input) {
	#partial switch &w in widget {
	case CommandBar:
		handle_input_command_bar(&w, input)
	case FileCopyBox:
		handle_input_file_copy_box(&w, input)
	}
}

handle_layout_change :: proc(widget: ^Widget) {
	switch &w in widget {
	case MessageBox:
		perform_messagebox_layout(&w)
	case CommandBar:
		break
	case TextViewer:
		perform_text_viewer_layout(&w)
	case FileCopyBox:
		perform_file_copy_box_layout(&w)
	}
}

/*
	Destroys currently active top-level dialog
*/
destroy_top_dialog :: proc() {
	assert(len(_dialogs) > 0)
	top_index := len(_dialogs) - 1

	top_widget := _dialogs[top_index]

	switch &w in top_widget {
	case MessageBox:
		destroy_messagebox(&w)
	case CommandBar:
		destroy_command_bar(&w)
	case TextViewer:
		destroy_text_viewer(&w)
	case FileCopyBox:
		destroy_file_copy_box(&w)
	}

	unordered_remove(&_dialogs, top_index)
}

