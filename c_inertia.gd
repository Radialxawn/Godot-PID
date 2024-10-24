class_name CInertia
extends RefCounted

var v: float:
	get():
		return _v
var ω: float:
	get():
		return _ω

var e: float:
	get():
		return 0.5 * v * ω**2

var m: float:
	get():
		return v * ω

var _v: float
var _ω: float
var _usec: int

func _init(_v_: float) -> void:
	_v = _v_

func process(_Δt_: float, _usec_: int, _τ_static_: float, _τ_dynamic_: float) -> void:
	_Δt_ = minf((_usec_ - _usec) * 1e-6, _Δt_)
	_usec = _usec_
	var Δω_static: float = (_τ_static_ / _v) * _Δt_
	var Δω_dynamic: float = (_τ_dynamic_ / _v) * _Δt_
	_ω = signf(_ω) * max(abs(_ω) - Δω_static, 0.0)
	_ω += Δω_dynamic
