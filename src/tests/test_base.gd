class_name TestBase
extends RefCounted
## Minimal headless test harness base (no addon dependency, CI-friendly).

var suite_name := "unnamed"
var failures: PackedStringArray = []
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func eq(a: Variant, b: Variant, msg: String) -> void:
	var same := false
	if a is float and b is float:
		same = absf(a - b) < 1e-9
	else:
		same = a == b
	checks += 1
	if not same:
		failures.append("%s (got %s, want %s)" % [msg, str(a), str(b)])


func approx(a: float, b: float, tol: float, msg: String) -> void:
	checks += 1
	if absf(a - b) > tol:
		failures.append("%s (got %f, want %f +/- %f)" % [msg, a, b, tol])
