package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:mem" //TODO: use something from it
import "core:os"
import "core:sys/posix"

_should_run := true //Once this becomes false, program exits
_last_keyboard_event: t.Keyboard_Input //Last input received from keyboard
_last_mouse_event: t.Mouse_Input //Last input received from mouse
_pid: posix.pid_t //This program's process ID
_left_panel: FilePanel //Left panel data
_right_panel: FilePanel //Right panel data

main :: proc() {
	_pid = posix.getpid()

	init()

	for _should_run {
		draw()
		update()
	}

	deinit_screen()
}

init :: proc() {
	init_screen()
	init_panels()
}

init_panels :: proc() {
	_left_panel.current_dir = os.get_current_directory()
	reload_file_panel(&_left_panel)

	_right_panel.current_dir = os.get_current_directory()
	reload_file_panel(&_right_panel)
}

/*
	Waits for something interesting to happen and handles it
*/
update :: proc() {

	input, screen_size_changed := wait_for_interesting_event()

	if screen_size_changed {
		deinit_screen()
		init_screen()
	}

	if input != nil {

		switch i in input {
		case t.Keyboard_Input:
			_last_keyboard_event = i
			if i.key == .Escape do _should_run = false
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

