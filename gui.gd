extends Control

@export var labels : Array[Node]
var count: int = 0
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			visible = !visible
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	count += 1

func _on_show_telemetry(
		ang_vel: Array,
		susp_force: Array,
		planar_vec: Array,
		tire_force_fwd: Array,
		tire_force_right: Array,
		steer_ang: Array,
		drive_torque: Array):

	if count == 5:
		count = 0
		for i in labels.size():
			labels[i].set_text(
			"\nAng vel = %1.1f" % ang_vel[i] +
			"\nSusp force = %1.1f" % susp_force[i] +
			"\nLocal vel unit vec X, Z = %1.2f, " % planar_vec[i].x +
			"%1.2f" % planar_vec[i].y +
			"\nTire force X, Z = %1.1f, " % tire_force_right[i] +
			"%1.1f" % tire_force_right[i] +
			"\nSteer ang = %1.2f" % steer_ang[i] +
			"\nDrive torque = %1.1f" % drive_torque[i])
