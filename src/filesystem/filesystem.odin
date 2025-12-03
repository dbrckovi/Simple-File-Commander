package filesystem

import err "../errors"
import "core:fmt"
import filepath "core:path/filepath"
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

	// dest_file_builder := strings.builder_make(context.temp_allocator)
	// strings.write_string(&dest_file_builder, dest_dir)
	// if !strings.ends_with(dest_dir, "/") {
	// 	strings.write_string(&dest_file_builder, "/")
	// }
	// strings.write_string(&dest_file_builder, src_file.name)

	dest_file := filepath.join({dest_dir, src_file.name}, context.temp_allocator)

	return copy_file_raw(src_file.fullpath, dest_file, overwrite = true)
}

/*
Copies a single file to destination
*/
@(private)
copy_file_raw :: proc(src_file, dest_file: string, overwrite := false) -> err.SfcException {

	if strings.equal_fold(src_file, dest_file) {
		return err.create_exception(
			.destination_same_as_source,
			fmt.tprint("Destination path is the same as the source:", dest_file),
			context.temp_allocator,
		)
	}

	if !overwrite && os.exists(dest_file) {
		return err.create_exception(
			.overwrite_not_requrested,
			fmt.tprint(
				"Target of 'copy' operation already exists, but 'overwrite' flag is not set:",
				dest_file,
			),
			context.temp_allocator,
		)
	}

	src_info, stat_err := os.stat(src_file)
	if stat_err != nil {
		return err.create_exception(
			.os_error,
			fmt.tprint("Error getting file info for", src_file, ":", stat_err),
			context.temp_allocator,
		)
	}

	data, read_error := os.read_entire_file_from_filename_or_err(src_file)
	if read_error != nil {
		return err.create_exception(
			.os_error,
			fmt.tprint("Error reading", src_file, "during copy operation:", read_error),
			context.temp_allocator,
		)
	}
	defer delete(data)

	write_error := write_entire_file_or_err(dest_file, src_info.mode, data, true)

	if write_error != nil {
		return err.create_exception(
			.os_error,
			fmt.tprint("Error writing", dest_file, "during copy operation", write_error),
			context.temp_allocator,
		)
	}

	return {}
}

/*
	Copied from core:os because built-in proc doesn't accept file_atrributes and there is no obvious way to change them afterwards
*/
@(private)
@(require_results)
write_entire_file_or_err :: proc(
	name: string,
	file_mode: os.File_Mode,
	data: []byte,
	truncate := true,
) -> os.Error {
	flags: int = os.O_WRONLY | os.O_CREATE
	if truncate {
		flags |= os.O_TRUNC
	}

	mode: int = int(file_mode & 0o7777)
	fd := os.open(name, flags, mode) or_return
	defer os.close(fd)

	for n := 0; n < len(data); {
		n += os.write(fd, data[n:]) or_return
	}
	return nil
}

/*
	Deletes current specified file
*/
delete_file :: proc(file: os.File_Info) -> err.SfcException {

	if !os.exists(file.fullpath) {
		return err.create_exception(
			.does_not_exist,
			fmt.tprintf(" '%v' does not exist", file.fullpath),
		)
	}

	if !os.is_file(file.fullpath) {
		return err.create_exception(
			.not_a_file,
			fmt.tprintf(" '%v' is not a directory", file.fullpath),
		)
	}

	delete_error := os.remove(file.fullpath)
	if delete_error != nil {
		return err.create_exception(
			.os_error,
			fmt.tprint("Error deleting", file.fullpath, delete_error),
			context.temp_allocator,
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

