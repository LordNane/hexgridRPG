extends Node
## Autoload "EventBus": game-wide broadcast signals.
##
## Only for news that many unrelated systems care about (an item was acquired, a story flag
## changed). Wire everything else with the emitting node's own signals.
