extends RefCounted
## Rewarded-ad hook. NO ad network is wired in, so available() is false and every ad button stays hidden.
## To add real ads later: integrate an AdMob plugin (needs Google consent/age settings), then make
## available() return true and call the callback ONLY from the plugin's "user earned reward" event.
## Never grant a reward without a real ad completion.

static func available() -> bool:
	return false

## placement examples: "exercise_double", "rent_hero", "rush_second_chance"
static func show_rewarded(_placement: String, _on_reward: Callable) -> void:
	pass
