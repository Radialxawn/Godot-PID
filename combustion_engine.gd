class_name CombustionEngine
extends RefCounted

var active: bool
var throttle: float
var τ_starter: float

var _inertia: CInertia
var _friction: CFriction
var _torque: CTorque
var _τ_combustion_curve: Curve
var _τ_combustion_curve_factor: Vector2
var _τ_load_max: float
var _ω_idle_peak_max: Vector3
var _τ_idle_peak: Vector2
var _τ_peak_at_ω: Array[float]
var _w_peak_at_ω_and_τ: Array[float]

var ω: float:
	get():
		return _inertia.ω

var τ_peak: float:
	get():
		return _τ_peak_at_ω[0]

var τ_at_w_peak: float:
	get():
		return _w_peak_at_ω_and_τ[2]

var w_peak: float:
	get():
		return _w_peak_at_ω_and_τ[0]

var τ_combustion_curve: Curve:
	get():
		return _τ_combustion_curve

var inertia: CInertia:
	get():
		return _inertia

var friction: CFriction:
	get():
		return _friction

var torque: CTorque:
	get():
		if not active:
			return _torque.data_set(0.0, 0.0)
		var τ_combustion: float = _τ_combustion_curve.sample(_inertia.ω * _τ_combustion_curve_factor.x) * _τ_combustion_curve_factor.y * throttle
		var τ_net_static: float = _friction.τ_μ(_inertia.ω)
		var τ_net_dynamic: float = τ_combustion + τ_starter
		return _torque.data_set(τ_net_static, τ_net_dynamic)

func data_set(_inertia_: CInertia, _friction_: CFriction, _rpm_idle_peak_max_: Vector3, _τ_idle_peak_: Vector2, _bias_: Vector2) -> void:
	_inertia = _inertia_
	_friction = _friction_
	_torque = CTorque.new()
	_ω_idle_peak_max = Vector3(
		rpm_to_omega(_rpm_idle_peak_max_[0]),
		rpm_to_omega(_rpm_idle_peak_max_[1]),
		rpm_to_omega(_rpm_idle_peak_max_[2])
		)
	_τ_idle_peak = Vector2(
		_τ_idle_peak_[0] + _friction.τ_μ(_ω_idle_peak_max[0]),
		_τ_idle_peak_[1] + _friction.τ_μ(_ω_idle_peak_max[1])
		)
	_τ_combustion_curve = Curve.new()
	_τ_combustion_curve_factor.x = 1.0 / max(_ω_idle_peak_max[0], _ω_idle_peak_max[1], _ω_idle_peak_max[2])
	_τ_combustion_curve_factor.y = max(_τ_idle_peak[0], _τ_idle_peak[1])
	_τ_combustion_curve.add_point(Vector2(0.0, 0.0))
	_τ_combustion_curve.add_point(Vector2(_ω_idle_peak_max[0] * _τ_combustion_curve_factor.x, _τ_idle_peak[0] / _τ_combustion_curve_factor.y))
	_τ_combustion_curve.add_point(Vector2(_ω_idle_peak_max[1] * _τ_combustion_curve_factor.x, _τ_idle_peak[1] / _τ_combustion_curve_factor.y))
	_τ_combustion_curve.add_point(Vector2(_ω_idle_peak_max[2] * _τ_combustion_curve_factor.x, 0.0))
	_τ_combustion_curve.set_point_right_tangent(1, _bias_[0])
	_τ_combustion_curve.set_point_left_tangent(2, _bias_[1])
	_τ_peak_at_ω = [0.0, 0.0]
	_w_peak_at_ω_and_τ = [0.0, 0.0, 0.0]
	for i in 100:
		var t: float = float(i) / 100.0
		var t_τ: float = (_τ_combustion_curve.sample(t) - τ_μ_normalized(t)) * _τ_combustion_curve_factor.y
		var t_ω: float = t * _ω_idle_peak_max[2]
		if t_τ > _τ_peak_at_ω[0]:
			_τ_peak_at_ω[0] = t_τ
			_τ_peak_at_ω[1] = omega_to_rpm(t_ω)
		var w: float = t_τ * t_ω
		if w > _w_peak_at_ω_and_τ[0]:
			_w_peak_at_ω_and_τ[0] = w
			_w_peak_at_ω_and_τ[1] = omega_to_rpm(t_ω)
			_w_peak_at_ω_and_τ[2] = t_τ
	_τ_load_max = _τ_peak_at_ω[0]

func τ_μ_normalized(_t_: float) -> float:
	return _friction.τ_μ(_t_ * _ω_idle_peak_max[2]) / _τ_combustion_curve_factor.y

func w_normalized(_t_: float) -> float:
	var t_ω: float = _t_ * _ω_idle_peak_max[2]
	var t_τ: float = (_τ_combustion_curve.sample(_t_) - τ_μ_normalized(_t_)) * _τ_combustion_curve_factor.y
	return (t_τ * t_ω) / _w_peak_at_ω_and_τ[0]

static func rpm_to_omega(_rpm_: float) -> float:
	return _rpm_ * PI / 30.0

static func omega_to_rpm(_omega_: float) -> float:
	return _omega_ * 30.0 / PI
