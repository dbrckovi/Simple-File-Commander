package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:sys/posix"

_should_run := true
_last_keyboard_event: t.Keyboard_Input
_last_mouse_event: t.Mouse_Input
_pid: posix.pid_t


main :: proc() {

	_pid = posix.getpid()

	init_screen()

	for _should_run {
		draw()
		update()
	}

	deinit_screen()
}


/*
	Periodically redraws entire screen
*/
draw :: proc() {
	t.clear(&_screen, .Everything)
	defer t.blit(&_screen)

	//half screen
	draw_vertical_line({int(_screen.size.w) / 2, 0}, int(_screen.size.h), .Black)
	draw_horizontal_line({0, int(_screen.size.h) / 2}, int(_screen.size.w), .Black)
	write("┼", {_screen.size.w / 2, _screen.size.h / 2}, .Black)

	//mouse cursor
	draw_vertical_line({int(_last_mouse_event.coord.x), 0}, int(_screen.size.h), .Cyan)
	draw_horizontal_line({0, int(_last_mouse_event.coord.y)}, int(_screen.size.w), .Cyan)
	write("┼", {_last_mouse_event.coord.x, _last_mouse_event.coord.y}, .Cyan)

	write_cropped(fmt.tprintf("PID: %v", _pid), {1, _screen.size.h - 2}, .Yellow)
	write_cropped(fmt.tprintf("%v", _last_keyboard_event), {1, _screen.size.h - 3}, .White)
	write_cropped(fmt.tprintf("%v", _last_mouse_event), {1, _screen.size.h - 4}, .White)
	write_cropped(fmt.tprintf("%v", _screen.size), {1, _screen.size.h - 5}, .White)

	//border
	draw_rectangle({0, 0, int(_screen.size.w), int(_screen.size.h)}, .White, nil, true)

	move_cursor(_last_mouse_event.coord.x, _last_mouse_event.coord.y)
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

