package sfc

import t "../lib/TermCL"

Widget :: struct {
	title:        string,
	border_style: BorderStyle,
	location:     WidgetLocation,
	data:         WidgetData,
}

/*
	Enumerates possible locations for dialogs
*/
WidgetLocation :: union {
	WidgetLocation_FullScreen, //dialog will be displayed accross almost full screen
	WidgetLocation_Center, //dialog will be in center of screen as small as reasonably possible
	WidgetLocation_BottomLine, //dialog will be drawn at the bottom line of the scrreen
}

WidgetLocation_FullScreen :: struct {}

WidgetLocation_Center :: struct {
	height: uint, //required height for content (if possible)
}

WidgetLocation_BottomLine :: struct {}

BorderStyle :: enum {
	none,
	single,
	double,
}

/*
	Union which enumerates all widget types and serves as unified data storage
*/
WidgetData :: union {
	MessageBoxData,
	CommandBarData,
}

handle_widget_input :: proc(widget: ^Widget, input: t.Input) {

}

destroy_current_dialog :: proc() {
	if len(_current_dialog.title) > 0 do delete(_current_dialog.title)

	switch w in _current_dialog.data {
	case MessageBoxData:
		if len(w.text) > 0 do delete(w.text)
	case CommandBarData:
	}

	_current_dialog = {}
}

