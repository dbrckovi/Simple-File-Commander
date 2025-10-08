package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"

_should_run := true
_screen: t.Screen
_lastKeyboardEvent: t.Keyboard_Input
_lastMouseEvent: t.Mouse_Input
BG_COLOR: t.Any_Color = {}

main :: proc() {

	init()

	for _should_run {
		loop()
	}

	deinit()
}

// initialization on start
init :: proc() {
	_screen = t.init_screen(tb.VTABLE)

	t.set_term_mode(&_screen, .Raw)

	t.clear(&_screen, .Everything)
	t.move_cursor(&_screen, 0, 0)

	t.blit(&_screen)
}

draw :: proc() {
	t.clear(&_screen, .Everything)
	defer t.blit(&_screen)
	t.move_cursor(&_screen, 0, 0)
	t.write(&_screen, "Press `Esc` to exit")

	t.move_cursor(&_screen, 4, 0)
	t.set_color_style(&_screen, .Green, BG_COLOR)
	t.write(&_screen, "Keyboard: ")
	t.set_color_style(&_screen, .White, BG_COLOR)
	t.writef(&_screen, "%v", _lastKeyboardEvent)

	t.move_cursor(&_screen, 6, 0)
	t.set_color_style(&_screen, .Green, BG_COLOR)
	t.write(&_screen, "Mouse: ")
	t.set_color_style(&_screen, .White, BG_COLOR)
	t.writef(&_screen, "%v", _lastMouseEvent)
}

update :: proc() {
	input := t.read_blocking(&_screen)

	switch i in input {
	case t.Keyboard_Input:
		_lastKeyboardEvent = i
		if i.key == .Escape do _should_run = false
	case t.Mouse_Input:
		_lastMouseEvent = i
	}
}


loop :: proc() {

	draw()

	update()


	t.move_cursor(&_screen, 2, 0)

}

// deinitialization on exit
deinit :: proc() {
	t.destroy_screen(&_screen)
}

