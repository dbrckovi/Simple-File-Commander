package sfc

import "core:os"
import "core:strings"
import "core:time"

/*
	Compares file names.

	Case-insensitive (ex: 'AAA' is the same as 'AAA')
	Leading dot in hidden files is ignored (ex: '.aaa' is the same as 'aaa')
*/
compare_file_names :: proc(a, b: string) -> int {

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

compare_dates :: proc(a, b: time.Time) -> int {
	//TODO: find better algorithm or at least make generic
	if a._nsec > b._nsec do return 1
	else if a._nsec < b._nsec do return -1
	else do return 0
}

compare_sizes :: proc(a, b: i64) -> int {
	//TODO: find better algorithm or at least make generic
	if a > b do return 1
	else if a < b do return -1
	else do return 0
}

contains :: proc(array: ^$T/[dynamic]$E, arg: E) -> bool {
	for item in array {
		if item == arg {
			return true
		}
	}

	return false
}

wrap_text :: proc(text: string, width: int, allocator := context.allocator) -> [dynamic]string {
	lines: [dynamic]string

	/*
	TODO:
	- split into words by spaces (don't forget new line char)
	- if word is longer than width, force split after last character
	- make string builder
	- keep adding words into stringbuilder for as long as there is space for next word
	- when there is no space for next word or \n is encountered commit string builder to array of lines and reset builder
	*/

	return lines
}

