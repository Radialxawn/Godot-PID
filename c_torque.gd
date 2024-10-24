class_name CTorque
extends RefCounted

var v_static: float
var v_dynamic: float

func data_set(_v_static_: float, _v_dynamic_: float) -> CTorque:
	v_static = _v_static_
	v_dynamic = _v_dynamic_
	return self
