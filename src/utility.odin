package sfc

import "core:os"
import "core:strings"

/*
	Compares file names.

	Case-insensitive (ex: 'AAA' is the same as 'AAA')
	Leading dot in hidden files is ignored (ex: '.aaa' is the same as 'aaa')
*/
compare_file_name :: proc(a, b: string) -> int {

	a_dotless: string
	b_dotless: string

	if strings.starts_with(a, ".") {
		a_dotless = a[1:]
	} else {
		a_dotless = a
	}

	if strings.starts_with(b, ".") {
		b_dotless = b[1:]
	} else {
		b_dotless = b
	}

	a_dotless_lowercase := strings.to_lower(a_dotless, context.temp_allocator)
	b_dotless_lowercase := strings.to_lower(b_dotless, context.temp_allocator)

	ret := strings.compare(a_dotless_lowercase, b_dotless_lowercase)

	if ret == 0 {
		return strings.compare(a_dotless, b_dotless)

	} else {
		return ret
	}
}

contains :: proc(array: ^$T/[dynamic]$E, arg: E) -> bool {
	for item in array {
		if item == arg {
			return true
		}
	}

	return false
}

