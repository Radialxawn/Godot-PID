class_name CombustionEngine
extends RefCounted

var active: bool
var throttle: float
var τ_load_static: float
var τ_load_dynamic: float
var τ_starter: float

var _inertia: float
var _ω: float
var _τ_combustion_curve: Curve
var _τ_combustion_curve_factor: Vector2
var _μ: float
var _μ_sqr: float
var _τ_μ_base: float
var _τ_load_max: float
var _ω_idle_peak_max: Vector3
var _τ_idle_peak: Vector2

var ω: float:
	get():
		return _ω

var τ_load_max: float:
	get():
		return _τ_load_max

var power_load: float:
	get():
		return _ω * τ_load()

var τ_combustion_curve: Curve:
	get():
		return _τ_combustion_curve

func data_set(_inertia_: float,
	_τ_μ_base_: float, _μ_: float, _μ_sqr_: float,
	_rpm_idle_peak_max_: Vector3, _τ_idle_peak_: Vector2,
	_bias_: Vector2
	) -> void:
	_inertia = _inertia_
	_τ_μ_base = _τ_μ_base_
	_μ = _μ_
	_μ_sqr = _μ_sqr_
	_ω_idle_peak_max = Vector3(
		rpm_to_omega(_rpm_idle_peak_max_[0]),
		rpm_to_omega(_rpm_idle_peak_max_[1]),
		rpm_to_omega(_rpm_idle_peak_max_[2])
		)
	_τ_idle_peak = Vector2(
		_τ_idle_peak_[0] + τ_μ(_ω_idle_peak_max[0]),
		_τ_idle_peak_[1] + τ_μ(_ω_idle_peak_max[1])
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
	var τ_peak_at_ω := [0.0, 0.0]
	var w_peak_at_ω_and_τ := [0.0, 0.0, 0.0]
	for i in 100:
		var t: float = float(i) / 100.0
		var t_τ: float = (_τ_combustion_curve.sample(t) - τ_μ_normalized(t)) * _τ_combustion_curve_factor.y
		var t_ω: float = t * _ω_idle_peak_max[2]
		if t_τ > τ_peak_at_ω[0]:
			τ_peak_at_ω[0] = t_τ
			τ_peak_at_ω[1] = omega_to_rpm(t_ω)
		var w: float = t_τ * t_ω
		if w > w_peak_at_ω_and_τ[0]:
			w_peak_at_ω_and_τ[0] = w
			w_peak_at_ω_and_τ[1] = omega_to_rpm(t_ω)
			w_peak_at_ω_and_τ[2] = t_τ
	_τ_load_max = τ_peak_at_ω[0]

func process(_Δt_: float) -> void:
	if not active:
		return
	var τ_combustion: float = _τ_combustion_curve.sample(_ω * _τ_combustion_curve_factor.x) * _τ_combustion_curve_factor.y * throttle
	var τ_net_dynamic: float = τ_combustion + τ_load_dynamic + τ_starter
	var Δω_dynamic: float = (τ_net_dynamic / _inertia) * _Δt_
	var τ_net_static: float = τ_μ(_ω) + abs(τ_load_static)
	var Δω_static: float = (τ_net_static / _inertia) * _Δt_
	_ω = signf(_ω) * max(abs(_ω) - Δω_static, 0.0)
	_ω += Δω_dynamic

func τ_μ(_ω_: float) -> float:
	return _τ_μ_base + _μ * _ω_ + _μ_sqr * (_ω_ * 0.1)**2

func τ_μ_normalized(_t_: float) -> float:
	return τ_μ(_t_ * _ω_idle_peak_max[2]) / _τ_combustion_curve_factor.y

func τ_load() -> float:
	return clampf(_ω * 1e2, 0.0, 1.0) * τ_load_static + τ_load_dynamic

static func rpm_to_omega(_rpm_: float) -> float:
	return _rpm_ * PI / 30.0

static func omega_to_rpm(_omega_: float) -> float:
	return _omega_ * 30.0 / PI
