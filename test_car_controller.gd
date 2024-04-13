extends RigidBody3D

@export var raycast_wheels: Array[Node3D]

var current_steering_angle: float = 0
@export var max_steer_angle_radians: float = 0.5
@export var keyboard_steer_speed: float = 0.01
@export var ackermann_wheelbase: float = 2
@export var ackermann_wheel_tread: float = 1.4

@export var max_drive_torque: float = 100
@export var number_of_driving_wheels: int = 2

var throttle_input: float = 0.0
var is_engine_running: bool = true
var engine_ang_vel: float = 100.0 # rad/s
var driveshaft_ang_vel: float
@export var engine_ang_vel_max: float = 733
@export var engine_ang_vel_prev: float = 0
@export var flywheel_moi: float = 0.1 # mass[kg] * ( radius[m] ^ 2 )
@export var clutch_capacity_max_static: float = 120
@export var clutch_capacity_max_dynamic: float = 100
var is_clutch_slipping: bool = false
var clutch_output_torque: float
var current_clutch_capacity: float

@export var max_brake_torque: float = 500
var reset_pos: bool = false

var local_vel: Vector3
var prev_pos: Vector3
var speed: float

signal show_telemetry()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_Z:
			is_clutch_slipping = true
	if event is InputEventKey and event.is_released():
		if event.keycode == KEY_R:
			reset_pos = true

func _process(delta):
	for i in raycast_wheels.size():
		raycast_wheels[i].reset_wheel_mesh_position(delta)
	
	# Caster angle
	raycast_wheels[0].wheel_mesh.rotate(Vector3.RIGHT, 0.2)
	raycast_wheels[1].wheel_mesh.rotate(Vector3.RIGHT, 0.2)
		
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
		
	show_telemetry.emit(
		speed,
		engine_ang_vel,
		driveshaft_ang_vel,
		current_clutch_capacity,
		is_clutch_slipping,
		clutch_output_torque,
		list_ang_vel, 
		list_susp_force, 
		list_planar_vec, 
		list_long_force, 
		list_lat_force)
	
func _physics_process(delta: float) -> void:
	if reset_pos == true:
		reset_pos = false
		position = Vector3(0,1,0)
		rotation = Vector3.ZERO
		linear_velocity = Vector3(0,1,0)
		angular_velocity = Vector3.ZERO
		
	# steering
		
	var steering_target = Input.get_axis("ui_right", "ui_left") * max_steer_angle_radians
	
	if steering_target == 0 && abs(current_steering_angle) < keyboard_steer_speed:
		current_steering_angle = 0
	elif current_steering_angle > steering_target:
		current_steering_angle -= keyboard_steer_speed
	elif current_steering_angle < steering_target:
		current_steering_angle += keyboard_steer_speed
		
	raycast_wheels[0].rotation.y = ackermann_steering(current_steering_angle, ackermann_wheelbase, ackermann_wheel_tread / -2) 
	raycast_wheels[1].rotation.y = ackermann_steering(current_steering_angle, ackermann_wheelbase, ackermann_wheel_tread / 2)
	
	# driving wheels
	
	var gear_ratio: float = 3.7 * 4.0 # gear ratios: 3.7 1.9 1.3 1.0 0.8 -3.2
	var clutch_input: float
	var engine_damping_torque: float = 0.1
	
	if engine_ang_vel < engine_ang_vel_max: throttle_input = Input.get_action_strength("throttle")
	else: throttle_input = 0.0
		
	clutch_input = Input.get_action_strength("clutch")
	
	driveshaft_ang_vel = (raycast_wheels[0].ang_vel + raycast_wheels[1].ang_vel) * 0.5 * gear_ratio
	
	var clutch_capacity_static = clutch_capacity_max_static * (1.0 - clutch_input)
	
	if is_clutch_slipping == true:
		var clutch_capacity_dynamic = clutch_capacity_max_dynamic * (1.0 - clutch_input)
		current_clutch_capacity = clutch_capacity_dynamic
		clutch_output_torque = clutch_capacity_dynamic * sign(engine_ang_vel - driveshaft_ang_vel)
		engine_ang_vel += ((max_drive_torque * throttle_input) - (engine_ang_vel * engine_damping_torque)) / flywheel_moi * delta
		if clutch_capacity_dynamic != 0.0:
			if driveshaft_ang_vel > engine_ang_vel * 0.95 and driveshaft_ang_vel < engine_ang_vel * 1.05 and abs(clutch_output_torque) <= clutch_capacity_static:
				is_clutch_slipping = false
	else:
		current_clutch_capacity = clutch_capacity_max_static
		clutch_output_torque = (max_drive_torque * throttle_input) - (engine_ang_vel * engine_damping_torque)
		clutch_output_torque += (engine_ang_vel_prev - engine_ang_vel) * flywheel_moi
		engine_ang_vel = driveshaft_ang_vel
		if abs(clutch_output_torque) > clutch_capacity_static:
			is_clutch_slipping = true
	
	engine_ang_vel_prev = engine_ang_vel
	
	raycast_wheels[0].drive_torque = clutch_output_torque * gear_ratio / number_of_driving_wheels
	raycast_wheels[1].drive_torque = clutch_output_torque * gear_ratio / number_of_driving_wheels
	
	# applying brakes
	
	var brake_input = Input.get_action_strength("brakes")
	
	for i in raycast_wheels.size():
		raycast_wheels[i].brake_torque = brake_input * max_brake_torque
		raycast_wheels[i].calc_suspension_force(delta)
		raycast_wheels[i].calc_tire_force(delta)
		
	
	local_vel = (global_transform.origin - prev_pos) * global_transform.basis / delta
	prev_pos = global_transform.origin
	speed = local_vel.length()
		
func ackermann_steering(avg_turning_angle, wheelbase, wheel_x_offset): # wheel_x_offset: lateral offset from center
	var turning_radius = wheelbase / (tan(avg_turning_angle) / 2) # Div by 2 because the angle is in radians
	var ackermann_angle = atan2(wheelbase, turning_radius + wheel_x_offset) * 2
	return ackermann_angle
