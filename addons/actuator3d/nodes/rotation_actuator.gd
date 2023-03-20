@icon("res://addons/actuator3d/nodes/rotation_actuator_3d.svg")
## Rotation actuator with two modes : MOTOR and SERVO
class_name RotationActuator3D
extends RigidBody3D

@export_enum("MOTOR", "SERVO") var actuator_type = "MOTOR":
	set(value):
		actuator_type = value
#		print_debug(get_node_or_null("HingeJoint"))
#		if get_node_or_null("HingeJoint"):
#			match actuator_type:
#				"MOTOR":
#					_joint.set("angular_limit_z/enabled", false)
#				"SERVO":
#					print("SERVO")
#					_joint.set("angular_limit_z/enabled", true)
#					_joint.set("angular_limit_z/lower_angle", -180)
#					_joint.set("angular_limit_z/uppers_angle", 180)
					

@export_group("Motor parameters")
## Angular velocity along Z axis in rad/sec
@export var rotation_speed: float = 0.0
@export var motor_gain: float = 1.0 # Couple
@export var motor_damping: float = 0.1 # Frottement visqueux

@export_group("Servo parameters")
## Desired angle value in °
@export_range(-180, 180) var angle: float = 0:
	set(value):
		if angle != value:
			angle = value
			_in_angle = rad_to_deg(current_angle)
			_out_angle = angle
			_step_count = int(profile_duration * Engine.physics_ticks_per_second)
			_step = 0
#			print("in_angle: %f , out_angle: %f , step_count: %d" %[_in_angle, _out_angle, _step_count])
		
		Engine.physics_ticks_per_second
@export var servo_gain: float = 20.0
@export var servo_damping: float = 5.0
@export_exp_easing var angle_profile: float = 1.0
@export_range(0.1, 2, 0.1) var profile_duration: float = 1.0

@export_group("Controller parameters")
@export var controllers: Array[Controller]

var current_velocity: float
var current_angle: float

var _joint: Generic6DOFJoint3D
var _pose_basis_inv: Basis = transform.basis.inverse()
var _in_angle: float
var _out_angle: float
var _step_count: int
var _step: float

func _enter_tree() -> void:
	_joint = Generic6DOFJoint3D.new()
	_joint.name = "HingeJoint"
	_joint.set("angular_limit_z/enabled", false)
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	add_child(_joint)


func _ready() -> void:
	can_sleep = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	match actuator_type:
		"MOTOR":
			current_velocity = (global_transform.inverse().basis * angular_velocity).z
		#	print(current_velocity)
			var err = rotation_speed - current_velocity
			var x: float
			if controllers.is_empty():
				x = err
			else:
				x = err
				for controller in controllers:
					x = controller.process(x)
			var torque_cmd =  motor_gain * x - motor_damping * current_velocity # DC Motor simplify model
			apply_torque(global_transform.basis.z * (torque_cmd))
		"SERVO":
			var basis_not_tranformed = _pose_basis_inv * transform.basis
			current_angle = basis_not_tranformed.get_euler().z
			current_velocity = (global_transform.inverse().basis * angular_velocity).z
			var i: float = _step / _step_count # Value between 0 and 1
			var ease_angle: float
			if i < 1:
#				print("i: ", i)
				_step += 1
				ease_angle = _in_angle + (_out_angle - _in_angle) * ease(i, angle_profile)
#				print("ease angle: ", ease_angle)
			else:
				ease_angle = _out_angle
			var err = deg_to_rad(ease_angle) - current_angle
			var x: float
			if controllers.is_empty():
				x = err
			else:
				x = err
				for controller in controllers:
					x = controller.process(x)
			var torque_cmd = servo_gain * x - servo_damping * current_velocity
#			print("angle: %f , vel: %f , err: %f , cmd: %f" %[rad_to_deg(current_angle), current_velocity, err, torque_cmd])
			apply_torque(global_transform.basis.z * (torque_cmd))
			
