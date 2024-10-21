class_name PID
extends RefCounted

var active: bool
var kp: float
var ki: float
var kd: float
var value: float

var _interval_time_msec: int
var _interval_msec: int
var _error_i: float
var _error_i_reset_interval_time_msec: int
var _error_i_reset_interval_msec: int

var error_i: float:
	get():
		return _error_i

func data_set(_interval_msec_: int, _error_i_reset_interval_msec_: int) -> void:
	_interval_msec = _interval_msec_
	_error_i_reset_interval_msec = _error_i_reset_interval_msec_

func process(_dt_: float, _error_: float, _error_d_: float) -> void:
	if not active:
		return
	if Time.get_ticks_msec() - _interval_time_msec < _interval_msec:
		return
	else:
		_interval_time_msec = Time.get_ticks_msec()
	_error_i += _error_
	if Time.get_ticks_msec() - _error_i_reset_interval_time_msec > _error_i_reset_interval_msec:
		_error_i_reset_interval_time_msec = Time.get_ticks_msec()
		_error_i = 0.0
	var p: float = _error_ * kp
	var i: float = _error_i * _dt_ * ki
	var d: float = _error_d_ * _dt_ * kd
	var pid: float = p + i + d
	value = clampf(value + pid, 0.0, 1.0)
