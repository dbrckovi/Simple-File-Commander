package sfc

import "core:strconv"

/*
	Holds colors for every gui element in the application
*/
Theme :: struct {
	main:             RgbPair,
	column_header:    RgbPair,
	sort_indicator:   RgbPair,
	focused_panel:    RgbPair,
	focused_file_row: RgbPair,
	error_message:    RgbPair,
	debug_message:    RgbPair,
	panel_title:      RgbPair,
	directory_normal: RgbPair,
	directory_hidden: RgbPair,
	file_normal:      RgbPair,
	file_executable:  RgbPair,
	file_hidden:      RgbPair,
	//TODO: system,  etc
}

/*
	Foreground and background pair
*/
RgbPair :: struct {
	fg:     [3]u8,
	use_fg: bool,
	bg:     [3]u8,
	use_bg: bool,
}

/*
	Resets the specified theme colors to default
*/
reset_theme_to_default :: proc(theme: ^Theme) {
	theme.main.fg = hex_to_rgb("#BBBBBB")
	theme.main.bg = hex_to_rgb("#202344")
	theme.main.use_fg = true
	theme.main.use_bg = true

	theme.focused_panel.bg = hex_to_rgb("#252849")
	theme.focused_panel.use_bg = true

	theme.focused_file_row.bg = hex_to_rgb("#454869")
	theme.focused_file_row.use_bg = true

	theme.column_header.fg = hex_to_rgb("#DD9922")
	theme.column_header.use_fg = true

	theme.panel_title.fg = hex_to_rgb("#CCCC22")
	theme.panel_title.use_fg = true

	theme.directory_normal.fg = hex_to_rgb("#CCCC22")
	theme.directory_normal.use_fg = true

	theme.directory_hidden.fg = hex_to_rgb("#AAAA99")
	theme.directory_hidden.use_fg = true

	theme.sort_indicator.fg = hex_to_rgb("#FFDD55")
	theme.sort_indicator.use_fg = true

	theme.error_message.fg = hex_to_rgb("#FF4422")
	theme.error_message.use_fg = true

	theme.debug_message.fg = hex_to_rgb("#44FF22")
	theme.debug_message.use_fg = true

	theme.file_normal.fg = hex_to_rgb("#CCCCCC")
	theme.file_normal.use_fg = true

	theme.file_executable.fg = hex_to_rgb("#22FF22")
	theme.file_executable.use_fg = true

	theme.file_hidden.fg = hex_to_rgb("#9999CC")
	theme.file_hidden.use_fg = true
}

/*
	Parses color from hex string format (#RRGGBB) to [3]u8
*/
hex_to_rgb :: proc(hex_rgb: string) -> [3]u8 {
	if len(hex_rgb) != 7 {
		return {0, 0, 0}
	}

	r, _ := strconv.parse_u64(hex_rgb[1:3], 16)
	g, _ := strconv.parse_u64(hex_rgb[3:5], 16)
	b, _ := strconv.parse_u64(hex_rgb[5:7], 16)

	return {u8(r), u8(g), u8(b)}
}

