package sfc

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:sort"
import "core:strings"

FilePanel :: struct {
	current_dir:       string,
	files:             [dynamic]os.File_Info,
	first_file_index:  int,
	sort_column:       SortColumn,
	sort_direction:    SortDirection,
	focused_row_index: int, //focused row counting from line below column header (first visible file is 0)
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

	handle, error := os.open(panel.current_dir, os.O_RDONLY, 0)

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

	parent_dir_info: os.File_Info = {
		fullpath = filepath.dir(panel.current_dir, context.allocator),
		name     = strings.clone("..", context.allocator),
		size     = 0,
		mode     = os.File_Mode_Dir,
		is_dir   = true,
	}
	append(&panel.files, parent_dir_info)

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

	sort_files(panel)
}


/*
	Changes current directory of specified panel one level up
*/
cd_up :: proc(panel: ^FilePanel) -> bool {
	parent_dir := filepath.dir(panel.current_dir, context.allocator)

	error := cd(panel, parent_dir)

	if error != os.General_Error.None {
		return false
	}

	return true
}

/*
	Changes current directory of specified panel to what ever was passed in
*/
cd :: proc(panel: ^FilePanel, directory: string) -> os.Error {
	if !os.exists(directory) {
		return os.General_Error.Not_Exist
	}

	if !os.is_dir(directory) {
		return os.General_Error.Not_Dir
	}

	delete(panel.current_dir)
	panel.current_dir = directory
	reload_file_panel(panel)

	return os.General_Error.None
}


sort_files :: proc(panel: ^FilePanel) {
	// TODO: Implement sort
	// AI suggests this:
	/*
		import "core:sort"

		SortContext :: struct {
		    sort_column: SortColumn,
		    sort_direction: SortDirection,
		}

		compare_proc :: proc(a, b: os.File_Info, ctx: rawptr) -> int {
		    context.user_ptr = ctx
		    sc := cast(^SortContext)ctx
		    if a.is_dir != b.is_dir {
		        return sc.sort_direction == .Ascending ? (a.is_dir && !b.is_dir ? -1 : 1) : (a.is_dir && !b.is_dir ? 1 : -1)
		    }
		    switch sc.sort_column {
		    case .Name:
		        return sc.sort_direction == .Ascending ? cmp(a.name, b.name) : cmp(b.name, a.name)
		    case .Size:
		        return sc.sort_direction == .Ascending ? cmp(a.size, b.size) : cmp(b.size, a.size)
		    }
		    return 0
		}

		cmp :: proc(a, b: $T) -> int where intrinsics.type_is_ordered(T) {
		    return a < b ? -1 : (a > b ? 1 : 0)
		}

		sort_files :: proc(panel: ^FilePanel) {
		    ctx := SortContext{panel.sort_column, panel.sort_direction}
		    sort.quick_sort_proc_context(panel.files[:], compare_proc, &ctx)
		}
	*/
}

