class_name Graph
extends Control

@export var _line: Line2D

const POINT_COUNT: int = 100

var _line_rect: Rect2
var _ys: Array[float]

func initialize() -> void:
	_line_rect = Rect2((_line.get_point_position(0) + _line.get_point_position(1)) * 0.5, _line.get_point_position(1) - _line.get_point_position(0))
	for i in POINT_COUNT:
		var p := Vector2(_x_at_index(i), _y_at_value(0.0))
		if _line.get_point_count() <= i:
			_line.add_point(p)
		else:
			_line.set_point_position(i, p)
		_ys.append(0.0)

func update(_y_: float) -> void:
	_ys.pop_front()
	_ys.append(_y_)
	for i in _line.get_point_count():
		var p := Vector2(_x_at_index(i), _y_at_value(_ys[i]))
		_line.set_point_position(i, p)

func _x_at_index(_index_: int) -> float:
	var c: Vector2 = _line_rect.position
	var s: Vector2 = _line_rect.size
	return c.x + (((_index_ + 0.5) - POINT_COUNT * 0.5) * s.x) / POINT_COUNT

func _y_at_value(_value_: float) -> float:
	var c: Vector2 = _line_rect.position
	var s: Vector2 = _line_rect.size
	return c.y + s.y * 0.5 - _value_ * s.y
