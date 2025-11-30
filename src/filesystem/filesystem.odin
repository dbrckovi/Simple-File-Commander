package filesystem

import err "../errors"

/*
	"Low level" procedures for file operations.
	They're "low level" in a sense that they are not aware of applicaiton context.
	They just do what they're told and don't depend on active panel, command, shortcut or anything else.
*/

import "core:os"

copy_file_to_directory :: proc(
	src_file, dest_dir: string,
	overwrite := false,
) -> err.FileSystemError {

	assert(len(src_file) > 0)
	assert(len(dest_dir) > 0)

	if !os.exists(src_file) {
		return .does_not_exist
	}

	if !os.is_file(src_file, false) {
		return .not_a_file
	}

	//TODO: continue here

	return nil
}

/*
	Gets an array of os.File_Info objects in specified directory.
*/
get_files_in_directory :: proc(
	path: string,
	allocator := context.allocator,
) -> (
	fi: []os.File_Info,
	err: os.Error,
) {
	assert(len(path) > 0)

	handle, error := os.open(path, os.O_RDONLY, 0)
	defer os.close(handle)

	if error != nil {
		return nil, error
	}

	return os.read_dir(handle, 1024, allocator)
}

