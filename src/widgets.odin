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

}

handle_layout_change :: proc(widget: ^Widget) {
	switch &widget in _current_dialog {
	case MessageBox:
		perform_messagebox_layout(&widget)
	case CommandBar:
		perform_command_bar_layout(&widget)
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

