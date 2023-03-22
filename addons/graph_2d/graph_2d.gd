@tool
@icon("res://addons/graph_2d/graph_2d.svg")
extends Control
class_name Graph2D

## background color of graph
@export var background_color = Color.BLACK:
	set(value):
		background_color = value
		if get_node_or_null("Background"):
			get_node("Background").color = background_color

@export_group("X Axis")
## Minimun value on X-axis
@export var x_min: float = 0.0:
	set(value):
		x_min = value
		update_graph()
## Maximum value on X-axis
@export var x_max: float = 10.0:
	set(value):
		x_max = value
		update_graph()
## Number of graduations on the X-axis
@export var x_grad_num: int = 11:
	set(value):
		x_grad_num = value
		update_graph()
## X-axis label
@export var x_label: String = "":
	set(value):
		x_label = value
		update_graph()
		
@export_group("Y Axis")
## Minimun value on Y-axis
@export var y_min = 0.0:
	set(value):
		y_min = value
		update_graph()
## Maximum value on Y-axis
@export var y_max = 1.0:
	set(value):
		y_max = value
		update_graph()
## Number of graduations on the Y-axis
@export var y_grad_num = 7:
	set(value):
		y_grad_num = value
		update_graph()
## Y-axis label
@export var y_label: String = ""
		
@export_group("Grid")
## Grid visibility
@export var grid_horizontal_visible = false:
	set(value):
		grid_horizontal_visible = value
		update_graph()

@export var grid_vertical_visible = false:
	set(value):
		grid_vertical_visible = value
		update_graph()

const MARGIN_TOP = 30
const MARGIN_BOTTOM = 30
const MARGIN_LEFT = 45
const MARGIN_RIGHT = 30

const Graph2DAxis = preload("res://addons/graph_2d/custom_nodes/axis.gd")
const Graph2DCoord = preload("res://addons/graph_2d/custom_nodes/coordinate.gd")
const Graph2DGrid = preload("res://addons/graph_2d/custom_nodes/grid.gd")
const Graph2DLegend = preload("res://addons/graph_2d/custom_nodes/legend.gd")

var plot_list: Array
var active_plot: Plot

class Plot:
	var curve: LinePlot
	var points: PackedVector2Array
	var graph: Graph2D
	var label: String
	
	func _init(obj, l, c, w):
		curve = LinePlot.new()
		graph = obj
		label = l
		curve.name = l
		curve.color = c
		curve.width = w
		graph.get_node("PlotArea").add_child(curve)
		
	func add_point(pt: Vector2):
		points.append(pt)
		var point = pt.clamp(Vector2(graph.x_min, graph.y_min), Vector2(graph.x_max, graph.y_max))
		var pt_px: Vector2
		pt_px.x = remap(point.x, graph.x_min, graph.x_max, 0, graph.get_node("PlotArea").size.x)
		pt_px.y = remap(point.y, graph.y_min, graph.y_max, graph.get_node("PlotArea").size.y, 0)
		curve.points_px.append(pt_px)
		curve.queue_redraw()
		
	func clear():
		points.clear()
		curve.points_px.clear()
		curve.queue_redraw()
	
	func redraw():
		curve.points_px.clear()
		for pt in points:
			var point = pt.clamp(Vector2(graph.x_min, graph.y_min), Vector2(graph.x_max, graph.y_max))
			var pt_px: Vector2
			pt_px.x = remap(point.x, graph.x_min, graph.x_max, 0, graph.get_node("PlotArea").size.x)
			pt_px.y = remap(point.y, graph.y_min, graph.y_max, graph.get_node("PlotArea").size.y, 0)
			curve.points_px.append(pt_px)
		curve.queue_redraw()
		
	func count() -> int:
		return points.size()

func _ready():
	var background = ColorRect.new()
	background.name = "Background"
	background.color = background_color
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)
	
	var plot_area = Control.new()
	
	plot_area.name = "PlotArea"
	plot_area.anchor_right = 1.0
	plot_area.anchor_bottom = 1.0
	plot_area.offset_left = MARGIN_LEFT
	plot_area.offset_top = MARGIN_TOP
	plot_area.offset_right = -MARGIN_RIGHT
	plot_area.offset_bottom = -MARGIN_BOTTOM
	add_child(plot_area)
	
	var axis = Graph2DAxis.new()
	add_child(axis)
	
	var grid = Graph2DGrid.new()
	add_child(grid)
	
	var legend = Graph2DLegend.new()
	plot_area.add_child(legend)
	
	var coordinate = Graph2DCoord.new()
	plot_area.add_child(coordinate)
	
	resized.connect(_on_Graph_resized)
	plot_area.resized.connect(_on_plot_area_resized)

	move_child(grid, 0)
	move_child(axis, 0)
	move_child(plot_area, 0)
	move_child(background, 0)
	
	update_graph()

func _input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		var plot_rect: Rect2 = Rect2(Vector2.ZERO, get_node("PlotArea").size)
#		print("plot rect: ", plot_rect)
#		print(get_node("PlotArea").get_local_mouse_position())
		if plot_rect.has_point(get_node("PlotArea").get_local_mouse_position()):
			var pos: Vector2i = get_node("PlotArea").get_local_mouse_position()
			var point = pixel_to_coordinate(pos)
			get_node("PlotArea/Coordinate").text = "(%.3f, %.3f)" % [point.x, point.y]
						
#			var points = Array(active_plot.points)
#			var times = points.map(func(pt): return pt.x)
##			print("times: ", times)
#			var diff = times.map(func(t): return abs(t - point.x))
##			print(diff)
#			var min_pt = diff.min()
##			print(min_pt)
#			var idx = diff.find(min_pt)
##			print("idx: ", idx)
#			if idx != -1:
##				print("t=", times[idx])
#				print("pt: ", points[idx])

## Add plot in Graph2D and return an instance of plot
func add_plot(label = "untitled", color = Color.WHITE, width = 1.0) -> Plot:
	var plot = Plot.new(self, label, color, width)
	plot_list.append(plot)
	update_legend()
	active_plot = plot
	return plot

func remove_plot(plot: Plot):
	# remove from plot_list
	var new_plot_list = plot_list.filter(func(p): return p!=plot)
	plot_list = new_plot_list
	plot.clear()
	plot.curve.queue_free()
	# unreference plot object
	plot.unreference()
	update_legend()

func pixel_to_coordinate(px: Vector2i) -> Vector2:
	var point: Vector2
	point.x = remap(px.x, 0, get_node("PlotArea").size.x, x_min, x_max)
	point.y = remap(px.y, 0, get_node("PlotArea").size.y, y_max, y_min)
	return point

func update_graph() -> void:
	if get_node_or_null("Axis") == null: return
	if get_node_or_null("Grid") == null: return
	if get_node_or_null("PlotArea") == null: return
	
	# Update margins depend of axis labels
	get_node("Axis").x_label = x_label
	get_node("Axis").y_label = y_label
	var margin_left: float = MARGIN_LEFT if get_node("Axis").y_label == "" else MARGIN_LEFT + 20
	var margin_bottom: float = MARGIN_BOTTOM if get_node("Axis").x_label == "" else MARGIN_BOTTOM + 20
	
	get_node("PlotArea").offset_left = margin_left
	get_node("PlotArea").offset_bottom = -margin_bottom
	
	# Vertical Graduation
	var y_axis_range: float = y_max - y_min
	var vert_grad_number = y_grad_num
	# Horizontal Graduation
	var x_axis_range: float = x_max - x_min
	var hor_grad_number = x_grad_num
	# Plot area height in pixel
	var area_height = size.y - MARGIN_TOP - margin_bottom
	var vert_grad_step_px = area_height / (vert_grad_number - 1)
	# Plot area width in pixel
	var area_width = size.x - margin_left - MARGIN_RIGHT
	var hor_grad_step_px = area_width / (hor_grad_number -1)
	
	var vert_grad: Array
	var hor_grid: Array
	var grad_px: Vector2
	grad_px.x = margin_left
	
	for n in range(vert_grad_number):
		var grad: Array = []
		grad_px.y = MARGIN_TOP + n * vert_grad_step_px
		grad.append(grad_px)
		var grad_text = "%0.1f" % (float(y_max) - n * float(y_axis_range)/(vert_grad_number-1))
		grad.append(grad_text)
		vert_grad.append(grad)
		
		# Horizontal grid
		if grid_horizontal_visible:
			var grid_px: PackedVector2Array
			grid_px.append(grad_px)
			grid_px.append(Vector2(grad_px.x + area_width, grad_px.y))
			hor_grid.append(grid_px)
			
	get_node("Axis").vert_grad = vert_grad
	
	if grid_horizontal_visible:
		get_node("Grid").hor_grid = hor_grid
	else:
		get_node("Grid").hor_grid = []
		
	var hor_grad: Array
	var vert_grid: Array
	grad_px = Vector2()
	grad_px.y = MARGIN_TOP + area_height
	
	for n in range(hor_grad_number):
		var grad: Array = []
		grad_px.x = margin_left + n * hor_grad_step_px
		grad.append(grad_px)
		var grad_text = "%0.1f" % (float(x_min) + n * float(x_axis_range)/(hor_grad_number-1))
		grad.append(grad_text)
		hor_grad.append(grad)
		
		# Vertical grid
		if grid_vertical_visible:
			var grid_px: PackedVector2Array
			grid_px.append(grad_px)
			grid_px.append(Vector2(grad_px.x, grad_px.y - area_height))
			vert_grid.append(grid_px)
		
	get_node("Axis").hor_grad = hor_grad
	
	if grid_vertical_visible:
		get_node("Grid").vert_grid = vert_grid
	else:
		get_node("Grid").vert_grid = []
	
	get_node("Axis").queue_redraw()
	get_node("Grid").queue_redraw()
	
func update_plots():
	for plot in plot_list:
		plot.redraw()

func update_legend() -> void:
	# Add labels to the legend
	var labels = Array()
	for p in plot_list:
		labels.append({
			name = p.label,
			color = p.curve.color,
		})
	get_node("PlotArea/Legend").update(labels)

func _on_Graph_resized() -> void:
	update_graph()
	
func _on_plot_area_resized() -> void:
	update_plots()
