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
	set_color_pair(_current_theme.main)
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

	set_color_pair(_current_theme.main)

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
			set_color_pair(_current_theme.error_message)
			write_cropped(error_message, {2, command_area_top_y + 1}, _screen.size.w - 2)
		}
	}

	//panel bottom
	panel_bottom_x := _screen.size.h - (draw_command_area ? 5 : 3)
	set_color_pair(_current_theme.main)
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

	//TODO: Rethink color handling. This is too convoluted

	panel_width := right - left
	draw_date := panel_width >= 40
	draw_size := panel_width >= 20
	current_rightmost_border := right
	date_left_x: uint
	size_left_x: uint
	name_left_x: uint = left + 2
	sort_char := panel.sort_direction == .ascending ? "↓" : "↑"
	panel_inner_bg :=
		_focused_panel == panel ? _current_theme.focused_panel.bg : _current_theme.main.bg

	//background
	paint_rectangle({int(left + 1), 1, int(right - left - 1), int(bottom - 1)}, panel_inner_bg)

	//date column and lines
	if draw_date {
		current_rightmost_border = current_rightmost_border - 19
		date_left_x = current_rightmost_border

		set_colors(_current_theme.main.fg, panel_inner_bg)
		draw_vertical_line({int(date_left_x), 1}, int(bottom - 1), false)

		set_fg_color(_current_theme.column_header.fg)
		write("Date", {date_left_x + 13, 1})
		if panel.sort_column == .date {
			set_fg_color(_current_theme.sort_indicator.fg)
			write(sort_char, {date_left_x + 17, 1})
		}

		set_color_pair(_current_theme.main)
		write("╤", {date_left_x, 0})
		write("┴", {date_left_x, bottom})
	}

	//size column and lines
	if draw_size {
		current_rightmost_border = current_rightmost_border - 10
		size_left_x = current_rightmost_border

		set_colors(_current_theme.main.fg, panel_inner_bg)
		draw_vertical_line({int(size_left_x), 1}, int(bottom - 1), false)

		set_fg_color(_current_theme.column_header.fg)
		write("Size", {size_left_x + 4, 1})
		if panel.sort_column == .size {
			set_fg_color(_current_theme.sort_indicator.fg)
			write(sort_char, {size_left_x + 8, 1})
		}

		set_color_pair(_current_theme.main)
		write("╤", {size_left_x, 0})
		write("┴", {size_left_x, bottom})
	}

	//name column
	set_bg_color(panel_inner_bg)
	set_fg_color(_current_theme.column_header.fg)
	write("Name", {name_left_x, 1})
	if panel.sort_column == .name {
		set_fg_color(_current_theme.sort_indicator.fg)
		write(sort_char, {left + 6, 1})
	}

	//current directory label
	set_colors(_current_theme.directory_text.fg, _current_theme.main.bg)
	write_cropped(panel.current_dir, {left + 2, 0}, right - 1, true)

	//all other files
	if len(panel.files) > 0 {
		last_file_index := len(panel.files) - 1
		max_visible_files := int(bottom) - 4
		if last_file_index - panel.first_file_index + 1 > max_visible_files {
			last_file_index = panel.first_file_index + max_visible_files - 1
		}

		current_row := 2
		for file_index in panel.first_file_index ..= last_file_index {
			is_focused := current_row - 2 == panel.focused_row_index && _focused_panel == panel
			if (is_focused) {
				set_bg_color(_current_theme.focused_file_row.bg)
			} else {
				set_bg_color(panel_inner_bg)
			}

			info := panel.files[file_index]

			if is_focused {
				paint_rectangle(
					{int(left) + 1, current_row, int(current_rightmost_border - left) - 1, 1},
					_current_theme.focused_file_row.bg,
					true,
				)
			}

			if info.is_dir {
				set_fg_color(_current_theme.main.fg)
				write("[", {left + 2, uint(current_row)})
				set_fg_color(_current_theme.file_directory.fg)
				write(fmt.tprint(info.name), {left + 3, uint(current_row)})
				set_fg_color(_current_theme.main.fg)
				write("]", {left + 3 + len(info.name), uint(current_row)})
			} else {
				set_fg_color(_current_theme.file_normal.fg)
				write(fmt.tprint(info.name), {left + 2, uint(current_row)})
			}
			current_row += 1
		}
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
draw_horizontal_line :: proc(point: [2]int, length: int, double_border := false) {
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
draw_vertical_line :: proc(point: [2]int, length: int, double_border := false) {
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

draw_rectangle :: proc(rect: Rectangle, double_border := false) {
	right := rect.x + rect.w - 1
	bottom := rect.y + rect.h - 1

	write(double_border ? "╔" : "┌", {uint(rect.x), uint(rect.y)})
	write(double_border ? "╗" : "┐", {uint(right), uint(rect.y)})
	write(double_border ? "╚" : "└", {uint(rect.x), uint(bottom)})
	write(double_border ? "╝" : "┘", {uint(right), uint(bottom)})

	draw_horizontal_line({rect.x + 1, rect.y}, rect.w - 2, double_border)
	draw_horizontal_line({rect.x + 1, bottom}, rect.w - 2, double_border)
	draw_vertical_line({rect.x, rect.y + 1}, rect.h - 2, double_border)
	draw_vertical_line({right, rect.y + 1}, rect.h - 2, double_border)

}

paint_rectangle :: proc(rect: Rectangle, color: t.Any_Color, temp_color: bool = true) {
	right := rect.x + rect.w - 1
	bottom := rect.y + rect.h - 1

	old_background := _last_background
	set_colors(nil, color)

	for x: int = rect.x; x <= right; x += 1 {
		for y: int = rect.y; y <= bottom; y += 1 {
			write(" ", {uint(x), uint(y)})
		}
	}

	if temp_color {
		set_colors(nil, old_background)
	}
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
write :: proc(text: string, location: [2]uint) {
	if location.y >= _screen.size.h || location.x >= _screen.size.w {
		return
	}

	move_cursor(location.x, location.y)
	t.write(&_screen, text)
}
/*
Writes string to screen, cropping it at screen width, or at custom 'max_width'
*/
write_cropped :: proc(
	text: string,
	location: [2]uint,
	max_width: uint = 0,
	align_right: bool = false,
) {
	crop_at_column: uint = _screen.size.w

	if max_width > 0 && max_width < _screen.size.w && location.x <= max_width {
		crop_at_column = max_width
	}

	space_available := crop_at_column - location.x

	move_cursor(location.x, location.y)
	if len(text) > int(space_available) {

		slice: string
		if align_right {
			slice = fmt.tprint(text[uint(len(text)) - space_available:])
		} else {
			slice = fmt.tprint(text[:space_available])
		}
		write(slice, location)

	} else {
		write(text, location)
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

set_color_pair :: proc(pair: RgbPair) {
	set_colors(pair.use_fg ? pair.fg : nil, pair.use_bg ? pair.bg : nil)
}

set_fg_color :: proc(color: [3]u8) {
	set_colors(color, nil)
}

set_bg_color :: proc(color: [3]u8) {
	set_colors(nil, color)
}

/*
	Moves cursor to specified location
*/
move_cursor :: proc(x, y: uint) {
	t.move_cursor(&_screen, y, x)
}

