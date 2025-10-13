package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"

_should_run := true
_screen: t.Screen
_last_keyboard_event: t.Keyboard_Input
_last_mouse_event: t.Mouse_Input

main :: proc() {

	init_screen()

	for _should_run {
		draw()
		update()
	}

	deinit_screen()
}

// initialization on start
init_screen :: proc() {
	_screen = t.init_screen(tb.VTABLE)
	_screen.size = t.get_term_size()

	t.set_term_mode(&_screen, .Raw)

	t.clear(&_screen, .Everything)
	t.move_cursor(&_screen, 0, 0)
	// t.hide_cursor(true)
	t.blit(&_screen)
}

draw :: proc() {
	t.clear(&_screen, .Everything)
	defer t.blit(&_screen)

	write_cropped("Press 'ESC' to exit", {0, _screen.size.h - 1}, .Yellow)

	write_cropped("Keyboard:", {0, _screen.size.h - 2}, .Green)
	write_cropped(fmt.tprintf("%v", _last_keyboard_event), {10, _screen.size.h - 2}, .White)

	write_cropped("Mouse:", {0, _screen.size.h - 3}, .Green)
	write_cropped(fmt.tprintf("%v", _last_mouse_event), {10, _screen.size.h - 3}, .White)

	write_cropped("Screen: ", {0, _screen.size.h - 4}, .Green)
	write_cropped(fmt.tprintf("%v", _screen.size), {10, _screen.size.h - 4}, .White)

	// draw_rectangle({10, 10, 20, 5})


	for i := 50; i < 79; i += 1 {
		draw_vertical_line({i, 0}, 20)
	}
	// if _last_mouse_event != nil {
	move_cursor(_last_mouse_event.coord.x, _last_mouse_event.coord.y)
	// }
}

update :: proc() {

	input := wait_for_input()

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

wait_for_input :: proc() -> t.Input {
	input: t.Input
	should_break := false
	for {
		new_size := t.get_term_size()

		if new_size != _screen.size {
			deinit_screen()
			init_screen()
			should_break = true
		}

		input = t.read(&_screen)
		if input != nil do should_break = true

		if should_break do break
	}

	return input
}

// deinitialization on exit
deinit_screen :: proc() {
	t.destroy_screen(&_screen)
}

