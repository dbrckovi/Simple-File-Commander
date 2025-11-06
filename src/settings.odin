package sfc

Settings :: struct {
	columns:              [dynamic]FilePanelColumn, //specifies which columns are visible and their order from left -> right (actual columns drawn depend on available space)
	name_column_min_size: uint, //dynamic columns will not be drawn if they would reduce space of name column below this value
}

/*
	Initializes and allocates the _settings instance fields to default values
*/
init_settings :: proc() {
	_settings.columns = make([dynamic]FilePanelColumn, 0, context.allocator)
	append(&_settings.columns, FilePanelColumn.size)
	append(&_settings.columns, FilePanelColumn.date)
	append(&_settings.columns, FilePanelColumn.attributes)
	_settings.name_column_min_size = 10
}

load_settings :: proc() {
	//TODO: find in user's .config directory (when name is decided)
	panic("Not implemented")
}

