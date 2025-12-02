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
	src_file: os.File_Info,
	dest_dir: string,
	overwrite := false,
) -> err.SfcException {

	if len(dest_dir) == 0 {
		return err.create_exception(
			.undefined,
			"'dest_dir' is not defined",
			context.temp_allocator,
		)
	}

	if !os.exists(dest_dir) {
		return err.create_exception(.does_not_exist, fmt.tprintf(" '%v' does not exist", dest_dir))
	}

	if !os.is_dir(dest_dir) {
		return err.create_exception(
			.not_a_directory,
			fmt.tprintf(" '%v' is not a directory", src_file),
		)
	}

	dest_file_builder := strings.builder_make(context.temp_allocator)
	//TODO: dest_file := filepath.join({dest_dir, src_file.name}, context.temp_allocator)
	strings.write_string(&dest_file_builder, dest_dir)
	if !strings.ends_with(dest_dir, "/") {
		strings.write_string(&dest_file_builder, "/")
	}
	strings.write_string(&dest_file_builder, src_file.name)

	return copy_file_to_file(src_file.fullpath, strings.to_string(dest_file_builder))
}

copy_file_to_file :: proc(src_file, dest_file: string, overwrite := false) -> err.SfcException {

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

