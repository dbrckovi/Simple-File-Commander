package sfc

import t "../lib/TermCL"
import tb "../lib/TermCL/term"
import "core:fmt"
import "core:os"
import "core:strings"

SORT_ASCENDING_CHAR := "↓"
SORT_DESCENDING_CHAR := "↑"

COL_DATE_LENGTH :: 19
COL_SIZE_LENGTH :: 10

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

	main_splitter_x := get_main_splitter_x()

	set_color_pair(_current_theme.main)

	//main border
	draw_rectangle({0, 0, int(_screen.size.w), int(_screen.size.h)}, true)

	//center
	draw_vertical_line({int(main_splitter_x), 1}, int(_screen.size.h - 2), true)
	write("╦", {main_splitter_x, 0})
	write("╩", {main_splitter_x, _screen.size.h - 1})

	//panel bottom
	panel_bottom_x := _screen.size.h - 3
	set_color_pair(_current_theme.main)
	draw_horizontal_line({1, int(panel_bottom_x)}, int(_screen.size.w) - 2, false)
	write("╟", {0, panel_bottom_x})
	write("╫", {main_splitter_x, panel_bottom_x})
	write("╢", {_screen.size.w - 1, panel_bottom_x})

	draw_panel(&_left_panel, 0, main_splitter_x, panel_bottom_x)
	draw_panel(&_right_panel, main_splitter_x, _screen.size.w - 1, panel_bottom_x)

	if _current_dialog != nil {
		draw_widget(&_current_dialog)
	}
}

/*
	Draws layout of a single panel
	left - x coordinate of the left border
	right - x coordinate of the right border
	bottom - y coordinate of the bottom single line
*/
draw_panel :: proc(panel: ^FilePanel, left: uint, right: uint, bottom: uint) {

	//TODO: Rethink color handling. This is too convoluted

	leftmost_dynamic_colunn_x: uint = left + _settings.name_column_min_size + 1
	panel_width := right - left

	date_drawn: bool // was date colunn drawn
	size_drawn: bool // was size colunn drawn
	attr_drawn: bool // was attrivutes column drawn
	name_drawn: bool // was name column drawn (can become false if screen is too small)

	date_left_border_x: uint // left border of date column (if drawn)
	size_left_border_x: uint // left border of size column (if drawn)
	attr_left_border_x: uint // left border of attributes colun (if drawn)

	current_rightmost_border := right
	name_label_left_x: uint = left + 2 //x coordinate for name column text and file names
	sort_char := panel.sort_direction == .ascending ? SORT_ASCENDING_CHAR : SORT_DESCENDING_CHAR
	panel_inner_bg :=
		_focused_panel == panel ? _current_theme.focused_panel.bg : _current_theme.main.bg

	//background
	paint_rectangle({int(left + 1), 1, int(right - left - 1), int(bottom - 1)}, panel_inner_bg)

	//focused line
	if _focused_panel == panel && len(panel.files) > 0 {
		paint_rectangle(
			{int(left) + 1, panel.focused_row_index + 2, int(right) - 1, 1},
			_current_theme.focused_file_row.bg,
			true,
		)
	}


	//dynamic columns
	#reverse for col in _settings.columns {
		//TODO: read comment below and find out
		drawn: bool // declaring here, because I'm not sure what odin will do if I use := with mixed variables (one exists, other doesn't)

		current_rightmost_border, drawn = try_draw_dynamic_column_borders(
			panel,
			col,
			current_rightmost_border,
			panel_inner_bg,
			bottom,
			leftmost_dynamic_colunn_x,
		)

		if drawn {
			#partial switch col {
			case .date:
				date_drawn = drawn
				date_left_border_x = current_rightmost_border
			case .size:
				size_drawn = drawn
				size_left_border_x = current_rightmost_border
			case .attributes:
				attr_drawn = drawn
				attr_left_border_x = current_rightmost_border
			}
		}
	}

	//name column
	if current_rightmost_border - left > 6 {
		set_colors(_current_theme.column_header.fg, panel_inner_bg)
		write("Name", {name_label_left_x, 1})
		if panel.sort_column == .name {
			set_fg_color(_current_theme.sort_indicator.fg)
			write(sort_char, {left + 6, 1})
		}
		name_drawn = true
	} else {
		name_drawn = false
	}

	//panel title (current directory label)
	set_colors(_current_theme.panel_title.fg, _current_theme.main.bg)
	write_cropped(panel.current_dir, {left + 2, 0}, right - 1, true)

	//files
	if len(panel.files) > 0 {
		last_file_index := len(panel.files) - 1
		max_visible_files := get_max_visible_files()
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

			file := &panel.files[file_index]

			if is_focused {
				paint_rectangle(
					{int(left) + 1, current_row, int(current_rightmost_border - left) - 1, 1},
					_current_theme.focused_file_row.bg,
					true,
				)
			}

			//Name
			if file.file.is_dir {
				//directory
				set_fg_color(_current_theme.main.fg)
				write("[", {left + 2, uint(current_row)})
				dir_right_x := min(current_rightmost_border, left + 3 + len(file.file.name))
				write("]", {dir_right_x, uint(current_row)})

				if file.selected {
					set_fg_color(_current_theme.directory_selected.fg)
				} else {
					if strings.starts_with(file.file.name, ".") {
						set_fg_color(_current_theme.directory_hidden.fg)
					} else {
						set_fg_color(_current_theme.directory_normal.fg)
					}
				}

				write_cropped(
					fmt.tprint(file.file.name),
					{left + 3, uint(current_row)},
					current_rightmost_border,
					true,
				)
			} else {
				//file
				hidden := is_hidden(file)
				executable := is_executable(file)
				link := is_link(file)

				set_fg_color(_current_theme.main.fg)
				if link {
					write(fmt.tprint(_settings.icon_link_to_file), {left + 1, uint(current_row)})
				}

				if file.selected {
					set_fg_color(_current_theme.file_selected.fg)
				} else {
					if hidden && executable && !link {
						set_fg_color(_current_theme.file_hidden_executable.fg)
					} else if hidden {
						set_fg_color(_current_theme.file_hidden.fg)
					} else if executable && !link {
						set_fg_color(_current_theme.file_executable.fg)
					} else {
						set_fg_color(_current_theme.file_normal.fg)
					}
				}

				write_cropped(
					fmt.tprint(file.file.name),
					{left + 2, uint(current_row)},
					current_rightmost_border,
					true,
				)

				if executable && !link {
					write(fmt.tprint(_settings.icon_executable), {left + 1, uint(current_row)})
				}
			}

			//Size
			if size_drawn {
				size_text := get_bytes_with_units(file.file.size)
				size_text_x := size_left_border_x + COL_SIZE_LENGTH - len(size_text) - 1
				write(size_text, {size_text_x, uint(current_row)})
			}

			//Attr
			if attr_drawn {
				attr_text := get_file_permissions_string(file.file)
				attr_text_x := attr_left_border_x + 2
				draw_attributes(attr_text, {attr_text_x, uint(current_row)}, !file.selected)
			}

			//Date
			if date_drawn {
				date_text := get_file_date_string(file.file)
				date_text_x := date_left_border_x + COL_DATE_LENGTH - len(date_text) - 1
				write(date_text, {date_text_x, uint(current_row)})
			}

			current_row += 1
		}
	}

	//panel summary line
	summary_y := bottom + 1
	selected_file_count: uint
	file_count := len(panel.files) - 1
	for file in panel.files {
		if file.selected {
			selected_file_count += 1
		}
	}

	// msg := fmt.tprintf("%2b", get_focused_file_info().file.mode)
	// indexes := "098765432109876543210"
	// write_cropped(indexes, {left + 25 - len(indexes), summary_y - 1}, right, true)
	// write_cropped(msg, {left + 25 - len(msg), summary_y}, right, true)

	msg := fmt.tprintf(
		"Files: %d, Selected: %d, ATTR: %v",
		file_count,
		selected_file_count,
		_settings.attribute_format,
	)
	set_color_pair(_current_theme.main)
	write_cropped(msg, {left + 2, summary_y}, right, true)
}

draw_attributes :: proc(attr_text: string, location: [2]uint, paint_sets: bool) {
	old_fg := _last_foreground

	if paint_sets && len(attr_text) == 9 {
		set_color_pair(_current_theme.attribute_owner)
		write(attr_text[:3], location)

		set_color_pair(_current_theme.attribute_group)
		write(attr_text[3:6], {location.x + 3, location.y})

		set_color_pair(_current_theme.attribute_other)
		write(attr_text[6:], {location.x + 6, location.y})
	} else if paint_sets && len(attr_text) == 3 {
		set_color_pair(_current_theme.attribute_owner)
		write(attr_text[:1], location)

		set_color_pair(_current_theme.attribute_group)
		write(attr_text[1:2], {location.x + 1, location.y})

		set_color_pair(_current_theme.attribute_other)
		write(attr_text[2:3], {location.x + 2, location.y})
	} else {
		write(attr_text, location)
	}

	set_colors(old_fg, nil)
}

get_attribute_column_width :: proc() -> uint {
	return _settings.attribute_format == .symbolic ? 12 : 7
}

/*
	If there is enough space, draws column name, sort indicator and border.

	@param panel - pointer to file panel on which the column is being drawn
	@param column - column which is being drawn
	@param right_border_x - current right border, left of which the column will be drawn
	@param background_color - background color used for elements
	@param bottom_y - y coordinate of the bottom line up to which files are drawn
	@param min_left_border_x: min 'x' coordinate. Everything left of that is reserved for the 'Name' column
	@returns the x coordinate of it's left border, and bool value indicating if column was drawn

	@remarks If there is not enough space, returns the original value of right_border_x
*/
try_draw_dynamic_column_borders :: proc(
	panel: ^FilePanel,
	column: FilePanelColumn,
	right_border_x: uint,
	background_color: [3]u8,
	bottom_y: uint,
	min_left_border_x: uint,
) -> (
	uint,
	bool,
) {
	left_border: int = int(right_border_x)
	title: string
	sort_char := panel.sort_direction == .ascending ? SORT_ASCENDING_CHAR : SORT_DESCENDING_CHAR

	switch column {
	case .date:
		title = "Date"
		left_border = int(right_border_x) - COL_DATE_LENGTH
	case .size:
		title = "Size"
		left_border = int(right_border_x) - COL_SIZE_LENGTH
	case .attributes:
		title = "Att"
		left_border = int(right_border_x) - int(get_attribute_column_width())
	case .name:
		panic("Procedure is not intended for drawing 'Name' column")
	}

	if left_border < int(min_left_border_x) {
		return right_border_x, false
	}

	set_colors(_current_theme.main.fg, background_color)
	draw_vertical_line({int(left_border), 1}, int(bottom_y - 1), false)

	set_fg_color(_current_theme.column_header.fg)
	write(title, {right_border_x - len(title) - 2, 1})
	if panel.sort_column == column {
		set_fg_color(_current_theme.sort_indicator.fg)
		write(sort_char, {right_border_x - 2, 1})
	}

	set_color_pair(_current_theme.main)
	write("╤", {uint(left_border), 0})
	write("┴", {uint(left_border), bottom_y})

	return uint(left_border), true
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

/*
	Draws a rectangle
*/
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

/*
	Sets background color to specified rectangular region
	- rect: region
	- color: color to use as background
	- temp_color: if true, reverts _last_background to previous value after painting
*/
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

write :: proc {
	write_string,
	write_rune,
}

write_string :: proc(text: string, location: [2]uint) {
	if location.y >= _screen.size.h || location.x >= _screen.size.w {
		return
	}

	move_cursor(location.x, location.y)
	t.write(&_screen, text)
}

write_rune :: proc(char: rune, location: [2]uint) {
	if location.y >= _screen.size.h || location.x >= _screen.size.w {
		return
	}

	move_cursor(location.x, location.y)
	t.write(&_screen, char)
}


/*
Writes string to screen, cropping it at screen width, or at custom 'max_width'
*/
write_cropped :: proc(
	text: string,
	location: [2]uint,
	max_width: uint = 0, //TODO: This is named poorly
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

get_max_visible_files :: proc() -> int {
	return int(_screen.size.h - 5)
}

get_main_splitter_x :: proc() -> uint {
	return uint(f32(_screen.size.w) * _splitter_fraction)
}


/*
	Draws specified widget to the screen
*/
draw_widget :: proc(widget: ^Widget) {
	// content_rect := draw_widget_background(widget.location, widget.border_style, widget.title)

	switch &w in widget {
	case CommandBar:
		draw_command_bar(&w)
	case MessageBox:
		draw_messagebox(&w)
	case TextViewer:
		draw_text_viewer(&w)
	case FileCopyBox:
		draw_file_copy_box(&w)
	}
}

/*
	Draws widget background, border and title
	@param location: location of the background
	@param border: defines border style for widges types that can have borders
	@param title: widget title, only for widget types that can have title
	@returns Rectangle for widget content
*/
draw_widget_background :: proc(
	location: WidgetLocation,
	border: BorderStyle,
	title: string,
) -> Rectangle {

	background_rect: Rectangle = {}
	effective_border := border
	effective_title: string = len(title) != 0 ? strings.clone(title, context.temp_allocator) : {}
	content_rect: Rectangle = {}

	switch location {

	case .middle:
		screen_center_x := _screen.size.w / 2
		screen_center_y := _screen.size.h / 2
		// background_rect.h = int(loc.height)
		if effective_border != .none {
			background_rect.h += 2
		}
		background_rect.w = int(_screen.size.w) - 4
		background_rect.x = int(screen_center_x) - background_rect.w / 2
		background_rect.y = int(screen_center_y) - background_rect.h / 2
		if background_rect.h > int(_screen.size.h) {
			background_rect.y = 0
			background_rect.h = int(_screen.size.h)
		}

	case .bottom_line:
		effective_border = .none
		effective_title = {}
		background_rect.x = 0
		background_rect.y = int(_screen.size.h) - 1
		background_rect.w = int(_screen.size.w)
		background_rect.h = 1

	case .full_screen:
		background_rect.x = 2
		background_rect.y = 1
		background_rect.w = int(_screen.size.w) - 4
		background_rect.h = int(_screen.size.h) - 2

	}

	border_size := effective_border == .none ? 0 : 1
	content_rect.x = background_rect.x + border_size
	content_rect.y = background_rect.y + border_size
	content_rect.w = background_rect.w - border_size * 2
	content_rect.h = background_rect.h - border_size * 2

	if content_rect.w < 1 || content_rect.h < 1 {
		return {}
	}

	paint_rectangle(background_rect, _current_theme.dialog_main.bg)

	if effective_border != .none {
		set_color_pair(_current_theme.dialog_main)
		draw_rectangle(background_rect, effective_border == .double)
	}

	if len(effective_title) > 0 {
		set_color_pair(_current_theme.dialog_title)
		write(effective_title, {uint(background_rect.x + 2), uint(background_rect.y)})
	}

	return content_rect
}

