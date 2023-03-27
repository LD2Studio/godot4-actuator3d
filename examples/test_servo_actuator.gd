extends Node3D

var ang_vel_plot
var t: float
var recording: bool = false

func _ready() -> void:
	ang_vel_plot = %Graph.add_plot("Angle", Color.YELLOW)


func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_accept"):
		ang_vel_plot.clear()
		t = 0
		%Motor.angle = 45
		recording = true
		print("inertia : ", %Motor._inertia_shaft)
		
		
	elif Input.is_action_just_pressed("ui_cancel"):
		%Motor.angle = 0
		recording = false
		
	if recording:
		ang_vel_plot.add_point(Vector2(t, rad_to_deg(%Motor.current_angle)))
		t += delta
#		print("inertia : ", %Motor._inertia_shaft)
