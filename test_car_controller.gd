extends RigidBody3D

@export var raycast_wheels: Array[Node3D]

var current_steering_angle: float = 0
@export var max_steer_angle_radians: float = 0.5
@export var keyboard_steer_speed: float = 0.01
@export var ackermann_wheelbase: float = 2
@export var ackermann_wheel_tread: float = 1.4

@export var max_drive_torque: float = 600
@export var number_of_driving_wheels: int = 2

@export var max_brake_torque: float = 500
var reset_pos: bool = false

signal show_telemetry()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			reset_pos = true

func _process(delta):
	for i in raycast_wheels.size():
		raycast_wheels[i].reset_wheel_mesh_position(delta)
	
	# Caster angle
	raycast_wheels[0].wheel_mesh.rotate(Vector3.RIGHT, 0.2)
	raycast_wheels[1].wheel_mesh.rotate(Vector3.RIGHT, 0.2)
	
	#_on_show_telemetry(
		#ang_vel: Array,
		#susp_force: Array,
		#tire_force_fwd: Array,
		#tire_force_right: Array,
		#steer_ang: Array,
		#drive_torque: Array)
		
	var list_ang_vel = [
		raycast_wheels[0].ang_vel,
		raycast_wheels[1].ang_vel,
		raycast_wheels[2].ang_vel,
		raycast_wheels[3].ang_vel]
		
	var list_susp_force = [
		raycast_wheels[0].susp_force,
		raycast_wheels[1].susp_force,
		raycast_wheels[2].susp_force,
		raycast_wheels[3].susp_force]
		
	var list_planar_vec = [
		raycast_wheels[0].planar_vec,
		raycast_wheels[1].planar_vec,
		raycast_wheels[2].planar_vec,
		raycast_wheels[3].planar_vec]
		
	var list_long_force = [
		raycast_wheels[0].long_force,
		raycast_wheels[1].long_force,
		raycast_wheels[2].long_force,
		raycast_wheels[3].long_force]
		
	var list_lat_force = [
		raycast_wheels[0].lat_force,
		raycast_wheels[1].lat_force,
		raycast_wheels[2].lat_force,
		raycast_wheels[3].lat_force]
		
	var list_rot_y = [
		raycast_wheels[0].rotation.y,
		raycast_wheels[1].rotation.y,
		raycast_wheels[2].rotation.y,
		raycast_wheels[3].rotation.y]
		
	var list_drive_torque = [
		raycast_wheels[0].drive_torque,
		raycast_wheels[1].drive_torque,
		raycast_wheels[2].drive_torque,
		raycast_wheels[3].drive_torque]
		
	show_telemetry.emit(
		list_ang_vel, 
		list_susp_force, 
		list_planar_vec, 
		list_long_force, 
		list_lat_force, 
		list_rot_y, 
		list_drive_torque)
	
func _physics_process(delta: float) -> void:
	if reset_pos == true:
		reset_pos = false
		position = Vector3(0,1,0)
		rotation = Vector3.ZERO
		linear_velocity = Vector3(0,1,0)
		angular_velocity = Vector3.ZERO
		
	var steering_target = Input.get_axis("ui_right", "ui_left") * max_steer_angle_radians
	
	if steering_target == 0 && abs(current_steering_angle) < keyboard_steer_speed:
		current_steering_angle = 0
	elif current_steering_angle > steering_target:
		current_steering_angle -= keyboard_steer_speed
	elif current_steering_angle < steering_target:
		current_steering_angle += keyboard_steer_speed
		
	raycast_wheels[0].rotation.y = ackermann_steering(current_steering_angle, ackermann_wheelbase, ackermann_wheel_tread / -2) 
	raycast_wheels[1].rotation.y = ackermann_steering(current_steering_angle, ackermann_wheelbase, ackermann_wheel_tread / 2)
	
	var drive_input = Input.get_action_strength("ui_up")
	var brake_input = Input.get_action_strength("ui_down")
	
	if max(abs(raycast_wheels[0].ang_vel), abs(raycast_wheels[1].ang_vel)) > 700:
		raycast_wheels[0].drive_torque = 0
		raycast_wheels[1].drive_torque = 0
	else:
		raycast_wheels[0].drive_torque = max_drive_torque / number_of_driving_wheels * drive_input
		raycast_wheels[1].drive_torque = max_drive_torque / number_of_driving_wheels * drive_input
		
	for i in raycast_wheels.size():
		raycast_wheels[i].brake_torque = brake_input * max_brake_torque
		raycast_wheels[i].calc_suspension_force(delta)
		raycast_wheels[i].calc_tire_force(delta)
		
func ackermann_steering(avg_turning_angle, wheelbase, wheel_x_offset): # wheel_x_offset: lateral offset from center
	var turning_radius = wheelbase / (tan(avg_turning_angle) / 2) # Div by 2 because the angle is in radians
	var ackermann_angle = atan2(wheelbase, turning_radius + wheel_x_offset) * 2
	return ackermann_angle
