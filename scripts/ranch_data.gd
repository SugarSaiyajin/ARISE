extends RefCounted

const AREAS := ["ranch_poultry", "ranch_meadow", "ranch_silk", "ranch_spring"]
const HOMES := ["家禽庭院", "月絨牧場", "桑蜜小院", "玉泉靈苑"]
const ORDER := ["hen", "duck", "rabbit", "sheep", "bee", "worm", "deer", "carp"]
const EXTRA := ["duck", "rabbit", "sheep", "bee", "worm", "deer", "carp"]
const LIMIT := 100000000
const SPECIES := {
	"hen": {"name":"琥珀雞", "home":0, "price":80, "days":0, "interval":1, "product":"雞蛋", "sell":56, "hint":"成雞吃收成小麥；餵好後隔日到巢箱領蛋。"},
	"duck": {"name":"蘆羽鴨", "home":0, "price":70, "days":2, "interval":1, "product":"鴨蛋", "sell":30, "hint":"淺水塘與乾燥鴨棚；親近時可撫摸。"},
	"rabbit": {"name":"月絨兔", "home":1, "price":90, "days":2, "interval":2, "product":"月絨", "sell":58, "hint":"住獨立防逃兔舍；親近時輕輕梳毛。"},
	"sheep": {"name":"苔角綿羊", "home":1, "price":160, "days":3, "interval":3, "product":"羊毛", "sell":90, "hint":"草場與遮蔭棚；親近時梳理捲毛。"},
	"bee": {"name":"蜜翼蜂", "home":2, "price":100, "days":2, "interval":2, "product":"花蜜蜂蜜", "sell":62, "hint":"以一箱蜂群飼養；照料花圃與觀察蜂箱。"},
	"worm": {"name":"雲錦蠶", "home":2, "price":100, "days":2, "interval":2, "product":"雲錦絲", "sell":64, "hint":"以一盤蠶群飼養；更換桑葉並清理蠶盤。"},
	"deer": {"name":"青玉靈鹿", "home":3, "price":220, "days":4, "interval":7, "product":"自然脫落玉角", "sell":220, "hint":"安靜林地照料；每七個成年餵養日自然落角。"},
	"carp": {"name":"星鱗鯉", "home":3, "price":180, "days":3, "interval":3, "product":"靈池星露", "sell":96, "hint":"觀察魚群並照料水質；收集池邊凝結星露。"},
}
const VISITORS := ["edric", "lyria", "borin", "yunji", "suyue", "qinglin"]
const RESIDENTS := {
	"edric": {"name":"艾德里克", "role":"誓約騎士", "home":0, "sprite":3, "line":"橋路的安全交給我。你餵好家禽後，也記得讓自己吃頓熱飯。"},
	"lyria": {"name":"莉莉雅", "role":"精靈園藝師", "home":2, "sprite":4, "line":"花圃會招來蜜翼蜂，桑葉則留給雲錦蠶。每一種生命都有自己的步調。"},
	"borin": {"name":"博林", "role":"矮人符文匠", "home":1, "sprite":5, "line":"兔舍的門扣修好了！我的符文器具與雷恩的農具，各有拿手的本事。"},
	"yunji": {"name":"雲霽", "role":"行腳修士", "home":3, "sprite":6, "line":"靈脈流過山川，也流過這口池水。星露凝在池邊，不必驚擾魚兒。"},
	"suyue": {"name":"素月", "role":"狐靈藥師", "home":0, "sprite":7, "line":"鴨棚要乾爽，清水要勤換。藥草照料人，細心照料小生靈。"},
	"qinglin": {"name":"青麟", "role":"山林守靈", "home":3, "sprite":8, "line":"等玉角自然落下再拾起吧。靈鹿願意靠近，是比產物更好的禮物。"},
}

const HOME_COST := [{"wood":8,"stone":6,"money":100},{"wood":6,"stone":3,"money":70},{"wood":6,"stone":4,"money":90},{"wood":8,"stone":6,"money":140}]
const CULTURES := {"edric":"culture_market","lyria":"culture_grove","borin":"culture_ember","yunji":"culture_sanctuary","suyue":"culture_sanctuary","qinglin":"culture_grove"}

static func visitor_area(id: String, minute: float, rain: bool) -> String:
	return CULTURES[id] if not rain and minute>=660 and minute<1080 else AREAS[RESIDENTS[id]["home"]]

static func visitor_position(id: String, area: String, minute: float, rain: bool) -> Vector2:
	var present: Array = []
	for key in VISITORS:
		if visitor_area(key,minute,rain)==area: present.append(key)
	var index := maxi(0,present.find(id))
	var x := 110.0+index*110.0
	if rain: return Vector2(x,190)
	var phase := fposmod(minute-420+index*13,180.0)
	var route := [[0,Vector2.ZERO],[45,Vector2.ZERO],[55,Vector2(16,0)],[100,Vector2(16,0)],[110,Vector2(16,10)],[125,Vector2(16,10)],[135,Vector2(0,10)],[145,Vector2.ZERO],[180,Vector2.ZERO]]
	for step in range(1,route.size()):
		if phase<=route[step][0]:
			var previous: Array=route[step-1]
			var next: Array=route[step]
			return Vector2(x,190)+(previous[1] as Vector2).lerp(next[1],(phase-previous[0])/float(next[0]-previous[0]))
	return Vector2(x,190)

static func visitor_direction(id: String, area: String, minute: float, rain: bool) -> Vector2:
	if rain: return Vector2.ZERO
	# Never derive motion across a schedule transition to another map.
	if visitor_area(id,minute+0.1,rain)!=area: return Vector2.ZERO
	return (visitor_position(id,area,minute+0.1,rain)-visitor_position(id,area,minute,rain)).normalized()

static func visitor_activity(id: String, area: String, minute: float, rain: bool) -> String:
	if rain: return "屋簷下整理物資"
	var present: Array=[]
	for key in VISITORS:
		if visitor_area(key,minute,rain)==area: present.append(key)
	var phase := fposmod(minute-420+maxi(0,present.find(id))*13,180.0)
	if phase>=110 and phase<125: return "稍作歇腳"
	if phase>=55 and phase<100: return "與街坊交流"
	if (phase>=45 and phase<55) or (phase>=100 and phase<110) or (phase>=125 and phase<145): return "前往下一處"
	return {"edric":"巡查路口","lyria":"整理花圃","borin":"檢查工具","yunji":"記錄泉水","suyue":"整理藥草","qinglin":"觀察林地"}[id]
