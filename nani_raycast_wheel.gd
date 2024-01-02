# Making Custom Car Physics in Unity (for Very Very Valet)
# https://youtu.be/CdPYlj5uZeI?si=_gFNmow1wqenHwa2

# Unity Car Physics - Lesson 1 - Suspension Physics
# https://youtu.be/x0LUiE0dxP0?si=-7FQk-lGQ_rvg8aU

extends RayCast3D

@onready var chassis: RigidBody3D = $'..' # Get the parent RigidBody3D

# Suspension

@export var susp_rest_length: float = 0.1
@export var susp_spring_stiffness: float = 25000
@export var susp_damper_stiffness: float = 1500
var susp_compression_prev: float = 0
var susp_spring_length: float
@export var tire_radius: float = 0.3
var collision_pos_prev: Vector3
var susp_force: float

# Tire

@export var wheel_mass: float = 10
@export var grip_factor: float = 1
var prev_pos: Vector3
var forward_vel: float
var local_vel: Vector3
var planar_vec: Vector2
var long_force: float = 0
var lat_force: float = 0
var ang_vel: float # Angular velocity
var drive_torque: float
var brake_torque: float
var wheel_inertia: float
var rolling_resistance: float = 10

# Rendering

@export var wheel_mesh: Node3D
var wheel_mesh_rotation_spin: float
var wheel_mesh_rotation: Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	susp_spring_length = susp_rest_length
	reset_wheel_mesh_position(0)
	set_target_position(transform.basis.y * -(susp_rest_length + tire_radius))
	prev_pos = global_transform.origin
	wheel_inertia = 0.5 * wheel_mass * pow(tire_radius, 2)

func _process(delta):
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass
		
func calc_suspension_force(delta) -> void:	
	if is_colliding():
		var collision_pos = get_collision_point()
		var actual_length = global_transform.origin.distance_to(collision_pos) - tire_radius
	
		var compression = susp_rest_length - actual_length
		var spring_velocity = (compression - susp_compression_prev) / delta
		var potential_force = compression * susp_spring_stiffness
	
		var damper_force = susp_damper_stiffness * spring_velocity
	
		potential_force += damper_force
		potential_force = max(potential_force, 0)
	
		susp_compression_prev = compression
		susp_spring_length = actual_length
	
		susp_force = potential_force
	
		chassis.apply_force(potential_force * get_collision_normal(), collision_pos - chassis.global_transform.origin)
		# Position arg for apply_force() must be local space value
	else:
		susp_compression_prev = 0
		susp_spring_length = susp_rest_length

		
func calc_tire_force(delta):
	local_vel = (global_transform.origin - prev_pos) * global_transform.basis / delta
	forward_vel = -local_vel.z
	planar_vec = Vector2(local_vel.x, local_vel.z).normalized()
	prev_pos = global_transform.origin
		
	if is_colliding():
		
		# if statements switch tire model to a simpler one when in very low speed
		# to suppress shaking derived from equation divergence
				
		if abs(forward_vel) < 0.1 and abs(local_vel.x) < 0.1:
			lat_force = -local_vel.x / delta * wheel_mass
		else:
			var lat_slip = asin(clamp(-planar_vec.x, -1, 1))
			lat_force = pacejka(susp_force, lat_slip, 1, 10, 0, 1.35)
			
		if abs(forward_vel) < 0.1 and brake_torque > 0:
			long_force = -local_vel.z / delta * wheel_mass
		else:
			var long_slip = (forward_vel - (ang_vel * tire_radius)) / max(abs(forward_vel), 0.0000001)
			long_force = pacejka(susp_force, long_slip, 1, 10, 0, 1.65)
			
		lat_force *= grip_factor
		long_force *= grip_factor
			
		var collision_pos = get_collision_point() - chassis.global_transform.origin
		chassis.apply_force(global_transform.basis.x * lat_force + global_transform.basis.z * long_force, collision_pos)
		
	var net_torque = (long_force * tire_radius) + drive_torque
	if abs(ang_vel) < 5 and brake_torque > abs(net_torque):
		ang_vel = 0
	else:
		net_torque -= (brake_torque + rolling_resistance) * sign(ang_vel)
		ang_vel += delta * net_torque / wheel_inertia
		# ang_vel += delta * net_torque / (wheel_inertia + drive_inertia)
		
func reset_wheel_mesh_position(delta):
	wheel_mesh.position = Vector3(position.x, position.y - susp_spring_length, position.z)
	
	if abs(ang_vel) < 10 and abs(ang_vel) != 0:
		wheel_mesh_rotation_spin += wrapf(-forward_vel / tire_radius * delta, 0, TAU)
	else:
		wheel_mesh_rotation_spin += wrapf(-ang_vel * delta, 0, TAU)
	wheel_mesh_rotation.x = wheel_mesh_rotation_spin
	wheel_mesh_rotation.y = rotation.y
	wheel_mesh_rotation.z = 0
	wheel_mesh.rotation = wheel_mesh_rotation
	
func pacejka(vert_load, slip, peak, stiff, curve, shape):
	return vert_load * peak * sin(shape * atan(stiff * slip - curve * (stiff * slip - atan(stiff * slip))))
