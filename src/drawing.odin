package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:strings"

_last_foreground: t.Any_Color = .White
_last_background: t.Any_Color = {}

Rectangle :: struct {
	x: uint,
	y: uint,
	w: uint,
	h: uint,
}

/*
	Draws hoizontal line
	- point: starting coordinate 
	- length: line length. Negative causes the line to be drawn leftwards
 	- foreground: optional foreground color
 	- background: optional background color
	- double_border: if true, draws double line instead of single
*/
draw_horizontal_line :: proc(
	point: [2]int,
	length: int,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	double_border := false,
) {
	x := point.x
	y := point.y
	length_normalized := length

	if length == 0 || y >= int(_screen.size.h) {
		return
	} else if length_normalized < 0 {
		//normalize
		length_normalized = -length_normalized
		x = x - length_normalized + 1
	}

	for i: uint = uint(max(x, 0)); i < min(uint(x + length_normalized), _screen.size.w); i += 1 {
		write(double_border ? "═" : "─", {i, uint(y)})
	}
}

/*
	Draws vertical line
	- point: starting coordinate 
	- length: line length. Negative causes the line to be drawn upwards
 	- foreground: optional foreground color
 	- background: optional background color
	- double_border: if true, draws double line instead of single
*/
draw_vertical_line :: proc(
	point: [2]int,
	length: int,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	double_border := false,
) {
	x := point.x
	y := point.y
	length_normalized := length

	if length == 0 || x >= int(_screen.size.w) {
		return
	} else if length_normalized < 0 {
		//normalize
		length_normalized = -length_normalized
		y = y - length_normalized + 1
	}

	for i: uint = uint(max(y, 0)); i < min(uint(y + length_normalized), _screen.size.h); i += 1 {
		write(double_border ? "║" : "│", {uint(x), i})
	}
}


draw_rectangle :: proc(
	rect: Rectangle,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	double_border := false,
) {
	right := rect.x + rect.w
	bottom := rect.y + rect.h

	set_colors(foreground, background)
	if rect.x >= _screen.size.w || rect.y >= _screen.size.h {
		return
	}

	write("┌", {rect.x, rect.y})

	if right <= _screen.size.w {
		write("┐", {right, rect.y})
	}

	if bottom < _screen.size.h {
		write("└", {rect.x, bottom})
	}

	for x: uint = rect.x + 1; x < min(right - 1, _screen.size.w); x += 1 {
		write("─", {x, rect.y})
		if bottom < _screen.size.h {
			write("─", {x, bottom})
		}
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

