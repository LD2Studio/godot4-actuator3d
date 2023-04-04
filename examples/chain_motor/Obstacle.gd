extends AnimatableBody3D

@export var close: bool = false:
	set(value):
		close = value
		if close:
			position.z = 0.145
		else:
			position.z = -1.1


