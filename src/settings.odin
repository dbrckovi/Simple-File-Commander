package sfc

import "core:os"
import "core:strconv"
import "core:strings"

Settings :: struct {
	columns:                [dynamic]FilePanelColumn, //specifies which columns are visible and their order from left -> right (actual columns drawn depend on available space)
	name_column_min_size:   uint, //dynamic columns will not be drawn if they would reduce space of name column below this value
	icon_link_to_file:      rune,
	icon_executable:        rune,
	icon_link_to_directory: rune,
	show_hidden_files:      bool,
	attribute_format:       Attribute_Format,
}

Attribute_Format :: enum {
	octal,
	symbolic,
}

/*
	Initializes and allocates the _settings instance fields to default values
*/
init_settings :: proc() {
	_settings.columns = make([dynamic]FilePanelColumn, 0, context.allocator)
	reset_default_settings()
}

reset_default_settings :: proc() {
	clear(&_settings.columns)
	append(&_settings.columns, FilePanelColumn.size)
	append(&_settings.columns, FilePanelColumn.date)
	append(&_settings.columns, FilePanelColumn.attributes)
	_settings.name_column_min_size = 10
	_settings.icon_link_to_file = '~'
	_settings.icon_executable = '*'
	_settings.icon_link_to_directory = '@'
	_settings.show_hidden_files = false
	_settings.attribute_format = .symbolic
}

/*
	If settings file exists, loads it into _settings instance
*/
load_settings :: proc() {

	file_path := get_local_config_file_path()
	bytes: []u8
	loaded: bool

	if os.exists(file_path) {
		bytes, loaded = os.read_entire_file(file_path, context.temp_allocator)
	}

	if loaded {
		text := string(bytes)

		sb := strings.builder_make(context.temp_allocator)

		for char in text {
			if char != '\n' {
				strings.write_rune(&sb, char)
			} else {
				parse_settings_line(strings.to_string(sb))
				strings.builder_reset(&sb)
			}
		}

		parse_settings_line(strings.to_string(sb))
	}
}

/*
	Parses a line loaded from config and, if parsed correctly, updates the settings
	@param line: line of text from config file
	@returns bool which indicates if line was successfully parsed
*/
parse_settings_line :: proc(line: string) -> bool {
	if len(line) == 0 do return false
	if strings.starts_with(line, "#") || strings.starts_with(line, ";") do return false

	equal_index := strings.index(line, "=")
	if equal_index > 0 {
		key := strings.trim(line[:equal_index], " ")
		value := strings.trim(line[equal_index + 1:], " ")

		switch key {
		case "name_column_min_size":
			parsed, ok := strconv.parse_uint(value)
			if ok && parsed >= 7 {
				_settings.name_column_min_size = parsed
			}
		case "icon_link_to_file":
			if len(value) == 1 {
				_settings.icon_link_to_file = rune(value[0])
			} else {
				_settings.icon_link_to_file = ' '
			}
		case "icon_executable":
			if len(value) == 1 {
				_settings.icon_executable = rune(value[0])
			} else {
				_settings.icon_executable = ' '
			}
		case "icon_link_to_directory":
			if len(value) == 1 {
				_settings.icon_link_to_directory = rune(value[0])
			} else {
				_settings.icon_link_to_directory = ' '
			}
		case "show_hidden_files":
			parsed, ok := strconv.parse_bool(value)
			if ok {
				_settings.show_hidden_files = parsed
			}
		case "attribute_format":
			switch value {
			case "octal":
				_settings.attribute_format = .octal
			case:
				_settings.attribute_format = .symbolic
			}
		case "columns":
			parts: []string = strings.split(value, ",", context.temp_allocator)
			clear(&_settings.columns)

			for part in parts {
				trimmed := strings.trim(part, " ")
				switch trimmed {
				case "size":
					if !contains(&_settings.columns, FilePanelColumn.size) {
						append(&_settings.columns, FilePanelColumn.size)
					}
				case "date":
					if !contains(&_settings.columns, FilePanelColumn.date) {
						append(&_settings.columns, FilePanelColumn.date)
					}
				case "attributes":
					if !contains(&_settings.columns, FilePanelColumn.attributes) {
						append(&_settings.columns, FilePanelColumn.attributes)
					}
				}
			}
		case:
			return false
		}
	}
	return false
}


/*
	Gets path to a local user's config directory
*/
get_local_config_directory :: proc() -> string {
	when ODIN_OS == .Windows {
		//TODO: revise this on windows
		return os.get_env("LOCALAPPDATA", context.temp_allocator)
	} else {
		return strings.concatenate(
			{os.get_env("HOME", context.temp_allocator), "/.config/", _application_name_short},
			context.temp_allocator,
		)
	}
}

/*
	Gets local user's config file path
*/
get_local_config_file_path :: proc() -> string {
	separator: string
	when ODIN_OS == .Windows {separator = "\\"} else {separator = "/"}

	return strings.concatenate(
		{get_local_config_directory(), "/config.cfg"},
		context.temp_allocator,
	)
}

