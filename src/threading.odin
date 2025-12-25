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

