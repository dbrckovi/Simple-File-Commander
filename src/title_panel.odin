package sfc

/*
	Panel with title in the upper left corner and border
*/
TitlePanel :: struct {
	title:     string,
	border:    BorderStyle,
	rectangle: Rectangle,
}

draw_title_panel :: proc(panel: ^TitlePanel) {

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

