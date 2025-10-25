package sfc

import "core:strconv"

/*
	Holds colors for every gui element in the application
*/
Theme :: struct {
	main:           RgbPair,
	column_header:  RgbPair,
	sort_indicator: RgbPair,
}

/*
	Foreground and background pair
*/
RgbPair :: struct {
	foreground: [3]u8,
	background: [3]u8,
}

/*
	Resets the specified theme colors to default
*/
reset_theme_to_default :: proc(theme: ^Theme) {
	theme.main.foreground = hex_to_rgb("#FFFFFF")
	theme.main.background = hex_to_rgb("#0000FF")

	theme.column_header.foreground = hex_to_rgb("#DD9922")
	theme.column_header.background = theme.main.background

	theme.sort_indicator.foreground = hex_to_rgb("#FFDD55")
	theme.sort_indicator.background = theme.main.background
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

