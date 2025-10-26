package sfc

import "core:fmt"
import "core:os"
import "core:strings"

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
		//deep copy strngs because they are allocated internally by os.read_dir
		//originally I just replaced the strings in &f, but AI convinced me that creating a new 'file_info_copy' variable here is safer
		//TODO: ask somone on forums what is better and why
		//Reasoning: f was created by os.read_dir and it's strings are allocated on temp allocator
		//If I re-allocate the strings on f variable, I'm changing the memory that I don't "own" and that's dangerous (no concrete reason)
		//So creating a new variable which holds cloned strings is "better practice".
		file_info_copy := f
		file_info_copy.name = strings.clone(f.name, context.allocator)
		file_info_copy.fullpath = strings.clone(f.fullpath, context.allocator)
		append(&panel.files, file_info_copy)
	}

}

