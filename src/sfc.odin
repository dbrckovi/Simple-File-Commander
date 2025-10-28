package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"

_should_run := true //Once this becomes false, program exits
_last_keyboard_event: t.Keyboard_Input //Last input received from keyboard
_last_mouse_event: t.Mouse_Input //Last input received from mouse
_pid: posix.pid_t //This program's process ID
_left_panel: FilePanel //Left panel data
_right_panel: FilePanel //Right panel data
_current_theme: Theme
_focused_panel: ^FilePanel

_last_error: os.Error = nil

main :: proc() {
	_last_error = .Broken_Pipe

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
	init_screen()
	init_panels()
	reset_theme_to_default(&_current_theme)
}

init_panels :: proc() {
	_left_panel.current_dir = os.get_current_directory(context.allocator)
	_left_panel.files = make([dynamic]os.File_Info, 0, context.allocator)
	reload_file_panel(&_left_panel)

	_right_panel.current_dir = os.get_current_directory(context.allocator)
	_right_panel.files = make([dynamic]os.File_Info, 0, context.allocator)
	reload_file_panel(&_right_panel)

	_focused_panel = &_left_panel
}

/*
	Waits for something interesting to happen and handles it
*/
update :: proc() {

	input, screen_size_changed := wait_for_interesting_event()

	if screen_size_changed {
		deinit_screen()
		init_screen()

		recalculate_indexes(&_left_panel)
		recalculate_indexes(&_right_panel)
	}

	if input != nil {

		switch i in input {
		case t.Keyboard_Input:
			//TODO: handle through keymap (which needs to be developed)
			_last_keyboard_event = i
			if i.key == .Escape do _should_run = false
			if i.key == .Tab do swap_focused_panel()
			if i.key == .Backspace do cd_up(_focused_panel)
			if i.key == .K do move_file_focus(1)
			if i.key == .I do move_file_focus(-1)
		case t.Mouse_Input:
			_last_mouse_event = i
		}
	}
}

/*
	Waits for something interesting to happen (which would cause the screen to redraw) and returns info on what happened
*/
wait_for_interesting_event :: proc() -> (t.Input, bool) {
	input: t.Input = nil
	screen_size_changed: bool = false
	should_break := false
	for {

		new_size := t.get_term_size()
		if new_size != _screen.size {
			screen_size_changed = true
			should_break = true
		}

		input = t.read(&_screen)

		if screen_size_changed || input != nil {
			break
		}
	}

	return input, screen_size_changed
}

swap_focused_panel :: proc() {
	_focused_panel = _focused_panel == &_left_panel ? &_right_panel : &_left_panel
}

