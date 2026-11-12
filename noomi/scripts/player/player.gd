extends Node2D
## Noomi gymnast. Hybrid physics:
##  HANG  - analytic pendulum around a bar (stable, tunable, keeps momentum exactly).
##  AIR   - ballistic body with controlled spin; rotation is accumulated so tricks are measured, not assumed.
## Convention: rot = 0 is upright (feet down). Positive rot = clockwise = front flip. Faces right.

signal grabbed(is_regrab: bool, bar_index: int)
signal released(speed: float, good: bool)
signal rotation_completed(count: int, dir: int)
signal flight_ended(summary: Dictionary, how: String)
signal landed(result: String, info: Dictionary)

const Art := preload("res://scripts/player/player_art.gd")
const CharacterData := preload("res://scripts/core/character_data.gd")

signal gust(direction: int)

enum State { HANG, AIR, LANDED, FALLEN }

@export_group("Swing")
@export var gravity := 1200.0
@export var hang_length := 80.0
@export var pump_accel := 9.0
@export var swing_damping := 0.12
@export var max_swing_speed := 6.8
@export var spin_transfer := 0.8
@export_group("Grab")
@export var grab_range := 110.0
@export var regrab_delay := 0.2
@export_group("Air")
@export var air_spin := 7.5
@export var tuck_mult := 1.8
@export var spin_accel := 40.0
@export var extend_brake := 18.0
@export var passive_damp := 0.8
@export var twist_speed := 9.0
@export var flip_tolerance := 0.6
@export var landing_assist := 3.5
@export var assist_height := 110.0
@export_group("Landing thresholds")
@export var perfect_angle := 0.24
@export var clean_angle := 0.50
@export var unstable_angle := 0.90
@export var perfect_vy := 1100.0
@export var clean_vy := 1300.0
@export var unstable_vy := 1500.0
@export var perfect_spin := 2.0
@export var clean_spin := 4.0
@export_group("Difficulty (random trouble in the air)")
## 0.4 = gentle, 1.0 = normal, 1.4 = hard. Set per level by gameplay.gd.
@export var difficulty := 1.0
## Chance that a flight gets a wind gust at some point.
@export var gust_chance := 0.85
## Spin kick (rad/s) and sideways push (px/s) of a gust at difficulty 1.0.
@export var gust_spin := 2.4
@export var gust_push := 200.0
## Instant tilt (radians) a gust adds at difficulty 1.0. Braking alone does not fix this: tap FLIP.
@export var gust_tilt := 0.5
## Random extra spin (rad/s) added at release at difficulty 1.0.
@export var release_jitter := 0.9

const FEET := 44.0
const HEAD := 48.0

var state: int = State.HANG
var bars: Array = []
var surfaces: Array = []
var target: Dictionary = {}
var palette: Dictionary = CharacterData.LIST[0].duplicate()

var bar_index := 0
var last_released_bar := -1
var theta := 0.5
var omega := 0.0
var cur_len := 80.0
var vel := Vector2.ZERO
var rot := 0.0
var rot_vel := 0.0
var twist := 0.0
var facing := 1.0
var flip_accum := 0.0
var airtime := 0.0
var cooldown := 0.0
var grab_queued := false
var tucked := false
var attempted := false
var counted_flips := 0
var near_bar := -1
var squash := 0.0
var hang_blend := 1.0
var extended := false
var last_result := ""
var gust_vis := 0.0
var gust_dir_vis := 1
var _gust_time := -1.0
var _gust_dir := 1

var _head := Vector2.ZERO
var _feet := Vector2.ZERO
var _prev_low_y := 0.0
var _land_top := 0.0
var _resting := false
var _oob_y := 1100.0
var _oob_min_x := -2000.0
var _oob_max_x := 5000.0

func setup(level: Dictionary) -> void:
	bars = level["bars"]
	surfaces = level["surfaces"]
	target = level.get("target", {})
	var min_x := 1e9
	var max_x := -1e9
	var max_y := 0.0
	for s in surfaces:
		var r: Rect2 = s
		min_x = minf(min_x, r.position.x)
		max_x = maxf(max_x, r.end.x)
		max_y = maxf(max_y, r.position.y)
	_oob_min_x = min_x - 300.0
	_oob_max_x = max_x + 300.0
	_oob_y = max_y + 450.0
	reset(0)

func reset(bar_i: int = 0) -> void:
	bar_index = clampi(bar_i, 0, maxi(bars.size() - 1, 0))
	last_released_bar = -1
	state = State.HANG
	theta = 0.5
	omega = 0.0
	cur_len = hang_length
	vel = Vector2.ZERO
	rot = -theta
	rot_vel = 0.0
	twist = 0.0
	facing = 1.0
	flip_accum = 0.0
	airtime = 0.0
	cooldown = 0.0
	grab_queued = false
	tucked = false
	attempted = false
	counted_flips = 0
	near_bar = -1
	squash = 0.0
	hang_blend = 1.0
	extended = false
	last_result = ""
	gust_vis = 0.0
	_gust_time = -1.0
	_resting = false
	var bar: Vector2 = bars[bar_index]
	position = bar + Vector2(sin(theta), cos(theta)) * cur_len
	_calc_points()
	_prev_low_y = maxf(_head.y, _feet.y)
	_apply_visual()
	queue_redraw()

func queue_grab() -> void:
	grab_queued = true

func is_hanging() -> bool:
	return state == State.HANG

func is_airborne() -> bool:
	return state == State.AIR

func flips_progress() -> float:
	return absf(flip_accum) / TAU

func twist_progress() -> float:
	return absf(twist) / PI

func hit_hazard() -> void:
	if state == State.HANG or state == State.AIR:
		_fail("hazard")

func body_points() -> Array:
	return [_head, position, _feet]

func _physics_process(delta: float) -> void:
	hang_blend = move_toward(hang_blend, 1.0 if state == State.HANG else 0.0, 9.0 * delta)
	gust_vis = maxf(0.0, gust_vis - delta)
	match state:
		State.HANG:
			_tick_hang(delta)
		State.AIR:
			_tick_air(delta)
		State.LANDED:
			_tick_landed(delta)
		State.FALLEN:
			_tick_fallen(delta)
	_calc_points()
	_apply_visual()
	queue_redraw()

func _calc_points() -> void:
	var up := Vector2(sin(rot), -cos(rot))
	_head = position + up * HEAD
	_feet = position - up * FEET

func _apply_visual() -> void:
	rotation = rot
	var sx := facing
	if state == State.AIR:
		var c := cos(twist)
		if absf(c) < 0.06:
			c = 0.06 if c >= 0.0 else -0.06
		sx = facing * c
	scale = Vector2(sx * (1.0 + 0.12 * squash), 1.0 - 0.18 * squash)

# ---------------------------------------------------------------- HANG
func _tick_hang(delta: float) -> void:
	var bar: Vector2 = bars[bar_index]
	var acc := -(gravity / hang_length) * sin(theta) - swing_damping * omega
	if Input.is_action_pressed("pump"):
		var dir := signf(omega) if absf(omega) > 0.05 else -signf(theta)
		if dir == 0.0:
			dir = 1.0
		acc += pump_accel * dir
	if Input.is_action_just_pressed("pump"):
		AudioManager.play("swing")
	omega = clampf(omega + acc * delta, -max_swing_speed, max_swing_speed)
	theta = wrapf(theta + omega * delta, -PI, PI)
	cur_len = move_toward(cur_len, hang_length, 500.0 * delta)
	position = bar + Vector2(sin(theta), cos(theta)) * cur_len
	rot = lerp_angle(rot, -theta, minf(1.0, 14.0 * delta))
	if grab_queued:
		grab_queued = false
		_release()

func _release() -> void:
	var tangent := Vector2(cos(theta), -sin(theta))
	vel = tangent * omega * hang_length
	# Gentle levels start with less leftover spin so a first-time player is not punished.
	var spin_scale := lerpf(0.35, 1.0, clampf((difficulty - 0.4) / 0.6, 0.0, 1.0))
	rot_vel = -omega * spin_transfer * spin_scale + randf_range(-1.0, 1.0) * release_jitter * difficulty
	_gust_time = randf_range(0.25, 0.75) if randf() < gust_chance else -1.0
	_gust_dir = 1 if randf() < 0.5 else -1
	var speed := vel.length()
	state = State.AIR
	last_released_bar = bar_index
	cooldown = regrab_delay
	flip_accum = 0.0
	twist = 0.0
	airtime = 0.0
	attempted = false
	counted_flips = 0
	_calc_points()
	_prev_low_y = maxf(_head.y, _feet.y)
	var good := speed >= 0.75 * max_swing_speed * hang_length and vel.y < 0.0
	released.emit(speed, good)

func _grab(i: int) -> void:
	var summary := _end_flight()
	summary["different_bar"] = i != last_released_bar
	var bar: Vector2 = bars[i]
	var rel := position - bar
	var dist := rel.length()
	if dist < 1.0:
		rel = Vector2(0, 1)
		dist = 1.0
	theta = atan2(rel.x, rel.y)
	var tangent := Vector2(cos(theta), -sin(theta))
	omega = clampf(vel.dot(tangent) / hang_length, -max_swing_speed, max_swing_speed)
	cur_len = clampf(dist, 30.0, hang_length + grab_range)
	bar_index = i
	state = State.HANG
	rot = wrapf(rot, -PI, PI)
	vel = Vector2.ZERO
	rot_vel = 0.0
	tucked = false
	flight_ended.emit(summary, "regrab")
	grabbed.emit(true, i)

# ---------------------------------------------------------------- AIR
func _tick_air(delta: float) -> void:
	airtime += delta
	cooldown = maxf(0.0, cooldown - delta)
	vel.y += gravity * delta
	var back := Input.is_action_pressed("flip_back")
	var front := Input.is_action_pressed("flip_front")
	tucked = Input.is_action_pressed("tuck")
	var extend := Input.is_action_pressed("extend")
	extended = extend
	var flipping := (back or front) and not (back and front)
	# Beginners (low difficulty) get more help; it fades out as difficulty rises.
	var easy := clampf(1.5 - difficulty, 0.0, 1.0)
	if flipping:
		var tgt := air_spin if front else -air_spin
		rot_vel = move_toward(rot_vel, tgt, spin_accel * delta)
		attempted = true
	elif extend:
		rot_vel = move_toward(rot_vel, 0.0, extend_brake * delta)
	else:
		rot_vel = move_toward(rot_vel, 0.0, passive_damp * (1.0 + 2.0 * easy) * delta)
	var d_rot := rot_vel * (tuck_mult if tucked else 1.0) * delta
	rot += d_rot
	flip_accum += d_rot
	# Wind gust: kicks the spin and pushes sideways. The player must correct it.
	if _gust_time >= 0.0 and airtime >= _gust_time:
		_gust_time = -1.0
		rot_vel += float(_gust_dir) * gust_spin * difficulty
		rot += float(_gust_dir) * gust_tilt * difficulty
		flip_accum += float(_gust_dir) * gust_tilt * difficulty
		vel.x += float(_gust_dir) * gust_push * difficulty
		gust_vis = 0.7
		gust_dir_vis = _gust_dir
		gust.emit(_gust_dir)
	# Forgiveness shrinks as difficulty grows: close to the ground and not actively flipping,
	# ease to upright, but only when the error is small enough.
	var window := clampf(2.4 - 1.2 * difficulty, 0.5, 2.2)
	if not flipping and _height_above() < assist_height * (1.0 + 0.4 * easy):
		var goal := roundf(rot / TAU) * TAU
		if absf(goal - rot) < window:
			var nudge := (goal - rot) * minf(1.0, landing_assist * (1.0 + 1.5 * easy) * delta)
			rot += nudge
			flip_accum += nudge
			rot_vel *= (1.0 - minf(1.0, 2.0 * delta))
	# Twist
	if Input.is_action_pressed("twist"):
		twist += twist_speed * delta
		attempted = true
	else:
		twist = move_toward(twist, roundf(twist / PI) * PI, 8.0 * delta)
	position += vel * delta
	# Live progress event (points are banked at the end of the flight).
	var f := int((absf(flip_accum) + flip_tolerance) / TAU)
	if f > counted_flips:
		counted_flips = f
		rotation_completed.emit(f, -1 if flip_accum < 0.0 else 1)
	# Regrab
	near_bar = _find_near_bar()
	if grab_queued:
		grab_queued = false
		if near_bar != -1:
			_grab(near_bar)
			return
	_calc_points()
	if position.y > _oob_y or position.x < _oob_min_x or position.x > _oob_max_x:
		_fail("out of bounds")
		return
	var low_y := maxf(_head.y, _feet.y)
	var lowest := _feet if _feet.y >= _head.y else _head
	for i in surfaces.size():
		var r: Rect2 = surfaces[i]
		var top := r.position.y
		if lowest.y >= top and _prev_low_y < top + 6.0 and lowest.x >= r.position.x - 4.0 and lowest.x <= r.end.x + 4.0:
			_land(i, lowest)
			return
		if position.y > top + 12.0 and position.y < r.end.y and position.x > r.position.x - 22.0 and position.x < r.end.x + 22.0:
			_fail("collision")
			return
	_prev_low_y = low_y

func _find_near_bar() -> int:
	if cooldown > 0.0:
		return -1
	var up := Vector2(sin(rot), -cos(rot))
	var hands := position + up * hang_length
	var best := -1
	var best_d := grab_range
	for i in bars.size():
		var d := hands.distance_to(bars[i])
		if d <= best_d:
			best_d = d
			best = i
	return best

func _height_above() -> float:
	var best := 99999.0
	for s in surfaces:
		var r: Rect2 = s
		if position.x >= r.position.x and position.x <= r.end.x and r.position.y >= position.y:
			best = minf(best, r.position.y - (position.y + FEET))
	return best

func _in_target(x: float, top: float) -> bool:
	if target.is_empty():
		return true
	return absf(top - float(target["y"])) < 2.0 and x >= float(target["x"]) and x <= float(target["x"]) + float(target["w"])

func _end_flight() -> Dictionary:
	var flips := int((absf(flip_accum) + flip_tolerance) / TAU)
	var halves := int(roundf(absf(twist) / PI))
	var s := {
		"flips": flips,
		"dir": -1 if flip_accum < 0.0 else 1,
		"halves": halves,
		"airtime": airtime,
		"attempted": attempted,
		"different_bar": true,
	}
	if halves % 2 == 1:
		facing = -facing
	twist = 0.0
	flip_accum = 0.0
	counted_flips = 0
	return s

# ---------------------------------------------------------------- LANDING
func _land(i: int, pt: Vector2) -> void:
	var r: Rect2 = surfaces[i]
	var top := r.position.y
	var ang := wrapf(rot, -PI, PI)
	var a := absf(ang)
	var vy := vel.y
	var spin := absf(rot_vel * (tuck_mult if tucked else 1.0))
	var on_target := _in_target(pt.x, top)
	var res := "fall"
	if cos(rot) > 0.0:
		if a <= perfect_angle and vy <= perfect_vy and spin <= perfect_spin and on_target:
			res = "perfect"
		elif a <= clean_angle and vy <= clean_vy and spin <= clean_spin:
			res = "clean"
		elif a <= unstable_angle and vy <= unstable_vy:
			res = "unstable"
	if res == "fall":
		_fail("bad landing")
		return
	last_result = res
	var summary := _end_flight()
	var info := {"speed": vel.length(), "angle": ang, "on_target": on_target, "airtime": summary["airtime"], "reason": ""}
	flight_ended.emit(summary, "landing")
	state = State.LANDED
	_land_top = top
	position.y = top - FEET * cos(rot)
	vel = Vector2.ZERO
	rot_vel = 0.0
	squash = 1.0
	landed.emit(res, info)

func _tick_landed(delta: float) -> void:
	squash = move_toward(squash, 0.0, delta * 4.0)
	var wob := 0.0
	if last_result == "unstable":
		wob = sin(float(Time.get_ticks_msec()) * 0.02) * 0.16
	rot = lerp_angle(rot, wob, minf(1.0, 12.0 * delta))
	position.y = _land_top - FEET * cos(rot)

func _fail(reason: String) -> void:
	if state == State.LANDED or state == State.FALLEN:
		return
	if state == State.HANG:
		vel = Vector2(cos(theta), -sin(theta)) * omega * hang_length
	var summary := _end_flight()
	flight_ended.emit(summary, "fall")
	last_result = "fall"
	state = State.FALLEN
	_resting = false
	rot_vel = 3.0 if rot_vel >= 0.0 else -3.0
	squash = 0.0
	landed.emit("fall", {"reason": reason, "on_target": false, "airtime": summary["airtime"], "speed": vel.length(), "angle": wrapf(rot, -PI, PI)})

func _tick_fallen(delta: float) -> void:
	if _resting:
		return
	vel.y += gravity * delta
	vel.x = move_toward(vel.x, 0.0, 200.0 * delta)
	position += vel * delta
	rot += rot_vel * delta
	for s in surfaces:
		var r: Rect2 = s
		if position.x >= r.position.x and position.x <= r.end.x and position.y + 18.0 >= r.position.y and position.y < r.position.y + 60.0:
			position.y = r.position.y - 18.0
			vel = Vector2.ZERO
			rot = (PI / 2.0) * (1.0 if sin(rot) >= 0.0 else -1.0)
			_resting = true
			return

# ---------------------------------------------------------------- DRAW
func _draw() -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	var pose: Dictionary
	match state:
		State.HANG, State.AIR:
			var air := Art.pose_air(extended and state == State.AIR, tucked and state == State.AIR)
			var hang := Art.pose_hang(cur_len, clampf(omega * 2.0, -12.0, 12.0) * facing)
			pose = Art.lerp_pose(air, hang, hang_blend)
		State.LANDED:
			pose = Art.pose_stand(last_result == "perfect" or last_result == "clean", last_result == "unstable", t)
		_:
			pose = Art.pose_flail(t)
	draw_set_transform(Vector2(0.0, -Art.SHIFT_HANG * hang_blend), 0.0, Vector2.ONE)
	Art.draw_character(self, pose, palette, t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
