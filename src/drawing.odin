package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:strings"

_screen: t.Screen
_last_foreground: t.Any_Color = .White
_last_background: t.Any_Color = {}

Rectangle :: struct {
	x: int,
	y: int,
	w: int,
	h: int,
}


/*
	Initializes the terminal screen
*/
init_screen :: proc() {
	_screen = t.init_screen(tb.VTABLE)
	_screen.size = t.get_term_size()

	t.set_term_mode(&_screen, .Raw)

	t.clear(&_screen, .Everything)
	t.move_cursor(&_screen, 0, 0)
	t.hide_cursor(true)
	t.blit(&_screen)
}


/*
	Destroys the screen object which was created by init_screen
*/
deinit_screen :: proc() {
	t.destroy_screen(&_screen)
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
		write(double_border ? "║" : "│", {uint(x), i}, foreground, background)
	}
}

draw_rectangle :: proc(
	rect: Rectangle,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	double_border := false,
) {
	right := rect.x + rect.w - 1
	bottom := rect.y + rect.h - 1

	set_colors(foreground, background)

	write(double_border ? "╔" : "┌", {uint(rect.x), uint(rect.y)})
	write(double_border ? "╗" : "┐", {uint(right), uint(rect.y)})
	write(double_border ? "╚" : "└", {uint(rect.x), uint(bottom)})
	write(double_border ? "╝" : "┘", {uint(right), uint(bottom)})

	draw_horizontal_line({rect.x + 1, rect.y}, rect.w - 2, nil, nil, double_border)
	draw_horizontal_line({rect.x + 1, bottom}, rect.w - 2, nil, nil, double_border)
	draw_vertical_line({rect.x, rect.y + 1}, rect.h - 2, nil, nil, double_border)
	draw_vertical_line({right, rect.y + 1}, rect.h - 2, nil, nil, double_border)

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
	if location.y >= _screen.size.h || location.x >= _screen.size.w {
		return
	}

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

