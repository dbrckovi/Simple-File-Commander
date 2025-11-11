package sfc

/*
	Holds info for drawing dialog background, border and title
*/
Dialog_Panel :: struct {
	location: Dialog_Location,
	title:    string,
}

/*
	Enumerates possible locations for dialogs
*/
Dialog_Location :: enum {
	full_screen, //dialog will be displayed accross almost full screen
	center, //dialog will be in center of screen as small as reasonably possible
	bottom_line, //dialog will be drawn at the bottom line of the scrreen
}

/*
	Union of all dialog types
*/
Dialog_Type :: union {
	File_Copy_Dialog,
}

/*
	Holds all data required for copying files
*/
File_Copy_Dialog :: struct {
	panel: Dialog_Panel,
	//TODO: source files, destination directory
}

