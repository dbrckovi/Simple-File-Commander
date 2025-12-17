package sfc

import "core:sync"
import "core:thread"
import "core:time"
import "errors"
import "filesystem"

FileCopyToken :: struct {
	cancel_requested:  bool, //set to true when thread should stop
	state:             ThreadState, //current state of the thread. Set by thread
	thread:            ^thread.Thread,
	dialog:            ThreadDialog,
	source_file_infos: [dynamic]SfcFileInfo, //array of items which were selected in the source panel. Set by caller thread
	destination_dir:   string, //destination directory. Set by caller thread
	using settings:    FileCopySettings,
	using progress:    ThreadProgress,
}

FileCopySettings :: struct {
	overwrite_files: Maybe(bool), //nil -> ask user
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
	sync.atomic_store(&token.state, .running)

	i := 0

	for file in token.source_file_infos {
		sync.atomic_add(&token.finished_count, 1)
		sync.atomic_add(&token.finished_size, 100)

		i += 1
		if i == 4 {
			response, response_text := post_thread_request(
				&token.dialog,
				.overwrite_file,
				file.file.fullpath,
			)

			if len(response_text) > 0 do delete(response_text)

			if response == .cancel do break
			//TODO: Handle response properly
		}

		trigger_update()
		time.sleep(300 * time.Millisecond)
	}

	sync.atomic_store(&token.state, .stopped)
	trigger_update()
}

