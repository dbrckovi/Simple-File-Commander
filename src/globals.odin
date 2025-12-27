package sfc

import "core:sys/posix"

_application_name := "Simple File Commander" //Application name for displaying in GUI
_application_name_short := "sfc" //Name for directories, binaries, links, etc
_should_run := true //Once this becomes false, program exits
_pid: posix.pid_t //This program's process ID
_left_panel: FilePanel //Left panel data
_right_panel: FilePanel //Right panel data
_current_theme: Theme
_focused_panel: ^FilePanel
_settings: Settings
_widgets: WidgetStack //thread-safe "stack" of dialogs.

