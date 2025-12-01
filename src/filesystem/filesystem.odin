package filesystem

import err "../errors"
import "core:fmt"
import "core:strings"

/*
	"Low level" procedures for file operations.
	They're "low level" in a sense that they are not aware of applicaiton context.
	They just do what they're told and don't depend on active panel, command, shortcut or anything else.
*/

import "core:os"

copy_file_to_directory :: proc(
	src_file, dest_dir: string,
	overwrite := false,
) -> err.SfcException {

	if len(src_file) == 0 {
		return err.create_exception(.undefined, "'src_file' is not defined")
	}

	if len(dest_dir) == 0 {
		return err.create_exception(.undefined, "'dest_dir' is not defined")
	}

	if !os.exists(src_file) {
		return err.create_exception(.does_not_exist, fmt.tprintf(" '%v' does not exist", src_file))
	}

	if !os.exists(dest_dir) {
		return err.create_exception(.does_not_exist, fmt.tprintf(" '%v' does not exist", dest_dir))
	}

	if !os.is_file(src_file, false) {
		return err.create_exception(.not_a_file, fmt.tprintf(" '%v' is not a file", src_file))
	}

	if !os.is_dir(dest_dir) {
		return err.create_exception(
			.not_a_directory,
			fmt.tprintf(" '%v' is not a directory", src_file),
		)
	}


	return {}
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

