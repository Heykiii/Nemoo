extends RefCounted
## Data-driven character specialists: unlock cost, passive perk (stat multipliers) and ONE active ability.
## Add or retune a hero by editing this table only. Gymnast is the neutral baseline (all 1.0).
##
## Perk keys (all optional, default 1.0 / false):
##   grab_range, pump, air_spin, land_angle (bigger = more forgiving), swing_max,
##   coins (campaign / rush coin multiplier), multi_flip (score multiplier for 2+ flips), preview (path dots)
## Ability ids are implemented in player.gd (activate_ability).

const TIERS := ["Starter", "Rookie", "Pro", "Elite", "Legend"]

const STATS := {
	"gymnast": {"tier": 0, "cost": 0, "perk": "Balanced. No weak spots.", "perk_stats": {},
		"ability": "float", "ability_name": "Chalk Float", "ability_desc": "Fall slower for 1 second."},
	"ninja": {"tier": 1, "cost": 500, "perk": "Wide grab range (+20%).", "perk_stats": {"grab_range": 1.2},
		"ability": "dash", "ability_name": "Shadow Dash", "ability_desc": "Burst of speed forward."},
	"chef": {"tier": 1, "cost": 600, "perk": "Quick spinner (+10% spin).", "perk_stats": {"air_spin": 1.1},
		"ability": "extra_flip", "ability_name": "Pancake Flip", "ability_desc": "Adds one extra flip instantly."},
	"pirate": {"tier": 2, "cost": 1200, "perk": "Treasure hunter: +20% coins.", "perk_stats": {"coins": 1.2},
		"ability": "hook", "ability_name": "Grappling Hook", "ability_desc": "Much longer grab reach for the rest of the jump."},
	"clown": {"tier": 2, "cost": 1500, "perk": "Soft landings (+12% angle forgiveness).", "perk_stats": {"land_angle": 1.12},
		"ability": "honk", "ability_name": "Confetti Honk", "ability_desc": "Instant +150 style points."},
	"viking": {"tier": 2, "cost": 1800, "perk": "Strong pump (+15% swing power).", "perk_stats": {"pump": 1.15, "swing_max": 1.05},
		"ability": "leap", "ability_name": "Mighty Leap", "ability_desc": "Extra upward kick."},
	"scientist": {"tier": 3, "cost": 3000, "perk": "Shows your flight path before release.", "perk_stats": {"preview": true},
		"ability": "slowmo", "ability_name": "Time Dilation", "ability_desc": "Slows time for 1.5 seconds."},
	"dino": {"tier": 3, "cost": 3500, "perk": "Heavy tail: +15% landing forgiveness.", "perk_stats": {"land_angle": 1.15},
		"ability": "stabilize", "ability_name": "Tail Stabilize", "ability_desc": "Stops your spin on the spot."},
	"robot": {"tier": 3, "cost": 4000, "perk": "Precise spin control (+15%).", "perk_stats": {"air_spin": 1.15},
		"ability": "autolevel", "ability_name": "Auto-Level", "ability_desc": "Gyros level you upright for 1 second."},
	"wizard": {"tier": 4, "cost": 7500, "perk": "Wide reach (+15%) and +10% coins.", "perk_stats": {"grab_range": 1.15, "coins": 1.1},
		"ability": "carpet", "ability_name": "Magic Carpet", "ability_desc": "Float and slow time for 1.5 seconds."},
	"astro": {"tier": 4, "cost": 10000, "perk": "Multi-flips score x2.", "perk_stats": {"multi_flip": 2.0},
		"ability": "zerog", "ability_name": "Zero-G", "ability_desc": "Almost no gravity for 2 seconds."},
}

static func of(id: String) -> Dictionary:
	return STATS.get(id, STATS["gymnast"])

static func cost(id: String) -> int:
	return int(of(id)["cost"])

static func tier_name(id: String) -> String:
	return TIERS[int(of(id)["tier"])]

## Multiplier lookup with a neutral default.
static func mult(id: String, key: String) -> float:
	return float(of(id)["perk_stats"].get(key, 1.0))

static func flag(id: String, key: String) -> bool:
	return bool(of(id)["perk_stats"].get(key, false))
