@abstract
class_name BattleEvent extends RefCounted
## Something that happened in a battle, returned by Battle so a view can show it. The model has
## already changed by the time the view plays it. Each kind of event is a small subclass, and
## BattleView has one handler per kind.
