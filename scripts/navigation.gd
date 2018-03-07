extends Navigation2D

# Member variables
const SPEED = 75.0

var Exit = load("res://scripts/Exit.gd")

var begin = Vector2()
var end = Vector2()
var path = []

var direction_string = "_down"
var idle = true

func _process(delta):
	if path.size() > 1:
		var to_walk = delta * SPEED
		while to_walk > 0 and path.size() >= 2:
			var pfrom = path[path.size() - 1]
			var pto = path[path.size() - 2]
			var d = pfrom.distance_to(pto)
			if d <= to_walk:
				path.remove(path.size() - 1)
				to_walk -= d
			else:
				path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
				to_walk = 0
				if update_anim_string(pto - pfrom) or idle:
					# print("move" + direction_string)
					$Robot.get_node("Sprite/AnimationPlayer").play("move" + direction_string)
					idle = false
		
		var atpos = path[path.size() - 1]
		process_collsion($Robot.move_and_collide(atpos - $Robot.position))
		
		if path.size() < 2:
			stop_moving()

	else:
		set_process(false)

func stop_moving():
	path = []
	set_process(false)
	# print("idle" + direction_string)
	$Robot.get_node("Sprite/AnimationPlayer").play("idle" + direction_string)
	idle = true

func _update_path():
	var p = get_simple_path(begin, end, true)
	path = Array(p)
	path.invert()
	set_process(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		begin = $Robot.position
		# Mouse to local navigation coordinates
		end = get_global_mouse_position() - position
		_update_path()

func update_anim_string(vec):
	var new_str = ""
	var normal = vec.normalized()

	# This might need some tweaking:
	var threshold = 0.414

	if normal.y < -threshold:
		new_str += "_up"
	if normal.y > threshold:
		new_str += "_down"
	if normal.x < -threshold:
		new_str += "_left"
	if normal.x > threshold:
		new_str += "_right"

	if new_str != direction_string:
		direction_string = new_str
		return true
	return false

func process_collsion(collision):
	if collision:
		# TODO: actual collisiony type things. At the minute, only portal behaviour
		var collider = collision.collider
		print (collider)

		if collider is Exit and collider.is_visible_in_tree():
			# This is a collider, move the player sprite and notify the room manager
			stop_moving()
			get_node("../RoomManager").change_room(collider)

