extends HBoxContainer

func _on_q_slider_value_changed(value):
	$qValue.text = "%.2f" % [value]
