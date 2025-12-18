package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sync"
import "core:sys/posix"
import "core:time"
import err "errors"
import fs "filesystem"

//TODO: Move all of this to a local variable (and pass them to every proc that's now using them directly)
_application_name := "Simple File Commander" //Application name for displaying in GUI
_application_name_short := "sfc" //Name for directories, binaries, links, etc
_should_run := true //Once this becomes false, program exits
_pid: posix.pid_t //This program's process ID
_left_panel: FilePanel //Left panel data
_right_panel: FilePanel //Right panel data
_current_theme: Theme
_focused_panel: ^FilePanel
_settings: Settings
_current_dialog: Widget //currently displayed dialog widget (if any)
_thread_request_pending := false //becomes true briefly when background thread triggers an update

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
	Triggers update and redraw as soon as possible.
	Intended to be called from background threads.
*/
trigger_update :: proc() {
	sync.atomic_store(&_thread_request_pending, true)
}

/*
	Waits for something interesting to happen and handles it
*/
update :: proc() {
	input, screen_size_changed, request_pending := wait_for_interesting_event()

	if screen_size_changed {
		deinit_screen()
		init_screen()
		recalculate_indexes(&_left_panel)
		recalculate_indexes(&_right_panel)
		if _current_dialog != nil {
			handle_layout_change(&_current_dialog)
		}
	}

	if input != nil {
		if _current_dialog != nil {
			i, is_keyboard := input.(t.Keyboard_Input)
			if is_keyboard {
				if i.key == .Escape {
					destroy_current_dialog()
					return
				}
			}

			handle_widget_input(&_current_dialog, input)
		} else {
			handle_input_main(input)
		}
	}

	if request_pending {
		if _current_dialog != nil {
			handle_thread_request(&_current_dialog)
		} else {
			panic("Thread request detected but there are no widgets that could handle it")
		}
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
	Waits for something interesting to happen (which would cause the screen to redraw) and returns info on what happened
*/
wait_for_interesting_event :: proc(
) -> (
	input: t.Input,
	screen_size_changed: bool,
	thread_request_pending: bool,
) {
	WAIT_LOOP: for {
		input = t.read(&_screen)

		new_size := t.get_term_size()
		if new_size != _screen.size {
			screen_size_changed = true
		}


		if sync.atomic_load(&_thread_request_pending) {
			thread_request_pending = true
		}

		if input != nil || screen_size_changed || thread_request_pending {
			break WAIT_LOOP
		}

		time.sleep(time.Millisecond)
	}

	sync.atomic_store(&_thread_request_pending, false)

	return input, screen_size_changed, thread_request_pending
}

/*
	Shows welcome message if settings allow it and there are no other dialogs
*/
try_show_welcome_message :: proc() {
	if _settings.show_welcome_message && _current_dialog == nil {
		title := "Welcome to 'Simple File Commander'"
		sb := strings.builder_make(context.temp_allocator)
		strings.write_rune(&sb, '\n')
		strings.write_string(&sb, "Type :help to see more detailed help.\n")
		strings.write_string(&sb, "Type :quit or :q to exit the program.\n")
		strings.write_rune(&sb, '\n')
		strings.write_string(&sb, "Press 'Esc' to close this message.\n")
		strings.write_rune(&sb, '\n')
		_current_dialog = create_messagebox(strings.to_string(sb), title)
	}
}

/*
	Called when debug command is executed
*/
debug :: proc() {
	destroy_current_dialog()
	_current_dialog = create_messagebox("test", "test")
}

//TODO: redirect to more descriptive error type (when developed)
show_error_message :: proc(error: err.SfcException) {
	assert(error != {})

	if _current_dialog != nil {
		destroy_current_dialog()
	}

	msg := fmt.tprint(error.message, "\n\n", "ERROR:", error.error)
	_current_dialog = create_messagebox(msg, "Error")
}

