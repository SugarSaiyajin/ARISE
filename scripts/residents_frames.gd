extends RefCounted

# Geometry read from the unchanged source PNG by register_hero_frames.py.
# Per-pose source rect and foot pivot keep the character registered in world space.
const PIXEL_SCALE := 0.072992700729927
const DIRECTIONS := ["south", "west", "east", "north", "southwest", "southeast", "northwest", "northeast"]
const FRAMES := [
	[
		[107, 9, 242, 430, 142.0, 427],
		[501, 9, 252, 429, 117.0, 426],
		[836, 8, 315, 431, 157.5, 428],
	],
	[
		[46, 434, 372, 422, 193.0, 419],
		[478, 444, 264, 412, 146.0, 409],
		[824, 497, 378, 358, 179.0, 355],
	],
	[
		[83, 854, 306, 417, 168.5, 414],
		[452, 852, 299, 419, 170.0, 416],
		[836, 858, 284, 413, 179.5, 410],
	],
]
