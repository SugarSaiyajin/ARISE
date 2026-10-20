extends RefCounted

# Geometry read from the unchanged source PNG by register_hero_frames.py.
# Per-pose source rect and foot pivot keep the character registered in world space.
const PIXEL_SCALE := 0.10830324909747292
const DIRECTIONS := ["south", "west", "east", "north", "southwest", "southeast", "northwest", "northeast"]
const FRAMES := [
	[
		[59, 67, 158, 295, 73.5, 292],
		[328, 74, 179, 285, 72.5, 282],
		[611, 75, 154, 287, 59.0, 284],
		[882, 72, 159, 290, 64.5, 287],
		[1133, 67, 167, 295, 75.0, 292],
		[1377, 92, 232, 260, 88.0, 257],
		[1645, 120, 245, 234, 96.0, 231],
		[1974, 70, 156, 292, 71.5, 289],
	],
	[
		[57, 384, 179, 285, 93.5, 282],
		[331, 389, 184, 280, 54.5, 277],
		[600, 391, 176, 281, 89.5, 278],
		[871, 391, 181, 281, 83.5, 278],
		[1121, 384, 179, 285, 94.0, 282],
		[1377, 405, 241, 261, 88.0, 258],
		[1645, 435, 245, 232, 94.5, 229],
		[1959, 392, 172, 277, 91.0, 274],
	],
]
