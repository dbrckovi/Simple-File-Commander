package sfc

import "core:strings"

/*
	Panel with title in the upper left corner and border
*/
BoxWithTitle :: struct {
	title:     string,
	border:    BorderStyle,
	rectangle: Rectangle,
}

/*
	Changes title of existing BoxWithTitle, deleting the old value
*/
change_box_with_title_title :: proc(box: ^BoxWithTitle, new_title: string) {
	if len(box.title) > 0 do delete(box.title)
	box.title = strings.clone(new_title)
}

draw_box_with_title :: proc(panel: ^BoxWithTitle) {

	paint_rectangle(panel.rectangle, _current_theme.dialog_main.bg)

	if panel.border != .none {
		set_color_pair(_current_theme.dialog_main)
		draw_rectangle(panel.rectangle, panel.border == .double)
	}

	if len(panel.title) > 0 {
		set_color_pair(_current_theme.dialog_title)
		write(panel.title, {uint(panel.rectangle.x + 2), uint(panel.rectangle.y)})
	}
}

draw_key_with_function :: proc(
	location: [2]uint,
	key: string,
	function: string,
	function_distance: uint,
) {
	set_color_pair(_current_theme.dialog_key)
	write(key, location)

	set_color_pair(_current_theme.dialog_main)
	write(function, {location.x + function_distance, location.y})
}

draw_label_with_value :: proc(
	location: [2]uint,
	label: string,
	value: string,
	value_distance: uint,
) {
	set_color_pair(_current_theme.dialog_main)
	write(label, location)

	set_color_pair(_current_theme.dialog_value)
	write(value, {location.x + value_distance, location.y})
}

/*
	Horizontal progress bar
	@param location: leftmost coordinate
	@param width: width of the progress bar
	@param progress_value: normalized value of the progress bar (clipped to 0-1)
*/
draw_progress_bar_h :: proc(location: [2]uint, width: uint, progress_value: f32) {
	value := progress_value
	if value < 0 do value = 0
	else if value > 1 do value = 1

	abs_value := uint(f32(width) * value)

	if abs_value > 0 {
		rect: Rectangle = {int(location.x), int(location.y), int(abs_value), 1}
		paint_rectangle(rect, _current_theme.dialog_progress.fg)
	}
	if abs_value < width {
		rect: Rectangle = {int(location.x + abs_value), int(location.y), int(width - abs_value), 1}
		paint_rectangle(rect, _current_theme.dialog_progress.bg)
	}
}

/*
	Vertical progress bar
	@param location: topmost coordinate
	@param height: height of the progress bar
	@param progress_value: normalized value of the progress bar (clipped to 0-1)
*/
draw_progress_bar_v :: proc(location: [2]uint, height: uint, progress_value: f32) {
	value := progress_value
	if value < 0 do value = 0
	else if value > 1 do value = 1

	abs_value := uint(f32(height) * value)

	if abs_value < height {
		rect: Rectangle = {int(location.x), int(location.y), 1, int(height - abs_value)}
		paint_rectangle(rect, _current_theme.dialog_progress.bg)
	}
	if abs_value > 0 {
		rect: Rectangle = {
			int(location.x),
			int(location.y + height - abs_value),
			1,
			int(abs_value),
		}
		paint_rectangle(rect, _current_theme.dialog_progress.fg)
	}
}

