extends Control

@export var _input_throttle: SliderInput
@export var _input_load: SliderInput
@export var _input_set_rpm: SliderInput
@export var _input_p: SliderInput
@export var _input_i: SliderInput
@export var _input_d: SliderInput

@export var _output_spindle: TextureRect
@export var _output_engine_status: Label
@export var _output_hz: Label
@export var _output_pid_status: Label
@export var _output_audio_stream_player: AudioStreamPlayer2D

@export var _pid_start_stop: Button
@export var _graph_rpm: Graph
@export var _graph_throttle: Graph

var _error_rate: float
var _error_rate_reset_msec: int

var _omega_error: float
var _omega_last: float
var _omega_acceleration: float

var _engine: CombustionEngine
var _pid: PID

func _ready() -> void:
	_engine = CombustionEngine.new()
	_engine.data_set(0.35, 39.52, 25.3, CombustionEngine.rpm_to_omega(3600.0), 0.012, 0.0015)
	_pid = PID.new()
	_pid.data_set(50, 1000)
	_input_throttle.initialize("%.3f", 1.0)
	_input_load.initialize("%.2f N-m", 100.0)
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
	_graph_rpm.initialize()
	_graph_throttle.initialize()

func _process(_dt_: float) -> void:
	if Input.is_key_pressed(KEY_S):
		_engine.τ_starter = 100.0
	else:
		_engine.τ_starter = 0.0
	_engine.process(_dt_)
	_collect_data(_dt_)
	_pid.process(_dt_, _omega_error, -_omega_acceleration)
	if _pid.active:
		_input_throttle.value = lerp(_input_throttle.value, _pid.value, 0.5)
	_engine.throttle = _input_throttle.value
	_engine.τ_load_static = _input_load.value
	_output_update(_dt_)

func _collect_data(_dt_: float) -> void:
	_pid.kp = _input_p.value
	_pid.ki = _input_i.value
	_pid.kd = _input_d.value
	_omega_error = CombustionEngine.rpm_to_omega(_input_set_rpm.value) - _engine.ω
	_omega_acceleration = (_engine.ω - _omega_last) / _dt_
	_omega_last = _engine.ω

func _output_update(_dt_: float) -> void:
	_output_spindle.rotation += _engine.ω * _dt_
	_output_engine_status.text = "%d W, %.1f N-m at %d RPM" % [_engine.power_load, _engine.τ_load(), CombustionEngine.omega_to_rpm(_engine.ω)]
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
	_graph_throttle.update(_input_throttle.value)
	_graph_rpm.update(_engine.ω / CombustionEngine.rpm_to_omega(5000.0))

func _pid_status_update() -> void:
	_output_pid_status.text = "EI: %.1f" % _pid.error_i
