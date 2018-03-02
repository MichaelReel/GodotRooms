
extends Node2D

var debug_polys

func _init(polys):
    self.debug_polys = polys

func _draw():
	for poly in self.debug_polys:
		draw_polyline(poly, Color("#FFFF0000"), 2.0)