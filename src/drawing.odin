package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:strings"

_screen: t.Screen
_last_foreground: t.Any_Color = .White
_last_background: t.Any_Color = {}
_splitter_fraction: f32 = .5

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
	Periodically redraws entire screen
*/
draw :: proc() {
	t.set_color_style(&_screen, _current_theme.main.foreground, _current_theme.main.background)
	t.clear(&_screen, .Everything)
	defer t.blit(&_screen)

	draw_main_gui()
}


/*
	Draws borders for main gui
*/
draw_main_gui :: proc() {

	main_splitter_x := uint(f32(_screen.size.w) * _splitter_fraction)
	draw_command_area := _last_error != nil

	set_colors(_current_theme.main.foreground, _current_theme.main.background)

	//main border
	draw_rectangle({0, 0, int(_screen.size.w), int(_screen.size.h)}, true)

	//center
	draw_vertical_line({int(main_splitter_x), 1}, int(_screen.size.h - 2), true)
	write("╦", {main_splitter_x, 0})
	write("╩", {main_splitter_x, _screen.size.h - 1})

	//command / error area
	if draw_command_area {
		command_area_top_y := _screen.size.h - 3
		draw_horizontal_line({1, int(command_area_top_y)}, int(_screen.size.w) - 2, true)
		write("╠", {0, command_area_top_y})
		write("╩", {main_splitter_x, command_area_top_y})
		write("╣", {_screen.size.w - 1, command_area_top_y})
		write(" ", {main_splitter_x, command_area_top_y + 1})
		write("═", {main_splitter_x, _screen.size.h - 1})

		if _last_error != nil {
			error_message := fmt.tprintf("Error: %v", _last_error)
			write_cropped(
				error_message,
				{2, command_area_top_y + 1},
				.Red,
				nil,
				_screen.size.w - 2,
			)
		}
	}

	//panel bottom
	panel_bottom_x := _screen.size.h - (draw_command_area ? 5 : 3)
	draw_horizontal_line({1, int(panel_bottom_x)}, int(_screen.size.w) - 2, false)
	write("╟", {0, panel_bottom_x})
	write("╫", {main_splitter_x, panel_bottom_x})
	write("╢", {_screen.size.w - 1, panel_bottom_x})

	draw_panel(&_left_panel, 0, main_splitter_x, panel_bottom_x)
	draw_panel(&_right_panel, main_splitter_x, _screen.size.w - 1, panel_bottom_x)
}


/*
	Draws layout of a single panel
	left - x coordinate of the left border
	right - x coordinate of the right border
	bottom - y coordinate of the bottom single line
*/
draw_panel :: proc(panel: ^FilePanel, left: uint, right: uint, bottom: uint) {

	panel_width := right - left
	draw_date := panel_width >= 40
	draw_size := panel_width >= 20
	current_rightmost_border := right
	date_left_x: uint
	size_left_x: uint
	sort_char := panel.sort_direction == .ascending ? "↓" : "↑"

	panel.sort_column = .size

	//date
	if draw_date {
		current_rightmost_border = current_rightmost_border - 19
		date_left_x = current_rightmost_border
		draw_vertical_line({int(date_left_x), 1}, int(bottom - 1))
		write("╤", {date_left_x, 0})
		write("┴", {date_left_x, bottom})

		write(
			"Date",
			{date_left_x + 13, 1},
			_current_theme.column_header.foreground,
			_current_theme.column_header.background,
		)
		if panel.sort_column == .date {
			write(
				sort_char,
				{date_left_x + 17, 1},
				_current_theme.sort_indicator.foreground,
				_current_theme.sort_indicator.background,
			)
		}
	}

	//size
	if draw_size {
		current_rightmost_border = current_rightmost_border - 10
		size_left_x = current_rightmost_border
		draw_vertical_line({int(size_left_x), 1}, int(bottom - 1))
		write("╤", {size_left_x, 0})
		write("┴", {size_left_x, bottom})

		write(
			"Size",
			{size_left_x + 4, 1},
			_current_theme.column_header.foreground,
			_current_theme.column_header.background,
		)
		if panel.sort_column == .size {
			write(
				sort_char,
				{size_left_x + 8, 1},
				_current_theme.sort_indicator.foreground,
				_current_theme.sort_indicator.background,
			)
		}
	}

	//current directory
	write_cropped(panel.current_dir, {left + 2, 0}, nil, nil, right - 1)

	//name
	write(
		"Name",
		{left + 2, 1},
		_current_theme.column_header.foreground,
		_current_theme.column_header.background,
	)
	if panel.sort_column == .name {
		write(
			sort_char,
			{left + 6, 1},
			_current_theme.sort_indicator.foreground,
			_current_theme.sort_indicator.background,
		)
	}
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
	double_border := false,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
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
	double_border := false,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
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
	double_border := false,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
) {
	right := rect.x + rect.w - 1
	bottom := rect.y + rect.h - 1

	set_colors(foreground, background)

	write(double_border ? "╔" : "┌", {uint(rect.x), uint(rect.y)})
	write(double_border ? "╗" : "┐", {uint(right), uint(rect.y)})
	write(double_border ? "╚" : "└", {uint(rect.x), uint(bottom)})
	write(double_border ? "╝" : "┘", {uint(right), uint(bottom)})

	draw_horizontal_line({rect.x + 1, rect.y}, rect.w - 2, double_border)
	draw_horizontal_line({rect.x + 1, bottom}, rect.w - 2, double_border)
	draw_vertical_line({rect.x, rect.y + 1}, rect.h - 2, double_border)
	draw_vertical_line({right, rect.y + 1}, rect.h - 2, double_border)

}

/*
	Writes text to location
 	- text: text to write
 	- location: screen coordinates where text writing will start
 	- foreground: optional foreground color
 	- background: optional background color
 	- temp_colors: if true, after writing resets colors to previous values
 	

 	Note: if color is not defined, a last used color will be used
*/
write :: proc(
	text: string,
	location: [2]uint,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	temp_colors: bool = true,
) {
	old_foreground := _last_foreground
	old_background := _last_background

	set_colors(foreground, background)
	if location.y >= _screen.size.h || location.x >= _screen.size.w {
		return
	}

	move_cursor(location.x, location.y)
	t.write(&_screen, text)

	if temp_colors {
		set_colors(old_foreground, old_background)
	}
}

/*
Writes string to screen, cropping it at screen width, or at custom 'max_width'
*/

write_cropped :: proc(
	text: string,
	location: [2]uint,
	foreground: t.Any_Color = nil,
	background: t.Any_Color = nil,
	max_width: uint = 0,
) {
	crop_column: uint = _screen.size.w

	if max_width > 0 && max_width < _screen.size.w && location.x <= max_width {
		crop_column = max_width
	}

	space_available := crop_column - location.x

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

