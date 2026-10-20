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
