package sfc

import "core:fmt"
import "core:os"

FilePanel :: struct {
	current_dir:      string,
	files:            [dynamic]os.File_Info,
	first_file_index: int,
	last_error:       string,
}

/*
	Reloads files in current directory of specified panel
*/
reload_file_panel :: proc(panel: ^FilePanel) {

	handle, error := os.open(".", os.O_RDONLY, 0)

	if error != nil {
		set_panel_error(panel, error)
		defer os.close(handle)
	}

	fi, err := os.read_dir(handle, 1024, context.temp_allocator)
	if err != 0 {
		set_panel_error(panel, err)
	}

	defer delete(fi)

	clear(&panel.files)

	for f in fi {
		append(&panel.files, f)
	}
}

/*
	Sets panel error text
*/
set_panel_error :: proc(panel: ^FilePanel, error: os.Error) {
	delete(panel.last_error)
	panel.last_error = fmt.tprintf("%v", error)
}

