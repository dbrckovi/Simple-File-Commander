package sfc

import "core:sync"
import "core:thread"
import "core:time"
import "errors"

FileCopyToken :: struct {
	cancel_requested:  bool, //caller thread sets this to false to cancel the thread
	thread:            ^thread.Thread,
	request:           i32, //TODO: type
	response:          i32, //TODO: type
	source_file_infos: [dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination_dir:   string, //destination directory. Set by caller thread
	using settings:    FileCopySettings,
	using progress:    ProgressInfo,
}

FileCopySettings :: struct {
	overwrite_files: Maybe(bool), //nil -> ask user
}

// TODO: put somewhere more general
ProgressInfo :: struct {
	total_count:    i64, //total number of items
	total_size:     i64, //total size of items in bytes
	finished_count: i64, //number of finished items
	finished_size:  i64, //sum sizes of finished bytes
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

stop_and_destroy_file_copy_thread :: proc(token: ^FileCopyToken) {
	sync.atomic_store(&token.cancel_requested, true)
	thread.join(token.thread)
	thread.destroy(token.thread)
}

file_copy_work :: proc(t: ^thread.Thread) {
	token := (^FileCopyToken)(t.data)

	for {
		//TODO: do
		sync.atomic_add(&token.finished_count, 1)
		time.sleep(time.Millisecond)
	}

	//TODO: Set success result to token
}

