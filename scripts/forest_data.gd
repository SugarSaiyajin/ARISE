extends RefCounted

const MATERIALS := {
	"wood": {"name": "木材", "amount": 2, "energy": 3},
	"stone": {"name": "石料", "amount": 2, "energy": 4},
	"herb": {"name": "霧香草", "amount": 1, "energy": 2},
}
const ORDER := ["wood", "stone", "herb"]
# IDs are persisted; keep them stable when changing art or placement.
const NODES := {
	"wood_1": {"kind": "wood", "position": Vector2(106, 112)},
	"wood_2": {"kind": "wood", "position": Vector2(182, 183)},
	"wood_3": {"kind": "wood", "position": Vector2(312, 119)},
	"stone_1": {"kind": "stone", "position": Vector2(220, 98)},
	"stone_2": {"kind": "stone", "position": Vector2(351, 182)},
	"herb_1": {"kind": "herb", "position": Vector2(148, 146)},
	"herb_2": {"kind": "herb", "position": Vector2(283, 182)},
	"herb_3": {"kind": "herb", "position": Vector2(402, 133)},
}
const REPAIR_COST := {"wood": 6, "stone": 4}
