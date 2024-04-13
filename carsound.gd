extends Node
@export var car: Node3D
@export var engine_sound_2k_on: AudioStreamPlayer3D
@export var engine_sound_2k_off: AudioStreamPlayer3D
@export var engine_sound_4k_on: AudioStreamPlayer3D
@export var engine_sound_4k_off: AudioStreamPlayer3D
@export var engine_sound_8k_on: AudioStreamPlayer3D
@export var engine_sound_8k_off: AudioStreamPlayer3D
var throttle_input_lerp = 0.0
var engine_ang_vel_lerp = 0.0
@export var mix2k_curve: Curve
@export var mix4k_curve: Curve
@export var mix8k_curve: Curve

# Called when the node enters the scene tree for the first time.
func _ready():
	engine_sound_2k_on.volume_db = -80.0
	engine_sound_2k_off.volume_db = -80.0
	engine_sound_4k_on.volume_db = -80.0
	engine_sound_4k_off.volume_db = -80.0
	engine_sound_8k_on.volume_db = -80.0
	engine_sound_8k_off.volume_db = -80.0
	engine_sound_2k_on.play()
	engine_sound_2k_off.play()
	engine_sound_4k_on.play()
	engine_sound_4k_off.play()
	engine_sound_8k_on.play()
	engine_sound_8k_off.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	engine_ang_vel_lerp = lerp(engine_ang_vel_lerp, car.engine_ang_vel, 0.1)
	
	var pitch_scale_2k = engine_ang_vel_lerp / (2000 * 0.1047)
	engine_sound_2k_on.pitch_scale = pitch_scale_2k
	engine_sound_2k_off.pitch_scale = pitch_scale_2k
	
	var pitch_scale_4k = engine_ang_vel_lerp / (4000 * 0.1047)
	engine_sound_4k_on.pitch_scale = pitch_scale_4k
	engine_sound_4k_off.pitch_scale = pitch_scale_4k
	
	var pitch_scale_8k = engine_ang_vel_lerp / (8000 * 0.1047)
	engine_sound_8k_on.pitch_scale = pitch_scale_8k
	engine_sound_8k_off.pitch_scale = pitch_scale_8k
	
	throttle_input_lerp = lerp(throttle_input_lerp, car.throttle_input, 0.1)
	var mix2k = mix2k_curve.sample(engine_ang_vel_lerp * (1 / 0.1047) / 8000)
	var mix4k = mix4k_curve.sample(engine_ang_vel_lerp * (1 / 0.1047) / 8000)
	var mix8k = mix8k_curve.sample(engine_ang_vel_lerp * (1 / 0.1047) / 8000)
	
	engine_sound_2k_on.volume_db = linear_to_db(mix2k * throttle_input_lerp * 0.8)
	engine_sound_2k_off.volume_db = linear_to_db(mix2k * (1.0 - throttle_input_lerp) * 0.8)
	engine_sound_4k_on.volume_db = linear_to_db(mix4k * throttle_input_lerp)
	engine_sound_4k_off.volume_db = linear_to_db(mix4k * (1.0 - throttle_input_lerp))
	engine_sound_8k_on.volume_db = linear_to_db(mix8k * throttle_input_lerp * 1.2)
	engine_sound_8k_off.volume_db = linear_to_db(mix8k * (1.0 - throttle_input_lerp) * 1.2)
