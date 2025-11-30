package sfc

import t "../lib/TermCL"
import "core:fmt"
import "core:strings"

CommandBar :: struct {
	chars: [dynamic]rune,
	error: Maybe(string),
}

CommandAndParams :: struct {
	command: string,
	params:  [dynamic]string,
}

create_command_bar :: proc(allocator := context.allocator) -> CommandBar {
	return CommandBar{chars = make([dynamic]rune, allocator)}
}

draw_command_bar :: proc(bar: ^CommandBar) {
	y := int(_screen.size.h - 1)
	rect: Rectangle = {0, y, int(_screen.size.w), y}

	paint_rectangle(rect, _current_theme.dialog_main.bg)

	error, has_error := bar.error.(string)
	if has_error {
		set_colors(_current_theme.error_message.fg, _current_theme.dialog_main.bg)
		write(error, {1, uint(y)})
	} else {
		set_color_pair(_current_theme.dialog_main)
		write(":", {0, uint(y)})
		set_color_pair(_current_theme.dialog_title)

		for c, i in bar.chars {
			write(c, {uint(i + 1), uint(y)})
		}
	}
}

destroy_command_bar :: proc(bar: ^CommandBar) {
	delete(bar.chars)
}

handle_input_command_bar :: proc(bar: ^CommandBar, input: t.Input) {
	switch i in input {
	case t.Keyboard_Input:
		if !clear_command_bar_error(bar) {
			char := key_to_rune(i.key)
			if char != {} {
				append(&bar.chars, char)
			} else {
				if i.key == .Backspace {
					if len(bar.chars) > 0 {
						unordered_remove(&bar.chars, len(bar.chars) - 1)
					}
				}
				if i.key == .Enter {
					try_execute_bar_command(bar, context.allocator)
				}
			}
		}
	case t.Mouse_Input:
	}
}

/*
	Parses and tries to execute command typed into command bar
*/
try_execute_bar_command :: proc(bar: ^CommandBar, allocator := context.allocator) {
	sb := strings.builder_make(context.temp_allocator)
	for char in bar.chars {
		strings.write_rune(&sb, char)
	}

	cmd, ok := parse_command(strings.to_string(sb))

	if !ok {
		set_command_bar_error(bar, "Invalid command format!")
	} else { 	//TODO: make some central list so that hints can be displayed

		if strings.equal_fold(cmd.command, "q") || strings.equal_fold(cmd.command, "quit") {
			_should_run = false


		} else if strings.equal_fold(cmd.command, "msgbox") {
			clear(&bar.chars)
			text := len(cmd.params) > 0 ? cmd.params[0] : "text not defined"
			title := len(cmd.params) > 1 ? cmd.params[1] : "title not defined"
			destroy_current_dialog()
			_current_dialog = create_messagebox(text, title)


		} else if strings.equal_fold(cmd.command, "cd..") ||
		   strings.equal_fold(cmd.command, "cd_up") {
			destroy_current_dialog()
			cd_up(_focused_panel)


		} else if strings.equal_fold(cmd.command, "cd") {
			if len(cmd.params) > 0 {
				//TODO: handle special shell directories and environment variables (ex: ~)
				if cmd.params[0] == "." {
					destroy_current_dialog()
					reload_file_panel(_focused_panel)
				} else if cmd.params[0] == ".." {
					destroy_current_dialog()
					cd_up(_focused_panel)
				} else {
					error := cd(_focused_panel, cmd.params[0])
					if error == nil {
						destroy_current_dialog()
					} else {
						set_command_bar_error(bar, fmt.tprint(error))
					}
				}
			} else {
				set_command_bar_error(bar, "Directory parameter is missing")
			}


		} else if strings.equal_fold(cmd.command, "help") || cmd.command == "?" {
			destroy_current_dialog()
			_current_dialog = create_text_viewer("TODO: draw help", "Help")

		} else if strings.equal_fold(cmd.command, "debug") {
			debug()


		} else {
			set_command_bar_error(bar, "Invalid command")
		}
	}
}

/*
	Sets command bar error which will be displayed until user's action
	Clones the error_text
*/
set_command_bar_error :: proc(
	bar: ^CommandBar,
	error_text: string,
	allocator := context.allocator,
) {
	clear_command_bar_error(bar)
	bar.error = strings.clone(error_text, allocator)
}

clear_command_bar_error :: proc(bar: ^CommandBar) -> bool {
	previous_error, had_error := bar.error.(string)
	if had_error {
		delete(previous_error)
		bar.error = nil
	}
	return had_error
}

/*
	Parses text into command and parameters.
	Leading spaces are ignored
	First word is a command, rest of the text are parameters.
	Parameters are either words separated by space, or strings enclosed in double quotes
	To use double quotes within a string parameter, escape it with \"
	Examples:
		quit
		shutdown now
		delete aaa.txt
		copy aaa.txt bbb.txt
		move "aa aa.txt" "bb bb.txt"
		compare "aa aa.txt" bbb.txt
		echo "This parameter contains \"quoted\" text"
*/
parse_command :: proc(text: string) -> (CommandAndParams, bool) {
	assert(len(text) > 0)
	ret: CommandAndParams
	ret.params = make([dynamic]string, context.temp_allocator)

	word := strings.builder_make(context.temp_allocator)
	quote_started := false
	escape_started := false

	for char in text {
		word_started := strings.builder_len(word) > 0 || quote_started
		add_char := false
		finish_word := false

		if escape_started && char != '"' { 	//escape char was not followed by double quote
			strings.write_rune(&word, '\\')
			escape_started = false
		}

		if char == ' ' {
			if word_started {
				if quote_started {
					add_char = true
				} else {
					finish_word = true
				}
			} // else not needed because that is space between words which is ignored
		} else if char == '"' {
			if word_started {
				if quote_started {
					if escape_started { 	//finish of escaped double quote
						add_char = true
						escape_started = false
					} else { 	//normal finish of quoted word
						quote_started = false
						finish_word = true
					}
				} else { 	//naked quotation inside unquoted word
					return ret, false
				}
			} else { 	//word not started
				if quote_started { 	//should be impossible
					return ret, false
				} else { 	//normal start of quoted word
					quote_started = true
				}
			}
		} else if char == '\\' {
			if word_started && quote_started {
				escape_started = true //escape inside quoted word
			} else {
				add_char = true
			}
		} else {
			add_char = true
		}

		if add_char {
			strings.write_rune(&word, char)
		}

		if finish_word {
			w := strings.clone(strings.to_string(word), context.temp_allocator)
			if ret.command == {} {
				ret.command = w
			} else {
				append(&ret.params, w)
			}
			strings.builder_reset(&word)
		}
	}

	if quote_started {
		return ret, false
	}

	if strings.builder_len(word) > 0 {
		w := strings.clone(strings.to_string(word), context.temp_allocator)
		if ret.command == {} {
			ret.command = w
		} else {
			append(&ret.params, w)
		}
	}

	return ret, true
}

