class_name CFriction
extends RefCounted

var _μ: float
var _μ_sqr: float
var _τ_μ_base: float

func _init(_μ_: float, _μ_sqr_: float, _τ_μ_base_: float) -> void:
	_μ = _μ_
	_μ_sqr = _μ_sqr_
	_τ_μ_base = _τ_μ_base_

func τ_μ(_ω_: float) -> float:
	return _τ_μ_base + _μ * _ω_ + _μ_sqr * (_ω_ * 0.1)**2
