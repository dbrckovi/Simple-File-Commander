package sfc

import "core:fmt"
import "core:os"

FilePanel :: struct {
	current_dir:      string,
	files:            [dynamic]os.File_Info,
	first_file_index: int,
	sort_column:      SortColumn,
	sort_direction:   SortDirection,
}

SortColumn :: enum {
	name,
	size,
	date,
}

SortDirection :: enum {
	ascending,
	descending,
}

/*
	Reloads files in current directory of specified panel
*/
reload_file_panel :: proc(panel: ^FilePanel) {

	handle, error := os.open(".", os.O_RDONLY, 0)

	if error != nil {
		_last_error = error
		defer os.close(handle)
	}

	fi, err := os.read_dir(handle, 1024, context.temp_allocator)
	if err != 0 {
		_last_error = err
	}

	defer delete(fi)

	clear(&panel.files)

	for f in fi {
		append(&panel.files, f)
	}

}

