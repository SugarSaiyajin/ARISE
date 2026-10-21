extends RefCounted

static func block(node: Node2D, center: Vector2, x: float, y: float, w: float, h: float, color: String) -> void:
	node.draw_rect(Rect2((center + Vector2(x,y)).floor(),Vector2(w,h)),Color(color))

static func draw(node: Node2D, crop: String, center: Vector2, stage: int) -> void:
	block(node,center,-7,0,14,2,"364e3c66")
	if stage == 0:
		block(node,center,-1,-4,2,5,"597849")
		block(node,center,-4,-4,3,2,"95b46b")
		block(node,center,1,-6,3,2,"789a55")
		return
	var height := 8 if stage == 1 else 12
	block(node,center,-1,-height,2,height,"496a45")
	for side in [-1,1]:
		block(node,center,side*3-2,-height+3,4,3,"55794a")
		block(node,center,side*3-1,-height+2,3,2,"99b871")
	if stage < 2: return
	match crop:
		"turnip":
			block(node,center,-6,-5,12,6,"d4cfaa")
			block(node,center,-4,-6,8,6,"f1e8cc")
			if stage==3: block(node,center,-1,1,2,3,"d4cfaa")
		"wheat":
			for x in [-5,0,5]:
				block(node,center,x,-17,1,18,"a48c47")
				block(node,center,x-2,-17,5,8,"d3ba6f")
				block(node,center,x,-17,2,7,"f1daa0")
		"berry":
			block(node,center,-7,-12,14,12,"507252")
			for p in [Vector2(-5,-10),Vector2(2,-7),Vector2(-2,-3)]:
				block(node,center,p.x,p.y,4,4,"b96d50")
				block(node,center,p.x,p.y,2,1,"e3ac6c")
		"carrot":
			block(node,center,-4,-5,8,6,"79513c")
			block(node,center,-3,-5,6,5,"d9924e")
			block(node,center,-2,-4,2,4,"efb36b")
			block(node,center,2,-3,2,1,"b97842")
			if stage == 3: block(node,center,-1,0,2,3,"d9924e")
		"cabbage":
			block(node,center,-8,-10,16,9,"3c6246")
			block(node,center,-7,-12,14,11,"668d57")
			block(node,center,-5,-13,10,10,"9fba79")
			block(node,center,-3,-12,5,7,"c3cf91")
			block(node,center,-6,-6,3,4,"819f63")
			block(node,center,4,-8,2,6,"4e744b")
		"potato":
			for shift in [-5,3]:
				block(node,center,shift,-3,6,5,"7e6946")
				block(node,center,shift,-3,5,4,"bda56b")
				block(node,center,shift+1,-2,2,1,"dfca91")
			if stage == 3:
				block(node,center,-6,-11,2,2,"eadcc3")
				block(node,center,5,-9,2,2,"e5d1ae")
		"pea":
			block(node,center,-4,-16,1,16,"a69764")
			block(node,center,4,-16,1,16,"a69764")
			block(node,center,-5,-13,10,1,"c3b77d")
			block(node,center,-3,-14,2,12,"6b985b")
			if stage == 3:
				for p in [Vector2(-5,-10),Vector2(2,-7)]:
					block(node,center,p.x,p.y,3,7,"92b86c")
					block(node,center,p.x+1,p.y+1,1,4,"c4d98b")
		"tea":
			block(node,center,-7,-10,14,10,"456747")
			block(node,center,-6,-13,12,10,"6c975c")
			for p in [Vector2(-5,-11),Vector2(2,-13),Vector2(-1,-7)]:
				block(node,center,p.x,p.y,4,2,"9fbd78")
			if stage == 3:
				block(node,center,-1,-16,2,7,"c6d591")
				block(node,center,1,-16,3,2,"d9dfad")
