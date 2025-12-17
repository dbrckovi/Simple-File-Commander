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
	Dispatches the thread request to current dialog
*/
handle_thread_request :: proc(widget: ^Widget) {
	#partial switch &w in widget {
	case FileCopyBox:
		handle_thread_request_file_copy_box(&w)
	case:
		panic("Widget is not of type that can handle thread request")
	}
}

/*
	Destroys currently active dialog
*/
destroy_current_dialog :: proc() {
	// WARN: There is inconsistency here
	// Specific widgets are designed to be flexible (every proc gets a widget in parameters)
	// however, their destroy proc is destroying _current_dialog (assuming they are the dialog)

	assert(_current_dialog != nil)

	switch &w in _current_dialog {
	case MessageBox:
		destroy_messagebox(&w)
	case CommandBar:
		destroy_command_bar(&w)
	case TextViewer:
		destroy_text_viewer(&w)
	case FileCopyBox:
		destroy_file_copy_box(&w)
	}

	_current_dialog = nil
}

