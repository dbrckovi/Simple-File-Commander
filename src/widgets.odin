package sfc

import t "../lib/TermCL"
import "core:sync"

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

WidgetStack :: struct {
	dialogs: [dynamic]Widget,
	mutex:   sync.Mutex,
}

/*
	Handles imput of specific widget
*/
handle_widget_input :: proc(widget: ^Widget, input: t.Input) {
	#partial switch &w in widget {
	case CommandBar:
		handle_input_command_bar(&w, input)
	case FileCopyBox:
		handle_input_file_copy_box(&w, input)
	}
}

/*
	Handles layout change of specific widget
*/
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
	Destroys currently active top-level widget
*/
destroy_top_widget :: proc(stack: ^WidgetStack) {
	sync.lock(&stack.mutex)
	top_widget: ^Widget
	top_index := len(&stack.dialogs) - 1
	if top_index >= 0 {
		top_widget = &stack.dialogs[top_index]
	}
	if top_widget != nil {
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
		unordered_remove(&stack.dialogs, top_index)
	}
	sync.unlock(&stack.mutex)
}

init_widget_stack :: proc() -> WidgetStack {
	ret: WidgetStack = {
		dialogs = make([dynamic]Widget, context.allocator),
	}

	return ret
}

/*
	Adds specified widget to the top of the stack (Thread-safe)
*/
add_widget :: proc(stack: ^WidgetStack, widget: Widget) {
	sync.lock(&stack.mutex)
	append(&stack.dialogs, widget)
	sync.unlock(&stack.mutex)
}

/*
	Gets the number of widgets on a WidgetStack (Thread-safe)
*/
get_widget_count :: proc(stack: ^WidgetStack) -> int {
	ret: int
	sync.lock(&stack.mutex)
	ret = len(stack.dialogs)
	sync.unlock(&stack.mutex)
	return ret
}

/*
	Locks the widget stack mutex and triggers draw for each widget
*/
draw_widgets :: proc(stack: ^WidgetStack) {
	sync.lock(&stack.mutex)
	for &widget in stack.dialogs {
		draw_widget(&widget)
	}
	sync.unlock(&stack.mutex)
}

/*
		Locks the widget stack mutex and triggers handle_layout_change for each widget

*/
widgets_handle_layout_change :: proc(stack: ^WidgetStack) {
	sync.lock(&stack.mutex)
	for &widget in stack.dialogs {
		handle_layout_change(&widget)
	}
	sync.unlock(&stack.mutex)
}

/*
	Gets a pointer to the top widget (or nil) (Thread-safe)
*/
get_top_widget :: proc(stack: ^WidgetStack) -> ^Widget {
	ret: ^Widget = nil
	sync.lock(&stack.mutex)
	if len(stack.dialogs) > 0 {
		ret = &stack.dialogs[len(stack.dialogs) - 1]
	}
	sync.unlock(&stack.mutex)
	return ret
}

