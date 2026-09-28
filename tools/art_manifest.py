"""VARCO 시트를 어떻게 잘라 어디에 쓸지. tools/varco_cut.py 가 읽는다.

가구 시트: 읽는 차례(왼쪽 위부터)대로 (이름, 상자 너비, 상자 높이, 방식). 이름이 None 이면 버린다.
방식
  fit   : 상자 안에 비율을 지켜 넣고 바닥 가운데에 붙인다 (가구)
  wall  : 상자 안에 비율을 지켜 넣고 아래 가운데에 붙인다 (벽에 거는 것)
  floor : 상자 가운데에 넣는다 (깔개, 계단)
  on    : 32x32 안에 20px 크기로, 가구 윗면에 놓인 것처럼 (작은 소품)
  on_high : 키 큰 가구(세탁기) 윗면에 기대 놓은 것
  span  : 상자 너비를 꽉 채운다
다섯째 칸 "left_half": 그림의 왼쪽 반만 쓴다 (두 토막으로 나온 울타리에서 한 토막)
"""

PROPS = {
    "props_a": [
        ("fireplace", 32, 64, "wall"), ("piano", 64, 64, "fit"), ("armchair", 32, 64, "fit"),
        ("sofa", 64, 64, "fit"), ("bookshelf", 32, 64, "wall"), ("tv_off", 32, 44, "fit"),
        ("armchair_green", 32, 64, "fit"), ("plant", 32, 48, "fit"), ("floor_lamp", 32, 64, "fit"),
        ("rug_orange", 96, 64, "floor"), ("nightstand", 32, 44, "fit"), ("cuckoo_clock", 30, 60, "wall"),
    ],
    "P2": [
        (None, 0, 0, ""), ("chair_down", 32, 40, "fit"), (None, 0, 0, ""),
        ("chair_left", 32, 40, "fit"), ("chair_right", 32, 40, "fit"), ("cabinet_tall", 32, 64, "fit"),
        ("window_arch", 32, 64, "wall"), ("window", 32, 32, "wall"), ("candelabra", 32, 32, "on"),
        ("on_silver_candle", 32, 32, "on"), ("on_glass", 32, 32, "on"), ("portrait_tall", 32, 64, "wall"),
    ],
    "P3": [
        ("counter", 32, 40, "fit"), ("counter_drawers", 32, 40, "fit"), ("counter_sink", 32, 40, "fit"),
        ("counter_fruit", 32, 40, "fit"), ("counter_bottles", 32, 40, "fit"), ("counter_dishes", 32, 40, "fit"),
        ("stove", 32, 64, "fit"), ("fridge", 32, 64, "fit"), ("hanging_pans", 32, 32, "wall"),
        ("hanging_pan_one", 32, 32, "wall"), ("on_knife_block", 32, 32, "on"), ("on_knife_block_empty", 32, 32, "on"),
    ],
    "P4": [
        ("wardrobe", 32, 64, "fit"), ("vanity", 32, 64, "fit"), ("dresser", 32, 40, "fit"),
        ("bed_double", 64, 72, "fit"), ("bed_messy", 32, 72, "fit"), ("table_big", 96, 72, "fit"),
        ("safe", 32, 36, "fit"), ("globe_statue", 32, 48, "fit"), ("bookshelf2", 32, 64, "wall"),
        ("painting_map", 64, 32, "wall"), ("painting_wide", 64, 32, "wall"), ("on_jewelry_box", 32, 32, "on"),
    ],
    "P5": [
        ("bathtub", 32, 68, "fit"), ("toilet", 32, 40, "fit"), ("basin", 32, 44, "fit"),
        ("med_cabinet", 32, 32, "wall"), ("mirror_tall", 32, 64, "wall"), ("painting_green", 28, 26, "wall"),
        ("painting_orange", 28, 26, "wall"), ("painting_teal", 28, 26, "wall"), ("portrait_tall2", 32, 64, "wall"),
        ("photo_wedding", 24, 28, "wall"), ("photo_family", 24, 28, "wall"), ("runner", 32, 96, "floor"),
    ],
    "P6": [
        ("console", 32, 48, "fit"), ("console_open", 32, 48, "fit"), ("cctv", 64, 72, "fit"),
        ("washer", 32, 40, "fit"), ("clothesline", 96, 64, "wall"), ("table_small", 32, 36, "fit"),
        ("table_round", 32, 36, "fit"), ("boxes", 32, 40, "fit"), ("shelf_tall", 32, 64, "fit"),
        ("bulb_on", 32, 32, "wall"), ("bulb_off", 32, 32, "wall"), ("runner_green", 32, 96, "floor"),
    ],
    "P7": [
        ("boiler", 64, 80, "fit"), ("chute", 64, 64, "wall"), ("chute_open", 64, 64, "wall"),
        ("tool_cabinet", 32, 64, "fit"), ("tool_cabinet_open", 32, 64, "fit"), ("tool_cabinet_broken", 32, 64, "fit"),
        ("coal", 32, 32, "fit"), ("chest", 32, 36, "fit"), ("on_crowbar", 32, 32, "floor"),
        ("bag", 32, 32, "fit"), (None, 0, 0, ""), ("newspaper", 32, 32, "floor"),
    ],
    "P8": [
        ("hedge", 32, 36, "fit", "left_half"), (None, 0, 0, ""), (None, 0, 0, ""),
        ("bush", 32, 32, "fit"), ("tree", 48, 80, "fit"), ("tree_round", 40, 48, "fit"),
        ("flowers", 32, 32, "fit"), ("stairs_up", 64, 64, "floor"), ("stairs_down", 64, 64, "floor"),
        ("on_flashlight", 32, 32, "on"), ("on_gloves", 32, 32, "on"), ("on_rope", 32, 32, "on"),
    ],
    "P9": [
        ("on_oil", 32, 32, "on"), ("on_tape", 32, 32, "on"), ("on_glasses", 32, 32, "on"),
        ("card", 32, 32, "on"), ("rug_round", 64, 32, "floor"), ("plant2", 32, 44, "fit"),
        (None, 0, 0, ""), ("sconce", 32, 32, "wall"), ("table_lamp", 32, 32, "on"),
        ("coat_stand", 32, 64, "fit"), ("shoe_rack", 32, 32, "fit"), ("umbrella_stand", 32, 40, "fit"),
    ],
    # 다시 뽑은 것: 의자 없는 식탁, 뒤돌아선 의자, 뚜껑 닫힌 컵라면, 켜진 텔레비전
    "P10": [
        ("table_long", 128, 48, "fit"), ("chair_up", 32, 40, "fit"), ("ramen", 32, 32, "fit"), ("tv_on", 32, 44, "fit"),
    ],
}
GRIDS = {"P10": (2, 2)}   # 나머지는 4 x 3

ICONS = {
    "I1": ["lockpick", "flashlight", "tape", "compact", "ash", "fingerprint", "knife", "pan",
           "rope", "gloves", "oil", "pills", "sandwich", "whiskey", "crowbar", "jack"],
    "I2": ["bulb", "diary", "memo", "card", "manual", "newspaper", "necklace", "gold",
           "cash", "silver_candle", "watch", "notebook", "photo", None, None, None],
}
ICON = 24
# 아이콘 시트 칸 -> 세상에 놓는 소품 (칸 번호, 이름, 상자, 방식)
ICON_PROPS = {"I2": [(11, "on_notepad", 32, 44, "on_high")]}

CHARS = {"C1": "thief", "C2": "crook"}
# 방향마다 시트의 몇째 줄을 쓸지 (줄, 좌우 뒤집기). 옆모습 줄의 방향이 섞여 나와서 한쪽을 뒤집어 쓴다.
CHAR_ROWS = {
    "C1": {"down": (0, False), "left": (1, True), "right": (1, False), "up": (3, False)},
    "C2": {"down": (0, False), "left": (1, False), "right": (2, False), "up": (3, False)},
}
CHAR_W, CHAR_H = 32, 48

# 초상화: 2x2 시안에서 (칸 순서대로 표정)
PORTRAITS = {"p_thief_a": ("thief", ["normal", "nervous", "smile", "shock"]),
             "p_crook_a": ("crook", ["normal", "angry", "grin", "soft"])}
FACE = 84

# 바닥: 2x2 (왼쪽 위, 오른쪽 위, 왼쪽 아래, 오른쪽 아래) -> 128x128 무늬 (32px 타일 4x4)
FLOORS = {
    "tex_a": ["floor_parquet", None, "floor_greytile", "floor_concrete"],
    "T1": ["floor_honey", "floor_marble", "floor_carpet", "floor_worn"],
    "T2": ["floor_walnut", "floor_checker", "floor_bath", "floor_lino"],
    "T3": ["grass", "dirt", "floor_slab", "floor_deck"],
}
FLOOR_PX = 128

# 벽면: 가로 띠 네 줄 (시안 tex_a 는 오른쪽 위 칸 하나) -> 256x64 (32px 타일 8칸 x 2줄)
WALLS = {
    "tex_a": ["wall_stripe"],
    "W1": ["wall_burgundy", "wall_beige", "wall_subway", "wall_rose"],
    "W2": ["wall_green", "wall_mustard", "wall_bluetile", "wall_paint"],
    "W3": ["wall_brick", "wall_soot", "wall_plank", "wall_panel"],
}
WALL_W, WALL_H = 256, 64
