extends Navigation2D

# Member variables
const SPEED = 75.0

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
				if update_anim_string(pto - pfrom) or self.idle:
					print("move" + self.direction_string)
					$Robot.get_node("AnimationPlayer").play("move" + self.direction_string)
					self.idle = false
		
		var atpos = path[path.size() - 1]
		$Robot.position = atpos
		
		if path.size() < 2:
			path = []
			set_process(false)
			print("idle" + self.direction_string)
			$Robot.get_node("AnimationPlayer").play("idle" + self.direction_string)
			self.idle = true

	else:
		set_process(false)

func _update_path():
	var p = self.get_simple_path(begin, end, true)
	path = Array(p)
	path.invert()
	
	# print ("begin: ", begin," -> end: ", end, " path: ", path)

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

	if new_str != self.direction_string:
		self.direction_string = new_str
		return true
	return false