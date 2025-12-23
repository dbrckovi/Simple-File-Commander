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
	// token.thread = thread.create(file_copy_work)

	// if token.thread == nil {
	// 	err := errors.create_exception(
	// 		errors.GeneralError.thread_not_created,
	// 		"File copy thread was not created",
	// 		context.temp_allocator,
	// 	)
	// 	return err
	// }

	// token.thread.init_context = context
	// token.thread.data = rawptr(token)
	// thread.start(token.thread)
	return {}
}

stop_and_destroy_file_copy_thread :: proc(token: ^FileCopyToken) {
	sync.atomic_store(&token.cancel_requested, true)
	thread.join(token.thread)
	thread.destroy(token.thread)
}

// file_copy_work :: proc(t: ^thread.Thread) {
// 	token := (^FileCopyToken)(t.data)
// 	sync.atomic_store(&token.state, .running)

// 	i := 0

// 	for file in token.source_file_infos {
// 		sync.atomic_add(&token.finished_count, 1)
// 		sync.atomic_add(&token.finished_size, 100)

// 		if file.file.is_dir {
// 			//TODO: call copy dir
// 		} else {
// 			copy_error := threaded_copy_file(token, file.file, token.destination_dir)

// 			if copy_error != {} {
// 				token.state = .stopped
// 				//TODO: set error to token
// 			}
// 		}

// 		time.sleep(300 * time.Millisecond)
// 	}

// 	sync.atomic_store(&token.state, .stopped)
// }


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

	if os.exists(dest_file) {
		overwrite, can_continue := should_overwrite_file(token, dest_file)
		if !can_continue {
			return errors.create_exception(
				.cancelled,
				fmt.tprint("File copy operation cancelled"),
				context.allocator,
			)
		} else if !overwrite {
			sync.atomic_add(&token.finished_count, 1)
			return {}
		}
	}

	copy_error := filesystem.copy_file_raw(src_file.fullpath, dest_file)

	if copy_error != {} do return copy_error
	else {
		sync.atomic_add(&token.finished_count, 1)
		sync.atomic_add(&token.finished_size, src_file.size)
		return {}
	}
}

should_overwrite_file :: proc(
	token: ^FileCopyToken,
	file_path: string,
) -> (
	overwrite: bool = true,
	can_continue: bool,
) {
	old_overwrite, ok := token.overwrite_files.?

	if ok {
		overwrite = old_overwrite
	} else {
		response, response_text := post_thread_request(&token.dialog, .overwrite_file, file_path)
		if len(response_text) > 0 do delete(response_text)

		#partial switch response {
		case .cancel:
			can_continue = false
		case .yes:
			overwrite = true
		case .yes_all:
			overwrite = true
			token.overwrite_files = true
		case .no:
			overwrite = false
		case .no_all:
			overwrite = false
			token.overwrite_files = false
		case .none:
			panic("Unexpected dialog response")
		}
	}

	response, response_text := post_thread_request(&token.dialog, .overwrite_file, file_path)
	if len(response_text) > 0 do delete(response_text)

	return overwrite, can_continue
}

