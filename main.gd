extends Control

@export var _fps: Label

@export var _input_throttle: SliderInput
@export var _input_set_rpm: SliderInput
@export var _input_p: SliderInput
@export var _input_i: SliderInput
@export var _input_d: SliderInput

@export var _output_engine_spindle: TextureRect
@export var _output_engine_status: Label
@export var _output_clutch_spindle: TextureRect
@export var _output_hz: Label
@export var _output_pid_status: Label
@export var _output_audio_stream_player: AudioStreamPlayer2D

@export var _pid_start_stop: Button
@export var _graph: Graph

var _error_rate: float
var _error_rate_reset_msec: int

var _omega_error: float
var _omega_last: float
var _omega_acceleration: float

var _engine: CombustionEngine
var _pid: PID
var _clutch: Clutch
var _clutch_load: CTorque
var _brake_torque: float

func _ready() -> void:
	_engine = CombustionEngine.new()
	_engine.data_set(CInertia.new(0.35), CFriction.new(0.012, 0.015, 15.0), Vector3(800.0, 3600.0, 4400.0), Vector2(33.9, 40.6), Vector2(0.8, 0.2))
	_pid = PID.new()
	_pid.data_set(50, 1000)
	_clutch = Clutch.new()
	_clutch.data_set(
		_engine.inertia, _engine.friction,
		CInertia.new(1.5), CFriction.new(0.012, 0.015, 5.0),
		_engine.τ_at_w_peak * 5.0
		)
	_clutch_load = CTorque.new()
	_input_throttle.initialize("%.3f", 1.0)
	_input_set_rpm.initialize("%d", 1.0)
	_input_p.initialize("%.3f", 0.1)
	_input_i.initialize("%.3f", 0.1)
	_input_d.initialize("%.3f", 0.1)
	_pid_start_stop.pressed.connect(func() -> void:
		_pid.active = not _pid.active
		_pid_start_stop.text = "PID OFF" if _pid.active else "PID ON"
		_pid_status_update()
		)
	_engine.active = true
	_pid.active = true
	_pid_start_stop.pressed.emit()
	_graph.initialize()
	_graph.set_color(0, Color.ROYAL_BLUE)
	_graph.set_color(1, Color.INDIAN_RED)
	_graph.set_color(2, Color.SEA_GREEN)
	_graph.set_color(3, Color.ORANGE)
	_graph.set_color(4, Color.ORANGE)
	_graph.set_color(5, Color.BLUE_VIOLET)
	await get_tree().process_frame
	for i in Graph.POINT_COUNT:
		var t: float = float(i) / Graph.POINT_COUNT
		_graph.update_static(2, t, max(0.0, _engine.τ_combustion_curve.sample(t) - _engine.τ_μ_normalized(t)))
		_graph.update_static(3, t, max(0.0, _engine.w_normalized(t)))

func _physics_process(_dt_: float) -> void:
	_pid_collect_data(_dt_)
	_pid.process(_dt_, _omega_error, -_omega_acceleration)
	if _pid.active:
		_input_throttle.value = lerp(_input_throttle.value, _pid.value, 0.5)
	_engine.throttle = _input_throttle.value
	_clutch.process(_dt_, _engine.torque, _clutch_load.data_set(_clutch.friction_r.τ_μ(_clutch.inertia_r.ω) + _brake_torque, 0.0))

func _process(_dt_: float) -> void:
	_fps.text = "%d" % Engine.get_frames_per_second()
	_input_update(_dt_)
	_output_update(_dt_)

func _input_update(_dt_: float) -> void:
	if Input.is_key_pressed(KEY_S):
		_engine.τ_starter = _engine.τ_peak
	else:
		_engine.τ_starter = 0.0
	if Input.is_key_pressed(KEY_C):
		_clutch.engage = minf(_clutch.engage + 2.0 * _dt_, 1.0)
	else:
		_clutch.engage = maxf(_clutch.engage - 2.0 * _dt_, 0.0)
	if Input.is_key_pressed(KEY_SPACE):
		_brake_torque = _engine.τ_peak * 10.0
	else:
		_brake_torque = 0.0

func _output_update(_dt_: float) -> void:
	_output_engine_spindle.rotation += _engine.ω * _dt_
	_output_engine_status.text = "%d W, %.1f N-m at %d RPM" % [_clutch.τ * _engine.ω, _clutch.τ, CombustionEngine.omega_to_rpm(_engine.ω)]
	_output_clutch_spindle.rotation += _clutch.ω_r * _dt_
	if Time.get_ticks_msec() - _error_rate_reset_msec > 1000:
		_error_rate_reset_msec = Time.get_ticks_msec()
		_error_rate = 0.0
	_error_rate = max(_error_rate, abs(CombustionEngine.rpm_to_omega(_input_set_rpm.value) - _engine.ω) / CombustionEngine.rpm_to_omega(_input_set_rpm.value))
	_output_hz.text = "Hz: %.2f ± %.3f%%" % [_engine.ω / (2.0 * PI), _error_rate]
	if _engine.ω > 1.0:
		if not _output_audio_stream_player.playing:
			_output_audio_stream_player.play()
	else:
		if _output_audio_stream_player.playing:
			_output_audio_stream_player.stop()
	_output_audio_stream_player.pitch_scale = remap(CombustionEngine.omega_to_rpm(_engine.ω), 0.0, 5000.0, 0.1, 2.0)
	_output_audio_stream_player.volume_db = remap(_input_throttle.value, 0.0, 1.0, -1.0, 0.0)
	_pid_status_update()
	_graph.update_dynamic(0, _input_throttle.value)
	_graph.update_dynamic(1, _engine.ω / CombustionEngine.rpm_to_omega(5000.0))
	_graph.update_dynamic(4, (_clutch.τ * _engine.ω) / _engine.w_peak)
	_graph.update_dynamic(5, _clutch.inertia_r.ω / CombustionEngine.rpm_to_omega(5000.0))

func _pid_collect_data(_dt_: float) -> void:
	_pid.kp = _input_p.value
	_pid.ki = _input_i.value
	_pid.kd = _input_d.value
	_omega_error = CombustionEngine.rpm_to_omega(_input_set_rpm.value) - _engine.ω
	_omega_acceleration = (_engine.ω - _omega_last) / _dt_
	_omega_last = _engine.ω

func _pid_status_update() -> void:
	_output_pid_status.text = "EI: %.1f" % _pid.error_i
