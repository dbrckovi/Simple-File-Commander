package sfc

import t "../lib/TermCL"

Widget :: union {
	MessageBox,
	CommandBar,
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
		{
			handle_input_command_bar(&w, input)
		}
	}

}

handle_layout_change :: proc(widget: ^Widget) {
	#partial switch &widget in _current_dialog {
	case MessageBox:
		perform_messagebox_layout(&widget)
	}
}


destroy_current_dialog :: proc() {
	switch &widget in _current_dialog {
	case MessageBox:
		destroy_messagebox(&widget)
	case CommandBar:
		destroy_command_bar(&widget)
	}

	_current_dialog = nil
}

