class_name Endings
extends RefCounted
## 엔딩 15가지. 기획서의 엔딩 표 12칸에, 표에 없던 경우(그의 배신, 자기 덫)를 더했다.

const ORDER := ["friend", "two_baddies", "tale", "rich", "revenge_out", "perfect", "fugitive",
		"loyal", "broke", "snitch", "murder", "revenge_release", "killed", "backstab", "slip"]

const TITLE := {
	"friend": "친구 엔딩",
	"two_baddies": "두 악당 엔딩",
	"tale": "무용담 엔딩",
	"rich": "벼락부자 엔딩",
	"revenge_out": "보복 엔딩",
	"perfect": "완전범죄 엔딩",
	"fugitive": "도망자 엔딩",
	"loyal": "의리 엔딩",
	"broke": "거지 엔딩",
	"snitch": "고발 엔딩",
	"murder": "살인죄 엔딩",
	"revenge_release": "석방, 그리고 보복 엔딩",
	"killed": "사망 엔딩",
	"backstab": "뒤통수 엔딩",
	"slip": "자업자득 엔딩",
}

## 엔딩 모음에서 아직 못 본 엔딩에 붙는 귀띔
const HINT := {
	"friend": "끝까지 믿는 사이로, 빈손으로 함께 나간다면",
	"two_baddies": "끝까지 믿는 사이로, 주머니도 두둑하게 함께 나간다면",
	"tale": "아무것도 훔치지 않고 빠져나간다면",
	"rich": "훔친 것을 챙겨 빠져나간다면",
	"revenge_out": "그를 해치거나 버리고 혼자 빠져나간다면",
	"perfect": "흔적 없이 그를 없앤다면",
	"fugitive": "흔적을 남긴 채 그를 없앤다면",
	"loyal": "믿는 사이로 함께 붙잡힌다면, 주머니는 두둑하게",
	"broke": "훔친 것 없이 붙잡힌다면",
	"snitch": "훔친 것을 들고 붙잡힌다면",
	"murder": "그를 없애고도 나가지 못한다면",
	"revenge_release": "그를 해치고, 훔친 것 없이 붙잡힌다면",
	"killed": "화난 그에게 두 번 붙잡힌다면",
	"backstab": "믿음이 바닥인 사람을 먼저 올려 보낸다면",
	"slip": "자기가 놓은 덫에",
}


static func number(id: String) -> int:
	return ORDER.find(id) + 1


static func money(n: int) -> String:
	if n >= 10000:
		return "%d억 %d만원" % [n / 10000, n % 10000] if n % 10000 != 0 else "%d억 원" % (n / 10000)
	return "%d만원" % n


static func lines(id: String) -> Array:
	var loot := money(Game.loot_total())
	var together := Game.escaped_with_crook
	var heard_daughter := Game.count("story") >= 3
	var crook_gone := Game.flag("crook_escaped")
	match id:
		"friend":
			var out := ["둘은 석탄 가루를 뒤집어쓴 채 산길을 뛰어 내려갔다. 등 뒤로 경찰차 불빛이 별장 앞에 모여들었다." if Game.flag("chute_open") or not Game.flag("front_open") else "둘은 현관을 박차고 나가 산길을 뛰어 내려갔다. 등 뒤로 경찰차 불빛이 별장 앞에 모여들었다."]
			out.append("갈림길에서 곽두철이 먼저 멈춰 섰다. '여기서 헤어지자. 같이 다니면 둘 다 잡힌다.'")
			if heard_daughter:
				out.append("한 달 뒤, 모르는 번호로 사진 한 장이 왔다. 고등학교 교문 앞에서 멀리 찍은, 교복 입은 여자아이.")
				out.append("'수아 봤다. 이제 자수하러 간다. 너는 착하게 살아라. 두철'")
			else:
				out.append("한 달 뒤, 모르는 번호로 문자가 왔다. '나 자수한다. 그날 네 덕에 마음먹었다. 두철'")
			out.append("만복은 그날 태어나서 처음으로 이력서라는 걸 써 봤다.")
			return out
		"two_baddies":
			var out := ["둘은 산길을 뛰어 내려갔다. 주머니 속에서 %s어치 금붙이가 달그락거렸다." % loot]
			if not Game.loot_split.is_empty():
				out.append("약속대로 반씩 나눴다. 도둑들 사이에도 의리는 있는 법이다.")
			else:
				out.append("만복이 다 챙긴 걸 두철도 알았지만, 씩 웃고 모른 척해 주었다.")
			out.append("그 뒤로 전국의 부잣집 별장에 도둑이 들 때마다 뉴스에는 같은 말이 나왔다. '두 사람이 짜고 벌인 일로 보입니다.'")
			out.append("사람들은 둘을 이렇게 불렀다. 두 악당.")
			return out
		"tale":
			var out := ["만복은 빈손으로 산을 내려왔다. 다리가 후들거렸다."]
			if together:
				out.append("곽두철은 갈림길에서 손 한 번 흔들고 반대쪽 어둠으로 사라졌다. 끝까지 서먹한 사이였다.")
			elif crook_gone:
				out.append("그 수배범은 한발 먼저 빠져나갔다. 누가 더 빨랐는지는 따지지 않기로 했다.")
			else:
				out.append("집 안에 남은 그 수배범이 어떻게 됐는지는 다음 날 뉴스로 알았다.")
			out.append("그날 밤 이야기는 동네 포장마차의 단골 안줏거리가 됐다. '내가 말이야, 철문이 쾅 내려오는데...'")
			out.append("물론 아무도 믿지 않았다.")
			return out
		"rich":
			var out := ["주머니가 묵직했다. %s어치." % loot]
			if Game.loot_total() < 500:
				out.append("벼락부자라기엔 좀 모자랐다. 그래도 밀린 월세는 갚았다.")
			else:
				out.append("만복은 그 돈으로 작은 분식집을 차렸다. 가게 이름은 '행운분식'.")
			if together:
				out.append("곽두철과는 산 아래에서 헤어졌다. 제 몫을 못 챙긴 그가 뭐라고 중얼거렸는데, 못 들은 척했다.")
			out.append("가끔 텔레비전에 수배범 소식이 나오면 만복은 조용히 채널을 돌렸다.")
			return out
		"revenge_out":
			var out := ["만복은 혼자 산을 내려왔다. 등 뒤로 경찰이 별장을 에워쌌다."]
			if Game.left_behind:
				out.append("두고 온 곽두철은 경찰차 뒷자리에서 이를 갈았다. 믿었던 놈이 먼저 튀었다고.")
			elif Game.crook_state == "tied" or Game.crook_state == "locked":
				out.append("꽁꽁 갇혀 있던 곽두철은 그대로 경찰에게 넘겨졌다. 끌려가면서 그는 만복의 얼굴을 똑똑히 기억해 두었다.")
			elif Game.flag("drugged"):
				out.append("수면제에서 깬 곽두철은 수갑부터 찼다. 누가 약을 탔는지는 금방 알았다.")
			else:
				out.append("곽두철은 경찰에게 붙잡혔다. 누가 자기를 쳤는지는 잊지 않았다.")
			out.append("몇 년 뒤, 비 오는 밤. 만복의 원룸 초인종이 울렸다.")
			out.append("문구멍 너머로 낯익은 흉터가 보였다.")
			return out
		"perfect":
			if Game.flag("trap_killed"):
				return ["경찰은 지하 계단 밑에서 공개수배범의 시신을 찾았다. 계단에는 식용유가, 전등에는 전구가 없었다.",
					"'숨어 지내던 수배범, 어두운 계단에서 실족.' 신문에는 딱 한 줄 났다.",
					"만복은 그 뒤로 계단을 내려갈 때마다 난간을 꽉 잡는다.",
					"아무도 모른다. 만복만 안다."]
			return ["경찰은 별장에서 공개수배범의 시신을 찾았다. 흉기도, 지문도 없었다.",
				"수배범끼리 다툰 것으로 보고 수사가 이어졌지만, 사건은 끝내 미제로 남았다.",
				"만복은 그 뒤로 목장갑만 보면 속이 울렁거린다.",
				"아무도 모른다. 만복만 안다."]
		"fugitive":
			return ["산을 내려오는 내내 손이 떨렸다.",
				"사흘 뒤, 뉴스에 새 얼굴이 떴다. '강도상해범 살해 용의자 오만복(31) 공개수배.'",
				"칼자루에 남은 지문 하나면 충분했다.",
				"이제 만복이 숨을 차례였다. 어느 산골 빈 별장에 몰래 들어가서, 라면을 먹으면서."]
		"loyal":
			return ["경찰이 들이닥치자 곽두철이 먼저 두 손을 들었다.",
				"'이 녀석은 내가 끌고 들어온 인질이오. 물건 턴 것도 다 나고.'",
				"경찰은 겁에 질린 척 떠는 만복의 주머니까지는 뒤지지 않았다. %s어치가 그대로 들어 있었다." % loot,
				"몇 달 뒤, 만복은 교도소 면회실에서 두철에게 영치금을 넣었다. 둘만 아는 비밀과 함께."]
		"broke":
			var out := []
			if crook_gone or Game.betrayed_by_him:
				out.append("집 안에는 만복 혼자였다. 경찰은 만복의 말을 반쯤 믿어 주었다. 주머니에서 나온 게 자물쇠 따개뿐이었으니까.")
			elif Game.coop_ever:
				out.append("곽두철은 순순히 수갑을 찼다. '이 녀석은 인질이오.' 한마디를 남기고.")
			else:
				out.append("경찰은 수배범을 붙잡고, 구석에서 떨고 있던 만복을 인질로 여겼다.")
			out.append("훔친 게 하나도 없으니 죄를 묻기도 애매했다. 만복은 며칠 만에 풀려났다.")
			out.append("풀려나던 날, 만복의 지갑에는 버스비 천이백 원이 남아 있었다.")
			return out
		"snitch":
			var out := []
			if Game.hostile and (Game.crook_state == "tied" or Game.crook_state == "locked"):
				out.append("갇힌 채로도 곽두철은 목청이 컸다. '저놈이 이 집 턴 도둑놈이오! 주머니 뒤져 보쇼!'")
			elif Game.coop_ever or Game.hostile:
				out.append("경찰 앞에서 곽두철이 턱으로 만복을 가리켰다. '저 녀석 주머니나 뒤져 보쇼.'")
			else:
				out.append("경찰이 몸수색을 하자 만복의 주머니에서 금붙이가 쏟아져 나왔다.")
			out.append("주머니에서 나온 것만 %s어치." % loot)
			out.append("만복은 특수절도로 구속됐다. 곽두철과 같은 호송차를 타고서." if not crook_gone else "만복은 특수절도로 구속됐다. 진짜 수배범은 놓치고 좀도둑만 잡은 셈이었다.")
			return out
		"murder":
			return ["경찰은 별장에서 두 사람을 찾았다. 한 사람은 차갑게 식어 있었고, 한 사람은 벌벌 떨고 있었다.",
				"좀도둑으로 들어간 만복은 살인범이 되어 나왔다.",
				"재판정에서 만복은 이 말만 되풀이했다. '20분이면 될 줄 알았어요.'"]
		"revenge_release":
			return ["만복은 곽두철에게 붙잡혀 있던 인질인 척했다. 훔친 게 없으니 경찰도 믿어 주었다.",
				"곽두철은 징역 12년을 받았다. 법정을 나서며 그는 방청석의 만복을 똑바로 쳐다봤다.",
				"12년 뒤, 만복이 차린 작은 가게 앞에 덩치 큰 손님이 섰다.",
				"'오랜만이다, 좀도둑.'"]
		"killed":
			return ["곽두철의 손아귀는 생각보다 훨씬 셌다.",
				"경찰이 도착했을 때 별장에는 수배범 한 명과 좀도둑 한 명이 있었다. 그중 한 사람만 숨을 쉬고 있었다.",
				"만복의 이름은 그날 뉴스 맨 끝에 아주 작게 나왔다."]
		"backstab":
			var out := ["쇠창살이 쾅 닫히던 소리가 아직도 귀에 선하다."]
			if Game.escaped:
				out.append("만복은 결국 제 힘으로 빠져나왔다. 하지만 그날 이후로는 누구도 먼저 올려 보내지 않는다.")
			else:
				out.append("경찰은 석탄 구멍 아래 주저앉아 있던 만복을 찾아냈다.")
			if Game.flag("loot_stolen_back"):
				out.append("훔친 것은 몽땅 곽두철 주머니로 들어갔다. 덕분에 만복의 죄는 가벼워졌으니, 고마워해야 하나.")
			out.append("곽두철은 끝내 잡히지 않았다. 가끔 만복 앞으로 보낸 사람 없는 엽서가 온다. '고맙다, 좀도둑.'")
			return out
		"slip":
			return ["계단에 기름을 부은 사람도 만복이었고, 전구를 뺀 사람도 만복이었다.",
				"그리고 그 계단을 제일 먼저 내려간 사람도 만복이었다.",
				"경찰 보고서에는 이렇게 적혔다. '침입자, 어두운 계단에서 미끄러짐. 자업자득.'"]
	return ["..."]


static func tone(id: String) -> String:
	if id in ["friend", "two_baddies", "tale", "rich", "loyal"]:
		return "good"
	if id in ["broke", "backstab", "perfect"]:
		return "mid"
	return "bad"
