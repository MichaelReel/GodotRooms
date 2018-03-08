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
	var robot_anim = $Robot.get_node("Sprite/AnimationPlayer")
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
					robot_anim.play("move" + direction_string)
					idle = false
		
		var atpos = path[path.size() - 1]
		process_collsion($Robot.move_and_collide(atpos - $Robot.position))
		
		if path.size() < 2:
			stop_moving()

	else:
		set_process(false)

func stop_moving():
	var robot_anim = $Robot.get_node("Sprite/AnimationPlayer")
	path = []
	set_process(false)
	# print("idle" + direction_string)
	robot_anim.play("idle" + direction_string)
	idle = true

func _update_path():
	var collider = $Robot.get_node("CollisionShape2D")
	var p = get_simple_path(begin, end, true)
	
	path = []
	for vert in p:
		var mod_path = vert - collider.position
		path.push_front(mod_path)

	# path = Array(p)
	# path.invert()

	set_process(true)

func _input(event):
	var collider = $Robot.get_node("CollisionShape2D")
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		begin = $Robot.position + collider.position
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
	var room_man = get_node("../RoomManager")
	var cam = $Robot.get_node("Camera2D")
	if collision:
		# TODO: actual collisiony type things. At the minute, only portal behaviour
		var collider = collision.collider
		print (collider)

		if collider is Exit and collider.is_visible_in_tree():
			# This is a collider, move the player sprite and notify the room manager
			stop_moving()
			# cam.smoothing_enabled = false
			room_man.change_room(collider)
			# cam.smoothing_enabled = true

