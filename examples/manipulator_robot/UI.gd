extends Control

func _on_q_0_slider_drag_ended(value_changed):
	if value_changed:
		%MotorBase.target_angle = %q0Slider.value

func _on_q_1_slider_drag_ended(value_changed):
	if value_changed:
		%Actuator1.target_angle = %q1Slider.value

func _on_q_2_slider_drag_ended(value_changed):
	if value_changed:
		%Actuator2.target_angle = %q2Slider.value

func _on_q_3_slider_drag_ended(value_changed):
	if value_changed:
		%Actuator3.target_angle = %q3Slider.value
