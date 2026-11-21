extends RefCounted
## "Train for Coins": short guided real-life exercises. Honest design: the game CANNOT see your body.
## It runs a paced countdown and trusts you (honor system). Each exercise pays once per day.

const LIST := [
	{"id": "squats", "name": "Squats", "icon": "squat", "coins": 150, "reps": 10, "secs_per_rep": 2.5,
		"how": "Feet shoulder-width apart. Bend your knees, back straight, then stand up. One squat per beat."},
	{"id": "jacks", "name": "Jumping Jacks", "icon": "jack", "coins": 150, "reps": 10, "secs_per_rep": 1.5,
		"how": "Jump your feet apart while raising your arms, then jump back. One jack per beat."},
	{"id": "plank", "name": "Plank 30s", "icon": "plank", "coins": 200, "reps": 0, "secs": 30.0,
		"how": "Forearms on the floor, body in a straight line. Breathe. Stop if it hurts."},
	{"id": "pushups", "name": "Push-ups x15", "icon": "pushup", "coins": 150, "reps": 15, "secs_per_rep": 2.0,
		"how": "Hands under shoulders, lower your chest, push up. Knees on the floor is fine."},
	{"id": "circles", "name": "Arm Circles x15", "icon": "circle", "coins": 150, "reps": 15, "secs_per_rep": 1.5,
		"how": "Arms straight out to the sides. Make small circles, then big ones. Gentle and slow."},
]

const SAFETY := "Warm up first. Move at your own pace and stop if you feel pain or dizzy. Not medical advice. Kids: ask a grown-up."

static func get_def(id: String) -> Dictionary:
	for e in LIST:
		if e["id"] == id:
			return e
	return {}

## Total seconds the guided countdown runs for this exercise.
static func duration(id: String) -> float:
	var d := get_def(id)
	if d.is_empty():
		return 0.0
	if int(d["reps"]) > 0:
		return float(d["reps"]) * float(d["secs_per_rep"])
	return float(d["secs"])
