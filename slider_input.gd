class_name SliderInput
extends Control

@export var _slider: Slider
@export var _value_label: Label

var _value: float
var _factor: float
var _factor_view: float

var value: float:
	get():
		return _value
	set(_value_):
		_slider.value = _value_ / _factor

func initialize(_format_: String, _factor_: float, _factor_view_: float = INF) -> void:
	_factor = _factor_
	_factor_view = _factor_
	if _factor_view_ != INF:
		_factor_view = _factor_view_
	_slider.value_changed.connect(func(__value__: float) -> void:
		_value = __value__ * _factor
		_value_label.text = _format_ % (__value__ * _factor_view)
		)
	_slider.value_changed.emit(_slider.value)
