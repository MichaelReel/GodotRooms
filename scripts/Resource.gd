extends Node2D

# Attempting to use this as a means to group some 
# resources to get FSB results and tiles

export (TileSet) var tileset
export (Vector2) var average_base_size
export (String) var map_name

const wave_width = 32
const wave_height = 32
const wave_depth = 1

var perlinRef = load("res://scripts/PerlinRef.gd")

var tile_size

var walls
var stairs
var base_fbm

func _ready():
	self.tile_size = self.tileset.tile_get_region(1).size
	
	self.walls = {}
	for i in range(16):
		self.walls[i] = self.tileset.find_tile_by_name("wall_%02d" % i)
	
	self.stairs = {}
	for i in [3, 5, 10, 12]:
		self.stairs[i] = self.tileset.find_tile_by_name("stair_%02d" % i)
	
	rand_seed(map_name.hash())

	self.base_fbm = self.perlinRef.new(wave_width, wave_height, wave_depth, 4, randi())