class_name CombustionEngine
extends RefCounted

var active: bool
var throttle: float
var τ_load_static: float
var τ_load_dynamic: float
var τ_starter: float

var _inertia: float
var _ω: float
var _ω_max: float
var _τ_combustion_max: float
var _μ: float
var _μ_sqr: float
var _τ_vacuum_max: float
var _τ_load_max: float

var ω: float:
	get():
		return _ω

var τ_load_max: float:
	get():
		return _τ_load_max

var power_load: float:
	get():
		return _ω * τ_load()

func data_set(_inertia_: float, _τ_load_max_: float, _τ_vacuum_max_: float, _ω_max_: float, _μ_: float, _μ_sqr_: float) -> void:
	_inertia = _inertia_
	_τ_load_max = _τ_load_max_
	_τ_vacuum_max = _τ_vacuum_max_
	_ω_max = _ω_max_
	_μ = _μ_
	_μ_sqr = _μ_sqr_
	_τ_combustion_max = _τ_μ(_ω_max_) + _τ_load_max_

func process(_Δt_: float) -> void:
	if not active:
		return
	var τ_combustion: float = _τ_combustion_max * throttle * clampf(_ω / _ω_max, 0.0, 1.0)
	var τ_net_dynamic: float = τ_combustion + τ_load_dynamic + τ_starter
	var Δω_dynamic: float = (τ_net_dynamic / _inertia) * _Δt_
	var τ_net_static: float = _τ_vacuum_max * (1.0 - throttle) + abs(τ_load_static) + _τ_μ(_ω)
	var Δω_static: float = (τ_net_static / _inertia) * _Δt_
	_ω = signf(_ω) * max(abs(_ω) - Δω_static, 0.0)
	_ω += Δω_dynamic

func _τ_μ(_ω_: float) -> float:
	return _μ * _ω_ + _μ_sqr * (_ω_**2)

func τ_load() -> float:
	return clampf(_ω * 1e2, 0.0, 1.0) * τ_load_static + τ_load_dynamic

static func rpm_to_omega(_rpm_: float) -> float:
	return _rpm_ * PI / 30.0

static func omega_to_rpm(_omega_: float) -> float:
	return _omega_ * 30.0 / PI
