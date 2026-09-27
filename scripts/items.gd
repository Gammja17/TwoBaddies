class_name Items
extends RefCounted
## 주머니에 들어가는 것들. kind: tool, clue, loot, food, weapon

const DB := {
	"lockpick": {"name": "자물쇠 따개", "icon": "lockpick", "kind": "tool",
		"desc": "만복의 밥줄. 서랍이나 보석함 정도의 작은 자물쇠는 이걸로 딴다."},
	"notebook": {"name": "만복의 수첩", "icon": "notebook", "kind": "tool",
		"desc": "일할 때 꼭 챙기는 수첩. 눈여겨본 것은 여기 적어 둔다."},
	"flashlight": {"name": "손전등", "icon": "flashlight", "kind": "tool",
		"desc": "다용도실 선반에서 챙겼다. 불 꺼진 지하도 이게 있으면 다닐 만하다."},
	"tape": {"name": "투명 테이프", "icon": "tape", "kind": "tool",
		"desc": "서재 책상에 있던 테이프. 끈적한 면에 지문이 잘 묻어난다."},
	"compact": {"name": "분첩", "icon": "compact", "kind": "tool",
		"desc": "할머니 화장대의 분첩. 고운 가루가 들어 있다. 지문 위에 뿌리면 무늬가 드러난다."},
	"ash": {"name": "벽난로 재 한 줌", "icon": "ash", "kind": "tool",
		"desc": "벽난로에서 긁어 온 고운 재. 분가루 대신 쓸 수 있다."},
	"fingerprint": {"name": "할아버지 지문 테이프", "icon": "fingerprint", "kind": "tool",
		"desc": "가루를 뿌려 드러난 지문을 테이프로 떠 냈다. 현관 인식기에 대 보면 된다."},
	"knife": {"name": "식칼", "icon": "knife", "kind": "weapon",
		"desc": "주방 칼꽂이에서 뽑은 식칼. 들고만 있어도 손이 떨린다."},
	"pan": {"name": "프라이팬", "icon": "pan", "kind": "weapon",
		"desc": "무쇠 프라이팬. 사람 뒤통수를 치면 한동안 정신을 잃는다. 죽지는 않는다."},
	"rope": {"name": "빨랫줄", "icon": "rope", "kind": "tool",
		"desc": "다용도실 빨랫줄. 정신 잃은 사람 하나 묶기에는 충분하다."},
	"gloves": {"name": "목장갑", "icon": "gloves", "kind": "tool",
		"desc": "다용도실에서 찾은 목장갑. 끼고 있으면 만지는 것마다 지문이 남지 않는다."},
	"oil": {"name": "식용유", "icon": "oil", "kind": "tool",
		"desc": "주방 식용유 한 병. 바닥에 부으면 무척 미끄럽다."},
	"pills": {"name": "수면제", "icon": "pills", "kind": "tool",
		"desc": "욕실 약장의 수면제. 할아버지 이름이 적힌 처방전이 붙어 있다. 먹을 것에 타면 모른다."},
	"sandwich": {"name": "샌드위치", "icon": "sandwich", "kind": "food",
		"desc": "냉장고에 있던 샌드위치. 할머니 글씨로 '영감 야식'이라고 적혀 있다."},
	"sandwich_laced": {"name": "샌드위치 (수면제)", "icon": "sandwich", "kind": "food",
		"desc": "수면제를 으깨 넣은 샌드위치. 겉보기에는 멀쩡하다."},
	"whiskey": {"name": "위스키", "icon": "whiskey", "kind": "food",
		"desc": "식당 장식장의 비싼 위스키. 반쯤 비어 있다."},
	"whiskey_laced": {"name": "위스키 (수면제)", "icon": "whiskey", "kind": "food",
		"desc": "수면제를 녹인 위스키. 맛이 조금 쓸지도 모른다."},
	"crowbar": {"name": "쇠지렛대", "icon": "crowbar", "kind": "weapon",
		"desc": "지하 창고의 빠루. 문짝 하나쯤은 뜯어낸다. 휘두르면 무기도 된다."},
	"jack": {"name": "자동차 잭", "icon": "jack", "kind": "tool",
		"desc": "차 바퀴 갈 때 쓰는 잭. 무거운 것을 혼자서도 들어 올릴 수 있다."},
	"bulb": {"name": "전구", "icon": "bulb", "kind": "tool",
		"desc": "지하 계단 전등에서 빼낸 전구. 계단이 캄캄해졌다."},
	"diary": {"name": "할아버지의 일기장", "icon": "diary", "kind": "clue", "read": "diary",
		"desc": "서재 책장에 꽂혀 있던 낡은 일기장."},
	"memo": {"name": "할머니의 메모", "icon": "memo", "kind": "clue", "read": "memo",
		"desc": "화장대 서랍에 있던 메모 한 장."},
	"card": {"name": "생일 카드", "icon": "card", "kind": "clue", "read": "card",
		"desc": "손님방 탁자에 있던 카드. 손자 지훈이가 쓴 것 같다."},
	"manual": {"name": "보안 설명서", "icon": "manual", "kind": "clue", "read": "manual",
		"desc": "보안실 책상에 있던 방범 장치 설명서."},
	"newspaper": {"name": "신문", "icon": "newspaper", "kind": "clue", "read": "newspaper",
		"desc": "손님방 바닥에 굴러다니던 신문. 사흘 전 날짜다."},
	"necklace": {"name": "진주 목걸이", "icon": "necklace", "kind": "loot", "value": 900,
		"desc": "할머니 보석함의 진주 목걸이. 알이 굵다."},
	"gold": {"name": "금괴 두 개", "icon": "gold", "kind": "loot", "value": 4000,
		"desc": "서재 금고에 있던 금괴. 묵직하다."},
	"cash": {"name": "현금 봉투", "icon": "cash", "kind": "loot", "value": 300,
		"desc": "서재 책상 서랍의 돈 봉투. 겉에 '지훈이 등록금 보탬'이라고 적혀 있다."},
	"silver_candle": {"name": "은촛대", "icon": "silver_candle", "kind": "loot", "value": 150,
		"desc": "식당 식탁의 은촛대."},
	"watch": {"name": "금 회중시계", "icon": "watch", "kind": "loot", "value": 1200,
		"desc": "할아버지 협탁 서랍의 회중시계. 뚜껑 안쪽에 '1974. 10. 3. 처음 만난 날. 순애가'라고 새겨져 있다."},
}


static func name_of(id: String) -> String:
	return DB.get(id, {}).get("name", id)


static func info(id: String) -> Dictionary:
	return DB.get(id, {})


static func is_loot(id: String) -> bool:
	return DB.get(id, {}).get("kind", "") == "loot"


static func value(id: String) -> int:
	return int(DB.get(id, {}).get("value", 0))
