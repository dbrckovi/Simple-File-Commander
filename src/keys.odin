package sfc

import t "../lib/TermCL"

key_to_rune :: proc(key: t.Key) -> rune {
	//TODO: update TermCL and hope it returns keys in a more sane way
	#partial switch key {
	case .A:
		return 'a'
	case .B:
		return 'b'
	case .C:
		return 'c'
	case .D:
		return 'd'
	case .E:
		return 'e'
	case .F:
		return 'f'
	case .G:
		return 'g'
	case .H:
		return 'h'
	case .I:
		return 'i'
	case .J:
		return 'j'
	case .K:
		return 'k'
	case .L:
		return 'l'
	case .M:
		return 'm'
	case .N:
		return 'n'
	case .O:
		return 'o'
	case .P:
		return 'p'
	case .Q:
		return 'q'
	case .R:
		return 'r'
	case .S:
		return 's'
	case .T:
		return 't'
	case .U:
		return 'u'
	case .V:
		return 'v'
	case .W:
		return 'w'
	case .X:
		return 'x'
	case .Y:
		return 'y'
	case .Z:
		return 'z'
	case .Num_0:
		return '0'
	case .Num_1:
		return '1'
	case .Num_2:
		return '2'
	case .Num_3:
		return '3'
	case .Num_4:
		return '4'
	case .Num_5:
		return '5'
	case .Num_6:
		return '6'
	case .Num_7:
		return '7'
	case .Num_8:
		return '8'
	case .Num_9:
		return '9'
	case .Space:
		return ' '
	case .Double_Quote:
		return '"'
	case .Backslash:
		return '\\'
	case:
		return {}
	}
}

