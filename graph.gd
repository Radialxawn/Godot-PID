class_name Graph
extends Control

@export var _line: Line2D

const POINT_COUNT: int = 100

var _line_rect: Rect2
var _index__line: Dictionary[int, Line2D]
var _line__ys: Dictionary[Line2D, Array]

func initialize() -> void:
	_line_rect = Rect2((_line.get_point_position(0) + _line.get_point_position(1)) * 0.5, _line.get_point_position(1) - _line.get_point_position(0))
	for i in POINT_COUNT:
		var p := Vector2(_x_at_index(i), _y_at_value(0.0))
		if _line.get_point_count() <= i:
			_line.add_point(p)
		else:
			_line.set_point_position(i, p)
	_new_line(0)

func _new_line(_index_: int) -> void:
	var line: Line2D
	if _index_ != 0:
		line = _line.duplicate()
		add_child.call_deferred(line)
	else:
		line = _line
	_index__line[_index_] = line
	var ys: Array[float] = []
	ys.resize(POINT_COUNT)
	_line__ys[line] = ys

func update_dynamic(_index_: int, _y_: float) -> void:
	if not _index__line.has(_index_):
		_new_line(_index_)
	var line: Line2D = _index__line[_index_]
	var ys: Array = _line__ys[line]
	ys.pop_front()
	ys.append(_y_)
	for i in POINT_COUNT:
		var p := Vector2(_x_at_index(i), _y_at_value(ys[i]))
		line.set_point_position(i, p)

func update_static(_index_: int, _x_: float, _y_: float) -> void:
	if not _index__line.has(_index_):
		_new_line(_index_)
	var line: Line2D = _index__line[_index_]
	var p := Vector2(_x_at_value(_x_), _y_at_value(_y_))
	line.set_point_position(roundi(_x_ * POINT_COUNT), p)

func set_color(_index_: int, _color_: Color) -> void:
	if not _index__line.has(_index_):
		_new_line(_index_)
	var line: Line2D = _index__line[_index_]
	line.default_color = _color_

func _x_at_index(_index_: int) -> float:
	var c: Vector2 = _line_rect.position
	var s: Vector2 = _line_rect.size
	return c.x + (((_index_ + 0.5) - POINT_COUNT * 0.5) * s.x) / POINT_COUNT

func _x_at_value(_value_: float) -> float:
	var c: Vector2 = _line_rect.position
	var s: Vector2 = _line_rect.size
	return c.x - s.x * 0.5 + _value_ * s.x

func _y_at_value(_value_: float) -> float:
	var c: Vector2 = _line_rect.position
	var s: Vector2 = _line_rect.size
	return c.y + s.y * 0.5 - _value_ * s.y
