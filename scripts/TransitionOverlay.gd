extends Sprite

const solid_time = 1.0
const fade_time = 2.0

var solid_var
var fade_var
var cam_node

func setup_transition():
	cam_node = get_node("..")

	# Take a screenshot of the current scene
	var viewport = get_tree().get_root()
	var screenshot = ImageTexture.new()
	screenshot.create_from_image(viewport.get_texture().get_data())

	# Set the texure
	set_texture(screenshot)
	scale = cam_node.zoom
	visible = true

	# Start the fade process
	solid_var = solid_time
	fade_var = fade_time
	set_process(true)

func _process(delta):
	# Work through the solid time
	solid_var -= delta
	if solid_var <= 0.0:
		# Solid time up, fade time now
		fade_var += solid_var
		solid_var = 0.0

	# Set the fading alpha value
	var alpha = fade_var / fade_time
	modulate = Color(1.0, 1.0, 1.0, alpha)

	if fade_var <= 0.0:
		visible = false
		set_process(false)


