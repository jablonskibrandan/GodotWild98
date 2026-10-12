class_name DistractionManager
extends Node2D

signal sound_made(source: Node2D, volume: float)

func broadcast_sound(source: Node2D, volume: float):
	sound_made.emit(source, volume)
