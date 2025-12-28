package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"
import "core:time"
import err "errors"

main :: proc() {
	_pid = posix.getpid()

	init()

	for _should_run {
		draw()
		update()
		free_all(context.temp_allocator)
	}

	deinit_screen()
}

init :: proc() {
	init_settings()
	load_settings()
	init_screen()
	init_panels()
	init_theme(&_current_theme)
	_widgets = init_widget_stack()
	try_show_welcome_message()
}

init_panels :: proc() {
	_focused_panel = &_left_panel
	cwd := os.get_current_directory(context.temp_allocator)
	left_dir := "/home/dbrckovi/aaa"
	right_dir := "/home/dbrckovi/bbb"
	//TODO: load last dir from settings

	if !os.exists(left_dir) do left_dir = cwd
	if !os.exists(right_dir) do right_dir = cwd

	initialize_file_panel(&_left_panel, left_dir)
	initialize_file_panel(&_right_panel, right_dir)
}

/*
	Waits for something interesting to happen and handles it
*/
update :: proc() {
	data := wait_for_interesting_event(100 * time.Millisecond)
	top_widget: ^Widget = nil
	top_widget = get_top_widget(&_widgets)

	if data.screen_size_changed {
		deinit_screen()
		init_screen()
		recalculate_indexes(&_left_panel)
		recalculate_indexes(&_right_panel)
	}

	if data.input != nil {
		if top_widget != nil {
			i, is_keyboard := data.input.(t.Keyboard_Input)
			if is_keyboard {
				if i.key == .Escape {
					destroy_top_widget(&_widgets)
					return
				}
			}
		} else {
			handle_input_main(data.input)
		}
	}

	if top_widget != nil {
		widget_update(top_widget, data)
	}
}

/*
	Handles mouse and keyboard input when there are not dialogs shown
*/
handle_input_main :: proc(input: t.Input) {
	switch i in input {
	case t.Keyboard_Input:
		if i.key == .Tab do swap_focused_panel()
		if i.key == .J do cd_up(_focused_panel)
		if i.key == .L do navigate_focused_directory()
		if i.key == .Backspace do cd_up(_focused_panel)
		if i.key == .K do move_file_focus(1)
		if i.key == .I do move_file_focus(-1)
		if i.key == .Arrow_Down do move_file_focus(1)
		if i.key == .Arrow_Up do move_file_focus(-1)
		if i.key == .Arrow_Left do cd_up(_focused_panel)
		if i.key == .Arrow_Right do navigate_focused_directory()
		if i.key == .Enter do activate_focused_file_info()
		if i.key == .Num_1 do set_sort_column(_focused_panel, .name)
		if i.key == .Num_2 do set_sort_column(_focused_panel, .size)
		if i.key == .Num_3 do set_sort_column(_focused_panel, .date)
		if i.key == .Insert do toggle_selection_focused_file(.down)
		if i.key == .A do select_all()
		if i.key == .S do toggle_selection_focused_file(.none)
		if i.key == .D do deselect_all()
		if i.key == .X do toggle_selection_focused_file(.down)
		if i.key == .W do toggle_selection_focused_file(.up)
		if i.key == .Semicolon do deselect_all()
		if i.key == .Percent do select_all()
		if i.key == .Period do toggle_show_hidden_files()
		if i.key == .F5 || i.key == .Num_5 do init_copy_process()
		if i.key == .F8 do perform_delete()
		if i.key == .Colon do goto_command_mode()
		if i.key == .R do reload_both_panels()
	case t.Mouse_Input:
	//todo: handle mouse
	}
}

/*
	Holds data that might be important for updating the state of the program
*/
update_data :: struct {
	input:               t.Input, //Hold info on keyboard or mouse event. Null if no such event happened
	screen_size_changed: bool, //True if screen was resized
}

/*
	Waits for something interesting to happen (which would cause the screen to redraw) and returns info on what happened
	@param timeout_ms: number of milliseconds to wait for something interesting. If nothing happens, return anyway
*/
wait_for_interesting_event :: proc(timeout_ms: time.Duration) -> (data: update_data) {
	start := time.now()

	WAIT_LOOP: for {
		data.input = t.read(&_screen)

		new_size := t.get_term_size()
		if new_size != _screen.size {
			data.screen_size_changed = true
		}

		timeout_expired := false
		elapsed := time.diff(start, time.now())
		if elapsed > timeout_ms do timeout_expired = true

		if data.input != nil || data.screen_size_changed || timeout_expired {
			break WAIT_LOOP
		}

		time.sleep(time.Millisecond)
	}

	return data
}

/*
	Shows welcome message if settings allow it and there are no other dialogs
*/
try_show_welcome_message :: proc() {
	if _settings.show_welcome_message && get_widget_count(&_widgets) == 0 {
		title := "Welcome to 'Simple File Commander'"
		sb := strings.builder_make(context.temp_allocator)
		strings.write_rune(&sb, '\n')
		strings.write_string(&sb, "Type :help to see more detailed help.\n")
		strings.write_string(&sb, "Type :quit or :q to exit the program.\n")
		strings.write_rune(&sb, '\n')
		strings.write_string(&sb, "Press 'Esc' to close this message.\n")
		strings.write_rune(&sb, '\n')
		box := create_messagebox(strings.to_string(sb), title)
		add_widget(&_widgets, box)
	}
}

/*
	Called when debug command is executed
*/
debug :: proc() {
}

/*
	Creates, and adds a new error messagebox
*/
show_error_message :: proc {
	show_error_message_fron_SfcException,
	show_error_message_from_string,
}

show_error_message_fron_SfcException :: proc(error: err.SfcException) {
	assert(error != {})

	msg := fmt.tprint(error.message, "\n\n", "ERROR:", error.error)
	box := create_messagebox(msg, "Error")
	add_widget(&_widgets, box)
}

show_error_message_from_string :: proc(error: string) {
	assert(len(error) != 0)

	msg := fmt.tprint(error, "\n\n")
	box := create_messagebox(msg, "Error")
	add_widget(&_widgets, box)
}

