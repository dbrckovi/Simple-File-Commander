package sfc

import t "../lib/TermCL"

/*
NOTE: I have no idea what I'm doing with this hierarchy.
If you're reading this code somehow, don't use it as a reference for anything.
For now, it does what I need, but there are many problems:
- only one dialog at a time is possible
- dialog is a global variable. simplifies the procedures, but feels dirty
- hierarchy doesn't make it clear where stuff should be created, drawn, destroyed...
*/

/*
	"Base" struct for defining various GUI elements
	Represents a rectangle with optional title and borders.
	It's a background rectangle where all dynamic panels, popups and dialogs are drawn
*/
Widget :: struct {
	appearance: WidgetAppearance,
	procedures: WidgetProcedures,
	data:       WidgetData,
}

/*
	Defines appearance information that every widget must have
*/
WidgetAppearance :: struct {
	location:     WidgetLocation,
	border_style: BorderStyle,
	title:        string,
	main_color:   RgbPair, // fg and bg color. fg is used for borders and as default color if specific implementation doesn't override it
	title_color:  RgbPair, // fg and bg color for title.
}

/*
	Enumerates possible locations for dialogs
*/
WidgetLocation :: union {
	WidgetLocation_FullScreen, //dialog will be displayed accross almost full screen
	WidgetLocation_Center, //dialog will be in center of screen as small as reasonably possible
	WidgetLocation_BottomLine, //dialog will be drawn at the bottom line of the scrreen
}

WidgetLocation_FullScreen :: struct {
	border_offset: uint,
}

WidgetLocation_Center :: struct {
	height:            uint,
	actual_dimensions: Rectangle, //actual dimensions. Depends on screen size and height
}

WidgetLocation_BottomLine :: struct {
}

/*
	Holds pointers to procedures which define widget behaviour
*/
WidgetProcedures :: struct {
	handle_input: proc(input: t.Input), //handles keyboard or mouse input
	draw_content: proc(), //draws widget content (everything except border and title)
}

/*
	Enumerates border styles.
	Border is not drawn if widget's size is less than 3
*/
BorderStyle :: enum {
	none, //widget is drawn without a border
	single, //single line border
	double, //double line border
}

/*
	Union which enumerates all widget types and serves as unified data storage
*/
WidgetData :: union {
	MessageBoxData,
}

/*
	Deletes and deallocates memory that is allocated on the Widget level
*/
widget_destroy :: proc() {
	delete(_current_dialog.appearance.title)
}

/*
	Draws widget's background, border and title
	@param widget: widget whose border to draw
*/
widget_draw_background :: proc() -> bool {
	if _screen.size.w < 7 || _screen.size.h < 7 {
		return false
	}

	switch &loc in _current_dialog.appearance.location {
	case WidgetLocation_Center:
		draw_widget_background_center(&loc)
	case WidgetLocation_FullScreen:

	case WidgetLocation_BottomLine:
	}

	return true
}

draw_widget_background_center :: proc(location: ^WidgetLocation_Center) {
	//TODO: conplete rewrite
	rect: Rectangle = {
		x = 0,
		y = 0,
		w = int(_screen.size.w) - 8,
		h = int(location.height),
	}

	if _current_dialog.appearance.border_style != .none {
		rect.h += 2
	}

	if rect.h > int(_screen.size.h) {
		rect.h = int(_screen.size.h)
	}

	if rect.w < 7 {
		rect.w = int(_screen.size.w)
	}

	rect.x = (int(_screen.size.w) - rect.w) / 2
	rect.y = (int(_screen.size.h) - rect.h) / 2

	paint_rectangle(rect, _current_theme.dialog_main.bg)
	if _current_dialog.appearance.border_style != .none {
		set_color_pair(_current_theme.dialog_main)
		draw_rectangle(rect, _current_dialog.appearance.border_style == .double)
	}

	if _current_dialog.appearance.title != {} {
		write(_current_dialog.appearance.title, {uint(rect.x + 2), uint(rect.y)})
	}
}

