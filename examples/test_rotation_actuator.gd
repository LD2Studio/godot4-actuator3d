extends Node3D

var ang_vel_plot
var t: float
var recording: bool = false
var oneshot: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ang_vel_plot = %Graph2D.add_plot_item("Angular Velocity", Color.GREEN)


func _physics_process(delta: float) -> void:
	if oneshot:
		%Motor.desired_velocity = 0
		oneshot = false
	if Input.is_action_just_pressed("ui_accept"):
		ang_vel_plot.clear()
		t = 0
		%Motor.desired_velocity = 1
		recording = true
		
	elif Input.is_action_just_pressed("impulse"):
		ang_vel_plot.clear()
		t = 0
		%Motor.desired_velocity = Engine.physics_ticks_per_second
		recording = true
		oneshot = true
		print("inertia : ", %Motor._inertia_shaft)
		
	elif Input.is_action_just_pressed("ui_cancel"):
		%Motor.desired_velocity = 0
		recording = false
		
	if recording:
		ang_vel_plot.add_point(Vector2(t, %Motor.current_velocity))
		t += delta

