@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	
	var curve = -2
	
	for i in range(0,10):
		var x = float(i)/10
		var y = ease(x, curve)
		print("x: %f , y: %f" % [x, y])
