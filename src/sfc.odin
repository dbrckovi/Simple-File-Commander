package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"

should_run := true

main :: proc() {

	s := init()

	for should_run {
		loop(&s)
	}

	deinit(&s)
}

// initialization on start
init :: proc() -> t.Screen {
	tb.set_backend()
	screen := t.init_screen()

	t.set_term_mode(&screen, .Raw)

	t.clear(&screen, .Everything)
	t.move_cursor(&screen, 0, 0)

	t.blit(&screen)
	return screen
}

loop :: proc(screen: ^t.Screen) {
	t.clear(screen, .Everything)
	defer t.blit(screen)

	t.move_cursor(screen, 0, 0)
	t.write(screen, "Press `Esc` to exit")

	t.move_cursor(screen, 2, 0)

	input := t.read_blocking(screen)

	switch i in input {
	case t.Keyboard_Input:
		t.move_cursor(screen, 4, 0)
		t.write(screen, "Keyboard: ")
		t.writef(screen, "%v", i)
		if i.key == .Escape do should_run = false
	case t.Mouse_Input:
		t.move_cursor(screen, 6, 0)
		t.write(screen, "Mouse: ")
		t.writef(screen, "%v", i)
	}
}

// deinitialization on exit
deinit :: proc(s: ^t.Screen) {
	t.destroy_screen(s)
}


