package errors

import "core:fmt"

/*
	Contains both error enum and message
	(This is not a classic exception. It's just a name which helps me know what it is at a glance)
*/
SfcException :: struct {
	error:   SfcError,
	message: string,
}

SfcError :: union {
	FileSystemError,
}

FileSystemError :: enum {
	does_not_exist,
	not_a_file,
}

exception_from_error :: proc(error: SfcError, parameter: string) -> SfcException {
	assert(error != nil)

	msg: string

	switch e in error {
	case FileSystemError:
		return get_error_description_for_FileSystemError(e, parameter)
	}

	panic("This should not be reached")
}

get_error_description_for_FileSystemError :: proc(
	error: FileSystemError,
	parameter: string,
	allocator := context.allocator,
) -> SfcException {

	ret: SfcException
	ret.error = error

	switch error {
	case .does_not_exist:
		ret.message = fmt.aprintf("'%v' does not exist.", parameter, allocator = allocator)
	case .not_a_file:
		ret.message = fmt.aprintf("'%v' is not a file", parameter, allocator = allocator)
	}

	return ret
}

