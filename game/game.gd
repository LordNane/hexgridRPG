extends Node
## Autoload "Game": the global entry point. Holds the playthrough in progress.
##
## Phase 3 adds starting and loading games, and the ModeRouter that switches between exploration,
## battles and menus. Systems should receive the session as a parameter where practical rather
## than reaching for this autoload, so tests can build their own.

## The playthrough in progress.
var session := GameSession.new(int(Time.get_unix_time_from_system()))
