class_name Clutch
extends RefCounted

var engage: float
var τ: float

var ω_l: float:
	get():
		return _inertia_l.ω

var ω_r: float:
	get():
		return _inertia_r.ω

var _inertia_l: CInertia
var _friction_l: CFriction
var _inertia_r: CInertia
var _friction_r: CFriction
var _τ_max: float

var inertia_l: CInertia:
	get():
		return _inertia_l

var inertia_r: CInertia:
	get():
		return _inertia_r

var friction_l: CFriction:
	get():
		return _friction_l

var friction_r: CFriction:
	get():
		return _friction_r

func data_set(
	_inertia_l_: CInertia, _friction_l_: CFriction,
	_inertia_r_: CInertia, _friction_r_: CFriction,
	_τ_max_: float
	) -> void:
	_inertia_l = _inertia_l_
	_friction_l = _friction_l_
	_inertia_r = _inertia_r_
	_friction_r = _friction_r_
	_τ_max = _τ_max_

func process(_Δt_: float, _torque_l: CTorque, _torque_r: CTorque) -> void:
	var ω_m: float = (inertia_l.m + inertia_r.m) / (inertia_l.v + inertia_r.v)
	τ = minf(engage * _τ_max, abs(((inertia_l.ω - ω_m) * inertia_l.v) / _Δt_))
	var s: float = signf(_inertia_r.ω - _inertia_l.ω)
	_inertia_l.process(_Δt_, _torque_l.v_static, _torque_l.v_dynamic + s * τ)
	_inertia_r.process(_Δt_, _torque_r.v_static, _torque_r.v_dynamic - s * τ)
