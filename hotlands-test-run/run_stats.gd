extends Node

const BASE_LEVEL_SCORE := 1000
const TIME_PENALTY_PER_SECOND := 2
const DEATH_PENALTY := 100
const RESTART_PENALTY := 75

var total_score := 0
var levels_completed := 0
var current_level := 0
var elapsed_seconds := 0.0
var deaths := 0
var restarts := 0
var run_active := false
var level_score_awarded := false


func start_run() -> void:
	total_score = 0
	levels_completed = 0
	current_level = 0
	elapsed_seconds = 0.0
	deaths = 0
	restarts = 0
	level_score_awarded = false
	run_active = true


func begin_level(level_number: int, reset_attempt: bool = false) -> void:
	if not run_active:
		start_run()
	if current_level != level_number or reset_attempt:
		current_level = level_number
		elapsed_seconds = 0.0
		deaths = 0
		restarts = 0
		level_score_awarded = false


func advance_time(delta: float) -> void:
	if run_active and current_level > 0 and not level_score_awarded:
		elapsed_seconds += delta


func record_death() -> void:
	if not level_score_awarded:
		deaths += 1


func record_restart() -> void:
	if not level_score_awarded:
		restarts += 1


func current_level_score() -> int:
	var time_deduction := floori(elapsed_seconds * TIME_PENALTY_PER_SECOND)
	return maxi(0, BASE_LEVEL_SCORE - time_deduction - deaths * DEATH_PENALTY - restarts * RESTART_PENALTY)


func finish_level() -> Dictionary:
	if not level_score_awarded:
		total_score += current_level_score()
		levels_completed += 1
		level_score_awarded = true
	return {
		"level_score": current_level_score(),
		"total_score": total_score,
		"elapsed_seconds": elapsed_seconds,
	}


func formatted_time() -> String:
	var whole_seconds := floori(elapsed_seconds)
	var minutes := floori(whole_seconds / 60.0)
	var seconds := whole_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
