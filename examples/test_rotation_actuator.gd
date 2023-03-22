extends Node3D

var ang_vel_plot
var t: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ang_vel_plot = %AngularVelocityGraph.add_plot("Angular Velocity", Color.GREEN)


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		%Motor.rotation_velocity = 1
#		print("motor on")
		ang_vel_plot.add_point(Vector2(t, %Motor.current_velocity))
		t += delta
	else:
		%Motor.rotation_velocity = 0
		t = 0
		ang_vel_plot.clear()

