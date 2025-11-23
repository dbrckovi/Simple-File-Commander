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

/*
	Wraps the text by splitting it to multiple lines of specified width.
	Existing new lines are respected. Words are not cut unless they are longer than line width.
	If new line would start with space, the first space is cut
	@param text: text to wrap
	@param width: max line width
*/
wrap_text :: proc(text: string, width: int, allocator := context.allocator) -> [dynamic]string {
	//WARN: This is probably not even close to being optimal
	assert(width > 0)

	characters: [dynamic]rune = make([dynamic]rune, 0, context.temp_allocator) //array of all characters (easier to work with)
	lines: [dynamic]string = make([dynamic]string, 0, allocator) //array of resulting lines
	line_builder := strings.builder_make(context.temp_allocator) //builds each line
	current_line_start := 0
	current_line_end := 0

	for char in text {
		append(&characters, char) //copy to char array
	}

	for {
		current_line_start, current_line_end = get_next_line_for_wrap(
			&characters,
			current_line_start,
			width,
		)

		for x := current_line_start; x <= current_line_end; x += 1 {
			if characters[x] != '\n' {
				strings.write_rune(&line_builder, characters[x])
			}
		}

		append(&lines, strings.clone(strings.to_string(line_builder), context.allocator))
		strings.builder_reset(&line_builder)

		if current_line_end == len(characters) - 1 {
			break
		} else {
			current_line_start = current_line_end + 1
		}
	}

	return lines
}

/*
	Gets start and end indexes of the next line. Used in wrap_text procedure
	@param characters: array of all characters in a string
	@param start: character index from which the next line should start
	@param width: maximum width of the line
	@returns new_start: index of the first character in a new line
	@returns new_end: index of the last character in a new line
	NOTE: 'new_start' sometimes differs from 'start'.
*/
get_next_line_for_wrap :: proc(
	characters: ^[dynamic]rune,
	start: int,
	width: int,
) -> (
	new_start: int,
	new_end: int,
) {
	new_start = start

	new_end = new_start + width - 1 //take next 'width' charactrs
	if new_end >= len(characters) {
		new_end = len(characters) - 1 //if we reached end of text, trim up to the end
	}

	last_space_index := -1
	for x := new_start; x <= new_end; x += 1 {
		if characters[x] == '\n' {
			//if we found 'new line', return up to it, but before that, fix the line if it beings with 'space' (looks ugly)
			if characters[new_start] == ' ' && x != new_start {
				new_start += 1
			}
			return new_start, x
		} else if characters[x] == ' ' {
			last_space_index = x
		}
	}

	//if there is a space in line, and the last word would be split, end at the last space
	if last_space_index >= 0 && last_space_index != new_end {
		if len(characters) > new_end + 1 && characters[new_end + 1] != ' ' {
			new_end = last_space_index
		}
	}

	//fix the line if it starts with space (looks ugly)
	if characters[new_start] == ' ' && new_end != new_start {
		new_start += 1
	}

	return new_start, new_end
}

