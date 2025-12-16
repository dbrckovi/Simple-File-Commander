package sfc

import "core:fmt"
import "core:sync"
import "core:time"

/*
	Information on amount of work finished by a thread.
	Not all values have to be used in every thread.
*/
ThreadProgress :: struct {
	total_count:    i64, //total number of items
	total_size:     i64, //total size of items in bytes
	finished_count: i64, //number of finished items
	finished_size:  i64, //sum sizes of finished bytes
}

/*
	Current thread state. Set by the thread itself
*/
ThreadState :: enum {
	not_started, //state before thread starts
	running, //state when thread is running
	stopped, //thread has stopped
}

ThreadRequestType :: enum {
	none = 0, //there are no pending dialog requests
	overwrite_file,
}

DialogResult :: enum {
	none = 0, //nobody responded yet
	yes,
	no,
	yes_all,
	no_all,
	ok,
	cancel,
}

ThreadDialog :: struct {
	request:       ThreadRequestType,
	request_text:  string,
	response:      DialogResult,
	response_text: string,
}

/*
	Starts a thread dialog and waits for other side to answer
*/
start_thread_dialog :: proc(
	dialog: ^ThreadDialog,
	request: ThreadRequestType,
	request_text: string,
) -> (
	response: DialogResult,
	response_text: string,
) {
	if sync.atomic_load(&dialog.response) != .none do panic("Response of previous dialog was not cleared")
	if len(dialog.response_text) > 0 do panic("Response text of prevouls dialog was not cleared")
	if sync.atomic_load(&dialog.request) != .none do panic("Request of previous dialog was not cleared")
	if len(dialog.request_text) > 0 do panic("Response text of prevouls dialog was not cleared")

	if len(request_text) > 0 {
		dialog.request_text = fmt.aprint(request_text)
		sync.atomic_store(&dialog.request, request)
	}

	//wait for response
	trigger_update()
	for sync.atomic_load(&dialog.response) == .none {
		time.sleep(time.Millisecond)
	}

	response = dialog.response
	if len(dialog.response_text) > 0 {
		response_text = fmt.aprint(dialog.response_text)
	}

	clear_thread_dialog(dialog)
	return response, response_text
}

/*
	Clears threading dialog. Only background thread who initiated the dialog may call this
*/
clear_thread_dialog :: proc(dialog: ^ThreadDialog) {
	sync.atomic_store(&dialog.request, .none)
	sync.atomic_store(&dialog.response, .none)

	if len(dialog.request_text) > 0 {
		delete(dialog.request_text)
	}
	if len(dialog.response_text) > 0 {
		delete(dialog.response_text)
	}
}

