extends RefCounted

# Geometry read from the unchanged source PNG by register_hero_frames.py.
# Per-pose source rect and foot pivot keep the character registered in world space.
const PIXEL_SCALE := 0.21935483870967742
const DIRECTIONS := ["south", "west", "east", "north", "southwest", "southeast", "northwest", "northeast"]
const FRAMES := [
	[
		[28, 21, 362, 318, 174.0, 315],
		[412, 102, 357, 245, 135.5, 242],
		[783, 19, 345, 328, 185.0, 325],
		[1147, 29, 369, 318, 191.0, 315],
	],
	[
		[45, 339, 268, 348, 134.0, 345],
		[391, 415, 365, 264, 190.5, 261],
		[775, 388, 363, 287, 208.0, 284],
		[1162, 366, 362, 311, 123.5, 308],
	],
	[
		[26, 689, 325, 316, 145.5, 313],
		[369, 688, 404, 304, 204.0, 301],
		[773, 679, 378, 326, 190.5, 323],
		[1176, 682, 339, 323, 166.0, 320],
	],
]
