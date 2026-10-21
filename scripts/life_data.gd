extends RefCounted

const AREAS := ["culture_grove","culture_ember","culture_sanctuary","culture_market"]
const NAMES := ["月葉林居","爐火守望","雲泉靈修院","星落共榮市集"]
const GOODS := ["moon_cloth","honey_tea","wool_blanket","jade_charm","star_lantern"]
const PRODUCTS := {
	"moon_cloth":{"name":"月絨雲錦","price":175,"icon":5},
	"honey_tea":{"name":"蜂蜜春茗","price":195,"icon":4},
	"wool_blanket":{"name":"苔絨暖毯","price":240,"icon":3},
	"jade_charm":{"name":"青玉護符","price":290,"icon":6},
	"star_lantern":{"name":"星露靈燈","price":220,"icon":7},
}
const FEES := {"grain_feed":0,"herb_feed":0,"moon_cloth":8,"honey_tea":8,"wool_blanket":10,"jade_charm":12,"star_lantern":10,"irrigator":20}
const ORDER := ["grain_feed","herb_feed","moon_cloth","honey_tea","wool_blanket","jade_charm","star_lantern","irrigator"]
const RECIPES := {
	"grain_feed":{"name":"穀物照料飼料","area":"farm","output":20,"needs":[["produce","wheat",1]]},
	"herb_feed":{"name":"草葉照料飼料","area":"farm","output":6,"needs":[["materials","herb",1]]},
	"moon_cloth":{"name":"月絨雲錦","area":"culture_grove","output":1,"needs":[["ranch","rabbit",1],["ranch","worm",1]]},
	"honey_tea":{"name":"蜂蜜春茗","area":"culture_sanctuary","output":1,"needs":[["ranch","bee",1],["produce","tea",1]]},
	"wool_blanket":{"name":"苔絨暖毯","area":"culture_ember","output":1,"needs":[["ranch","sheep",2]]},
	"jade_charm":{"name":"青玉護符","area":"culture_sanctuary","output":1,"needs":[["ranch","deer",1],["materials","stone",2]]},
	"star_lantern":{"name":"星露靈燈","area":"culture_market","output":1,"needs":[["ranch","carp",1],["ranch","rabbit",1],["materials","wood",2]]},
	"irrigator":{"name":"符玉灌溉器","area":"culture_ember","output":1,"needs":[["ranch","deer",1],["ranch","sheep",1],["materials","stone",4]]},
}
const REQUESTS := {
	"edric":{"item":"duck","reward":42,"purpose":"守橋人的早餐"},
	"lyria":{"item":"bee","reward":80,"purpose":"花圃的甜香"},
	"borin":{"item":"sheep","reward":114,"purpose":"工坊的保暖襯墊"},
	"yunji":{"item":"carp","reward":122,"purpose":"記錄靈泉回聲"},
	"suyue":{"item":"worm","reward":82,"purpose":"包紮藥袋的細絲"},
	"qinglin":{"item":"deer","reward":270,"purpose":"歸還山林的印記"},
}
const STORIES := {
	"edric":{"title":"橋上的一盞燈","pages":["艾德里克把盾靠在石欄旁，向你展示早已磨平的舊徽章。\n\n「以前我只會等命令。來到雲橋後，我才知道，修好一段圍欄也能保護別人。」他望向正在覓食的家禽，笑得有些靦腆。","你把一盞小燈放到橋頭。他仔細繫好燈繩，約定每晚巡路時替大家照看。\n\n「你的莊園讓人想回家。我的工作，就是讓回家的路一直亮著。」"]},
	"lyria":{"title":"種子不問來處","pages":["莉莉雅打開育苗盒。精靈林裡的種子旁，並排放著一株東洲茶苗。\n\n「它們需要的土不太一樣，但可以共享同一口泉水。」她請你幫忙把較弱的幼苗移到樹蔭下。","新葉終於舒展，蜜翼蜂在兩株植物之間停了停。\n\n莉莉雅把空育苗盒交給你：「下次帶你喜歡的種子來。我們不用把所有樹種成一樣，也能一起長成森林。」"]},
	"borin":{"title":"錘聲之外","pages":["博林的工作檯上沒有武器，只有一只裂開的水槽。\n\n「符文能保存力量，木頭卻記得使用它的人。」他摸著老水槽上的磨痕，說起祖父曾替整座村莊修理農具。","你幫他磨平最後一根木刺，綿羊便安心低頭飲水。\n\n博林收起錘子：「等你備好玉角和羊毛，我們再做一台灌溉器。真正好的工藝，應該讓日子輕鬆一些。」"]},
	"yunji":{"title":"留在此地的風","pages":["雲霽的竹卷畫滿山川，唯獨雲橋那一頁仍留著空白。\n\n「我總是記下遠處的景色，卻很少停下來問近處的人過得如何。」他邀你沿靈泉走一小段路。","你們沒有找到新的秘境，只看見魚群避開急流，又慢慢游回暖水。\n\n雲霽在空白頁寫下今天的日期：「這次先記人，再記路。我想在雲橋多住些日子。」"]},
	"suyue":{"title":"藥袋上的結","pages":["素月正在拆開一只舊藥袋，狐尾輕輕掃過椅腳。\n\n「以前有人見到我的耳朵，便不願收下藥。青禾卻先問我，路上冷不冷。」她把新曬好的藥草分成小份。","你用雲錦絲替藥袋打好結，準備送到守橋的休息棚。\n\n素月把另一只留給你：「不用等到疲倦才休息。照料莊園的人，也值得被好好照料。」"]},
	"qinglin":{"title":"自然落下的禮物","pages":["青麟蹲在一處落葉旁，指給你看鹿群留下的蹄印。\n\n「山林的禮物不會每天出現。等待，也是照料的一部分。」你們替小鹿清開擋住水槽的細枝。","一枚自然落下的玉角躺在樹根邊。青麟沒有急著拾起，而是先確認鹿群已平安離開。\n\n「記住今天的安靜。願我們需要的，永遠不多於山林願意給的。」"]},
}
