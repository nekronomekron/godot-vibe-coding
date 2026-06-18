extends Node2D
class_name DrawProxy
## Kleiner Zeichen-Helfer: ruft beim Neuzeichnen eine zugewiesene Callable auf.
## Erlaubt eigene Zeichen-Ebenen (Halo, Overlay) als Node2D-Kinder unter der
## Pan/Zoom-Transform des Editors, ohne pro Ebene ein eigenes Skript.

var draw_fn: Callable

func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self)
