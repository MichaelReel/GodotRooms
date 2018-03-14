extends Camera2D

var robot_cam

var time_out
var tot_time

# func _ready():
# 	set_process(false)

func setup_transition(out_dir, main_cam, total_time = 2.0):
	robot_cam = main_cam

	# Set this sprites position to exit
	position = robot_cam.get_camera_screen_center()
	make_current()

	# Give a second or so
	tot_time = total_time
	time_out = total_time

	set_process(true)

func _process(delta):
	time_out -= delta

	robot_cam.align()
	robot_cam.reset_smoothing()

	if time_out <= tot_time / 2:
		position = robot_cam.get_camera_screen_center()

	if time_out <= 0:
		robot_cam.make_current()
		set_process(false)


