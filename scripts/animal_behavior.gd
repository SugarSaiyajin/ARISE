extends RefCounted
# Presentation only: time and bonding never grant food, products or friendship.
static func pose(s: RefCounted, id: String, seconds: float, player_distance: float, effect: String = "") -> Dictionary:
	var baby: bool=id!="hen" and s.ranch["animals"][id]["age"]<s.RANCH_DATA.SPECIES[id]["days"]
	var fed: bool=s.fed_chickens>0 if id=="hen" else s.ranch["animals"][id]["fed"]
	var ready: int=s.nest_eggs if id=="hen" else s.ranch["animals"][id]["ready"]
	var phase := fposmod(seconds+s.RANCH_DATA.ORDER.find(id)*0.7,10.0)
	var friendly_range: float=52 if s.GROWTH.stage(s,id)>=2 else 40
	var activity := "休息" if s.minute>=1140 else "進食" if effect=="feed" else "親近" if player_distance<friendly_range else "覓食" if not fed and phase<3 else "散步" if phase>=4 and phase<7 else "歇腳"
	var offset := Vector2.ZERO
	if activity=="散步": offset.x=sin((phase-4)*TAU/3)*6
	if id=="rabbit" and activity in ["散步","親近"]: offset.y=-absf(sin(seconds*4))*2
	if id=="bee" and activity!="休息": offset.y=sin(seconds*5)*1.5
	if activity in ["進食","覓食"]: offset.y=sin(seconds*7)*0.8
	return {"activity":activity,"offset":offset,"frame":3 if baby else 1 if activity in ["進食","覓食"] else int(seconds*3)%3 if activity=="散步" else 0,"ready":ready,"resting":activity=="休息","baby":baby}
