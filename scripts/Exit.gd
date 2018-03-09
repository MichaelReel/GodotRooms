extends StaticBody2D

const EXIT_TOP = 0
const EXIT_BOTTOM = 1
const EXIT_LEFT = 2
const EXIT_RIGHT = 3
const EXIT_UP = 4
const EXIT_DOWN = 5

const EXIT_DIRS = ["top", "bottom", "left", "right", "up", "down"]

var resource
var cellv

# Set these to determine where this exit goes
var room
var destination

func _init(resource, dir, tile_size = Vector2(16, 16)):
	self.resource = resource
	# Create Sprite
	var templates = resource.get_node("SpritePool")
	var exit_sprite = templates.get_node("Exit_" + str(dir))
	var sprite = exit_sprite.duplicate()
	sprite.visible = true
	add_child(sprite)

	# Add collsion body
	# var collision = CollisionShape2D.new()
	# collision.position = Vector2(8, 8)
	# collision.shape = RectangleShape2D.new()
	# collision.shape.extents = Vector2(8, 8)
	add_child(create_collider(dir, tile_size) )

func details():
	return str(self) + ": " + str(self.position)

func exit_start(i, room_size):
	var cellv
	match i:
		EXIT_TOP:
			cellv = Vector2(int(room_size.x / 2), 0)
		EXIT_BOTTOM:
			cellv = Vector2(int(room_size.x / 2), room_size.y)
		EXIT_LEFT:
			cellv = Vector2(0, int(room_size.y / 2))
		EXIT_RIGHT:
			cellv = Vector2(room_size.x, int(room_size.y / 2))
		EXIT_UP:
			cellv = Vector2(int(room_size.x / 2), int(room_size.y / 2) - 1)
		EXIT_DOWN:
			cellv = Vector2(int(room_size.x / 2), int(room_size.y / 2) + 1)
	return cellv

func exit_incursion(i):
	var inc
	match i:
		EXIT_TOP:
			inc = Vector2(0, 1)
		EXIT_BOTTOM:
			inc = Vector2(0, -1)
		EXIT_LEFT:
			inc = Vector2(1, 0)
		EXIT_RIGHT:
			inc = Vector2(-1, 0)
		EXIT_UP:
			inc = Vector2(0, -1)
		EXIT_DOWN:
			inc = Vector2(0, 1)
	return inc

func create_collider(dir, tile_size):
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	var tile_x = tile_size.x / 2
	var tile_y = tile_size.y / 2

	match dir:
		EXIT_TOP:
			collision.position = Vector2(tile_x, tile_y / 2)
			collision.shape.extents = Vector2(tile_x, tile_y / 2)
		EXIT_BOTTOM:
			collision.position = Vector2(tile_x, tile_y / 2 + tile_y)
			collision.shape.extents = Vector2(tile_x, tile_y / 2)
		EXIT_LEFT:
			collision.position = Vector2(tile_x / 2, tile_y)
			collision.shape.extents = Vector2(tile_x / 2, tile_y)
		EXIT_RIGHT:
			collision.position = Vector2(tile_x / 2 + tile_x, tile_y)
			collision.shape.extents = Vector2(tile_x / 2, tile_y)
		EXIT_UP:
			collision.position = Vector2(tile_x, tile_y)
			collision.shape.extents = Vector2(tile_x / 2 , tile_y / 2)
		EXIT_DOWN:
			collision.position = Vector2(tile_x, tile_y)
			collision.shape.extents = Vector2(tile_x / 2, tile_y / 2)

	return collision
