@tool
@icon("res://addons/actuator3d/nodes/translation_actuator_3d.svg")
## Translation actuator
class_name TranslationActuator3D
extends RigidBody3D

@export var moving_distance: float = 0.0:
	set(value):
		if moving_distance != value:
			moving_distance = value
			_in_dist = current_pos_x
			_out_dist = moving_distance
			_step_count = int(profile_duration * Engine.physics_ticks_per_second)
			_step = 0

@export_enum("X","-X","Y","-Y","Z","-Z") var translation_axis = "Z":
	set(value):
		translation_axis = value
		if _joint.is_inside_tree():
			update_limit()
			if Engine.is_editor_hint() or not only_debug:
				draw_help()

@export_exp_easing var angle_profile: float = 1.0
@export_range(0.1, 2, 0.1) var profile_duration: float = 1.0


@export var exclude_nodes_from_collision: bool = true

@export_group("Parameters")
## Coefficient of force (N/m)
@export var force_constant: float = 50
@export var velocity_damping: float = 5
@export_range(5.0, 20.0) var velocity_constant: float = 5.0

@export var max_negative_distance: float = -1.0:
	set(value):
		if value <= 0:
			max_negative_distance = value
			update_limit()

@export var max_positive_distance: float = 1.0:
	set(value):
		if value >= 0:
			max_positive_distance = value
			update_limit()

@export_group("Debug")
@export var helper_size: float = 1.0:
	set(value):
		helper_size = value
		if is_instance_valid(_help_meshinstance):
			_help_meshinstance.scale = Vector3.ONE * helper_size

@export var only_debug: bool = true

@export_group("Controller parameters")
@export var controllers: Array[Controller]

var _joint: Generic6DOFJoint3D
var _pose_position: Vector3 = position
var current_pos_x: float
var _in_dist: float
var _out_dist: float
var _step_count: int
var _step: float
var _servo_pid: PIDController
var _help_meshinstance := MeshInstance3D.new()

func _enter_tree() -> void:
	_joint = Generic6DOFJoint3D.new()
	_joint.name = "LinearJoint"
	_joint.set("linear_limit_x/lower_distance", max_negative_distance)
	_joint.set("linear_limit_x/upper_distance", max_positive_distance)
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	add_child(_joint)
	
	create_servo_pid()

func _ready() -> void:
	can_sleep = false
	current_pos_x = (transform.inverse().basis * (position - _pose_position)).x

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
#	print("linear velocity: ", transform.inverse().basis * linear_velocity)
#	print("local pos x: ", (transform.inverse().basis * (position - _pose_position)).x)
	current_pos_x = (transform.inverse().basis * (position - _pose_position)).x
	var current_velocity = (global_transform.inverse().basis * linear_velocity).x
	var i: float = _step / _step_count # Value between 0 and 1
	var ease_dist: float
	if i < 1:
		_step += 1
		ease_dist = _in_dist + (_out_dist - _in_dist) * ease(i, angle_profile)
	else:
		ease_dist = _out_dist
	var err = ease_dist - current_pos_x
	var x: float = _servo_pid.process(err)
	x -= velocity_constant * current_velocity
	var force = force_constant * x - velocity_damping * current_velocity
#	print("pos: %f , err: %f" % [current_pos_x, err])
	apply_central_force(global_transform.basis.x * force)
	

func update_limit():
	pass
	if get_node_or_null("LinearJoint"):
		_joint.set("linear_limit_x/lower_distance", max_negative_distance)
	if get_node_or_null("LinearJoint"):
		_joint.set("linear_limit_x/upper_distance", max_positive_distance)
	
	
func draw_help():
	pass

func create_servo_pid():
	if _servo_pid != null: return
	_servo_pid = PIDController.new()
	_servo_pid.Kp = 50
	_servo_pid.Ki = 5

func delete_servo_pid():
	if _servo_pid == null: return
#	print("ref pid: ", _servo_pid.get_reference_count())
	_servo_pid.unreference()
#	print("ref pid: ", _servo_pid.get_reference_count())
	_servo_pid = null
