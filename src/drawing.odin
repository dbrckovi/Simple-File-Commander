package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:strings"

_last_foreground: t.Any_Color = .White
_last_background: t.Any_Color = {}

draw_rectangle :: proc(
	rect: [4]uint,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
) {
	set_colors(foreground, background)
	if (rect.x >= _screen.size.w || rect.y >= _screen.size.h) do return

	for x: uint = rect.x; x < min(rect.x + rect.w, _screen.size.w); x += 1 {
		//TODO: this is probybly wrong. Continue
		write("X", {x, rect.z})

		write("X", {x, rect.y + rect.w})
	}
}

/*
	Writes text to location
 	- text: text to write
 	- location: screen coordinates where text writing will start
 	- foreground: optional foreground color
 	- background: optional background color

 	Note: if color is not defined, a last used color will be used
*/
write :: proc(
	text: string,
	location: [2]uint,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
) {
	set_colors(foreground, background)
	if (location.y >= _screen.size.h) do return

	move_cursor(location.x, location.y)
	t.write(&_screen, text)
}

write_cropped :: proc(
	text: string,
	location: [2]uint,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
) {
	space_available := _screen.size.w - location.x

	move_cursor(location.x, location.y)
	if len(text) > int(space_available) {
		write(text[:space_available], location, foreground, background)
	} else {
		write(text, location, foreground, background)
		// t.write(&_screen, text)
	}
}

/*
	Sets new color style.
	Only replaces colors which are not 'nil' and if they are different than last used values
*/

set_colors :: proc(foreground: t.Any_Color = nil, background: t.Any_Color = nil) {
	if foreground != nil || background != nil {
		if foreground != nil do _last_foreground = foreground
		if background != nil do _last_background = background
		t.set_color_style(&_screen, _last_foreground, _last_background)
	}
}

/*
	Moves cursor to specified location
*/
move_cursor :: proc(x, y: uint) {
	t.move_cursor(&_screen, y, x)
}

