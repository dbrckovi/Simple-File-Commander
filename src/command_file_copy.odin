package sfc

import "core:fmt"
import "core:os"
import filepath "core:path/filepath"
import "core:sync"
import "core:thread"
import "core:time"
import "errors"
import "filesystem"

FileCopyToken :: struct {
	cancel_requested:  bool, //set to true when thread should stop
	thread:            ^thread.Thread,
	source_file_infos: [dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination_dir:   string, //destination directory. Set by caller thread
	overwrite_files:   Maybe(bool),
	progress:          ThreadProgress,
}

start_file_copy_thread :: proc(token: ^FileCopyToken) -> errors.SfcException {
	token.thread = thread.create(file_copy_work)

	if token.thread == nil {
		err := errors.create_exception(
			errors.GeneralError.thread_not_created,
			"File copy thread was not created",
			context.temp_allocator,
		)
		return err
	}

	token.thread.init_context = context
	token.thread.data = rawptr(token)
	thread.start(token.thread)
	return {}
}

/*
	Performs the file copy operation.
*/
file_copy_work :: proc(t: ^thread.Thread) {
	token := (^FileCopyToken)(t.data)


}

/*
	Sets 'cancel' signal to file copy thread, joins and destroys the thread
*/
stop_and_destroy_file_copy_thread :: proc(token: ^FileCopyToken) {
	sync.atomic_store(&token.cancel_requested, true)
	thread.join(token.thread)
	thread.destroy(token.thread)
}

threaded_copy_dir :: proc(
	token: ^FileCopyToken,
	src_dir: string,
	dest_dir: string,
) -> errors.SfcError {

	return {}
}

threaded_copy_file :: proc(
	token: ^FileCopyToken,
	src_file: os.File_Info,
	dest_dir: string,
) -> errors.SfcException {

	dest_file := filepath.join({dest_dir, src_file.name}, context.temp_allocator)

	copy_error := filesystem.copy_file_raw(src_file.fullpath, dest_file)

	if copy_error != {} do return copy_error
	else {
		sync.atomic_add(&token.progress.finished_count, 1)
		sync.atomic_add(&token.progress.finished_size, src_file.size)
		return {}
	}
}

