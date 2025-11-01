package sfc

//TODO: move logic for parsing and executing ':' commands here

/*
	Performs the default action on currently focused file or directory.
	Action depends on the type of the item
*/
activate_focused_item :: proc() {

	file_info := get_focused_file_info()
	if file_info.is_dir {
		cd(_focused_panel, file_info.fullpath)
	}
}

