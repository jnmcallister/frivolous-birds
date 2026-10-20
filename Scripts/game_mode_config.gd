# Holds which game mode the players picked on the start menu.
#
# current_mode is a static variable, so it survives the scene reload done by the
# retry button without needing an autoload or any project.godot changes.
#
# Usage:
#   GameModeConfig.current_mode = GameModeConfig.GameMode.CLASSIC
#   if GameModeConfig.current_mode == GameModeConfig.GameMode.CLASSIC:
#       ...
#
# RULE: read current_mode only when the game starts or while it is running,
# never in _ready(). _ready() runs when the scene loads, before a start button
# is pressed, so the value could still be left over from the previous run.

class_name GameModeConfig
extends RefCounted

enum GameMode {
	NORMAL, # Main game. All new features go here
	CLASSIC # Frozen baseline. No new features, uses the CLASSIC_ values
}

# Mode for the current run. A start button (or the jump key shortcut) always sets
# this before start_game() runs. Defaults to NORMAL on first launch.
static var current_mode: GameMode = GameMode.NORMAL
