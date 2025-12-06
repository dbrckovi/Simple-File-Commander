package errors

import "core:fmt"
import "core:strings"

/*
	Contains both error enum and message
	(This is not a classic exception. It's just a name which helps me know what it is at a glance)

	TODO: Re-evaluate this after some time
*/
SfcException :: struct {
	error:   SfcError,
	message: string,
}

/*
	Union of error enums
*/
SfcError :: union {
	FileSystemError,
	GeneralError,
}

/*
	Enum of file system errors
*/
FileSystemError :: enum {
	does_not_exist,
	not_a_file,
	not_a_directory,
	destination_same_as_source,
	overwrite_not_requrested, //when file would be overwritten but overwrite flag is not set
	os_error,
}

GeneralError :: enum {
	undefined,
	thread_not_created,
}

create_exception :: proc(
	error: SfcError,
	message: string,
	allocator := context.allocator,
) -> SfcException {
	return SfcException{error = error, message = strings.clone(message, allocator)}
}

