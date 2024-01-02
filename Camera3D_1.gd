extends Camera3D

@export var offset: Vector3 = Vector3(0, 2.5, 6)
@export var car: Node3D
@export_enum("Dolly Track", "Fix Pos + Y Rot", "Fix Pos + Full Rot") var mode: int
@export var additional_rot: Vector3 = Vector3(0, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match mode:
		0:
			position = car.global_position + offset
		1:
			position = car.global_position + Vector3(car.global_transform.basis.z.x, 0, car.global_transform.basis.z.z).normalized() * offset.z
			position.y = position.y + offset.y
			rotation.y = car.global_rotation.y
		2:
			position = car.global_position + car.global_transform.basis * offset
			rotation = car.global_rotation
			rotate(car.global_transform.basis.x, additional_rot.x)
			rotate(car.global_transform.basis.y, additional_rot.y)
			rotate(car.global_transform.basis.z, additional_rot.z)
