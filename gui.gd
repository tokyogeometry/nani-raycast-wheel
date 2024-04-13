extends Control

@export var labels : Array[Node]
var count: int = 0

@export var label2: Label
	
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
		speed: float,
		eng_ang_vel: float,
		driveshaft_ang_vel: float,
		clutch_capacity: float,
		is_clutch_slipping: bool,
		clutch_output_torque: float,
		ang_vel: Array,
		susp_force: Array,
		planar_vec: Array,
		tire_force_fwd: Array,
		tire_force_right: Array):

	if count == 6:
		count = 0
		
		var speed_kmph = speed * 3.6
		
		label2.set_text("Speed (kmph) = %1.0f" % speed_kmph +
			"\nEngine ang vel (rad/s) = %1.1f" % eng_ang_vel +
			"\nDriveshaft ang vel (rad/s) = %1.1f" % driveshaft_ang_vel +
			"\nIs clutch slipping = " + str(is_clutch_slipping) +
			"\nCurr clutch capacity = %1.1f" % clutch_capacity +
			"\nClutch output tor = %1.1f" % clutch_output_torque)
		
		for i in labels.size():
			labels[i].set_text(
			"\nAng vel = %1.1f" % ang_vel[i] +
			"\nSusp force = %1.1f" % susp_force[i] +
			"\nLocal vel unit vec X, Z = %1.2f, " % planar_vec[i].x +
			"%1.2f" % planar_vec[i].y +
			"\nTire force X, Z = %1.1f, " % tire_force_right[i] +
			"%1.1f" % tire_force_fwd[i])
