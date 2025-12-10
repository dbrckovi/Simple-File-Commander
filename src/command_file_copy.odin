package sfc

import "core:sync"
import "core:thread"
import "core:time"
import "errors"

FileCopyToken :: struct {
	run:               bool, //caller thread sets this to false to cancel the thread
	thread:            ^thread.Thread,
	request:           i32, //TODO: type
	response:          i32, //TODO: type
	source_file_infos: ^[dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination:       string, //destination directory. Set by caller thread
	using settings:    FileCopySettings,
	using progress:    ProgressInfo,
}

FileCopySettings :: struct {
	overwrite_files:   Maybe(bool), //nil -> ask user
	overwrite_dirs:    Maybe(bool), //nil -> ask user
	continue_on_error: Maybe(bool), //nil -> ask user
	copy_hidden:       Maybe(bool), //nil -> ask user
}

// TODO: put somewhere more general
ProgressInfo :: struct {
	total_count:      i32,
	finished_percent: f32,
	finished_count:   i32,
}

start_file_copy_thread :: proc(
	source_file_infos: ^[dynamic]SfcFileInfo,
	destination: string,
) -> (
	^FileCopyToken,
	errors.SfcException,
) {
	token: ^FileCopyToken = new(FileCopyToken)
	token.run = true
	token.source_file_infos = source_file_infos
	token.destination = destination
	token.thread = thread.create(file_copy_work)

	if token.thread == nil {
		err := errors.create_exception(
			errors.GeneralError.thread_not_created,
			"File copy thread was not created",
			context.temp_allocator,
		)
		return nil, err
	}

	token.thread.init_context = context
	token.thread.data = rawptr(token)
	thread.start(token.thread)
	return token, {}
}

stop_and_destroy_file_copy_thread :: proc(token: ^FileCopyToken) {
	sync.atomic_store(&token.run, false)
	thread.join(token.thread)
	thread.destroy(token.thread)
}

file_copy_work :: proc(t: ^thread.Thread) {
	token := (^FileCopyToken)(t.data)

	for sync.atomic_load(&token.run) {
		//TODO: do
		sync.atomic_add(&token.finished_count, 1)
		time.sleep(time.Millisecond)
	}

	//TODO: Set success result to token
}

