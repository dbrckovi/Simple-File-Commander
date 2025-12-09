package sfc

/*
	Panel with title in the upper left corner and border
*/
BoxWithTitle :: struct {
	title:     string,
	border:    BorderStyle,
	rectangle: Rectangle,
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

