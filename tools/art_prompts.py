"""VARCO(gpt-image-2.5)로 그림을 뽑을 때 쓴 프롬프트. 다시 뽑거나 더 뽑을 때 여기서 고쳐 쓴다.

시트마다 id, 비율, 참고 그림, 프롬프트. 잘라 쓰는 규칙은 tools/art_manifest.py 에 있다.
"""

STYLE = (
    "Stylized mid-resolution pixel art with clearly visible square pixels, bold dark outlines, flat cel shading "
    "with three or four tones per color, a limited muted palette with warm accents, matte surfaces with no glossy "
    "highlights, no sparkles and no glow. Clean, purposeful shapes and restrained detail, like the art of a "
    "well-made modern indie game. No clusters of tiny dots, holes or rings."
)

PROPS_HEAD = (
    "A sprite sheet of separate objects for a top-down RPG in 3/4 overhead view (like RPG Maker interiors with "
    "32 pixel tiles), drawn in exactly the same style, scale and palette as the reference image, with the same "
    "lighting from the top-left. Each object is isolated with generous empty space around it on a flat pure "
    "magenta background (#FF00FF), arranged in a neat 4 by 3 grid, read left to right and top to bottom. "
    "The setting is a rich elderly Korean couple's mountain villa at night. The objects are:"
)
PROPS_TAIL = "No drop shadows on the background, no text, no labels, no numbers."


def props(items):
    body = " ".join("%d) %s." % (i + 1, t) for i, t in enumerate(items))
    return "%s\n\n%s %s %s" % (STYLE, PROPS_HEAD, body, PROPS_TAIL)


SHEETS = {
    "P2": ("4:3", "props", props([
        "a long wooden dining table for eight seen from the front in 3/4 view, four times wider than it is deep, "
        "with a plain cream table runner",
        "a wooden dining chair facing the viewer, backrest at the top",
        "the same wooden dining chair seen from behind, backrest toward the viewer",
        "the same wooden dining chair facing left",
        "the same wooden dining chair facing right",
        "a tall narrow glass-front liquor cabinet with whisky bottles on its shelves",
        "a tall arched window with thin curtains, showing a dark blue night sky and a pale moon",
        "a small square window with curtains, dark blue night outside",
        "a gold-plated three-armed candelabra with unlit candles",
        "a single real silver candlestick with an unlit candle",
        "a short whisky glass with a little amber whisky in it",
        "a tall framed oil portrait of an elderly Korean couple, a stern grandfather and a smiling grandmother",
    ])),
    "P3": ("4:3", "props", props([
        "a kitchen base cabinet with a wooden countertop, one tile wide",
        "the same kitchen cabinet with three drawers",
        "the same kitchen cabinet with a steel sink and faucet in the countertop",
        "the same kitchen cabinet with a bowl of fruit on the countertop",
        "the same kitchen cabinet with bottles of soy sauce and oil on the countertop",
        "the same kitchen cabinet with a stack of plates on the countertop",
        "a tall gas range with four burners and an oven, with a range hood above it",
        "a tall white two-door refrigerator with a paper calendar stuck on its door",
        "a wooden wall rack with a heavy cast-iron frying pan and two pots hanging from hooks",
        "the same wall rack with only the two pots, the frying pan gone and its hook empty",
        "a wooden knife block full of kitchen knives",
        "the same knife block with the biggest knife missing and its slot empty",
    ])),
    "P4": ("4:3", "props", props([
        "a tall wooden wardrobe with two doors, one tile wide and two tiles tall",
        "a vanity table with a tall oval mirror and a small powder compact on it, one tile wide and two tiles tall",
        "a low wooden chest of drawers",
        "a large double bed seen from above in 3/4 view, headboard at the top, two pillows, a neatly smoothed "
        "orange and cream blanket, two tiles wide and two tiles long",
        "a single bed seen from above in 3/4 view, headboard at the top, with a messy tangled cream blanket and a "
        "dented pillow, one tile wide and two tiles long",
        "a heavy dark wooden desk with scattered papers and a green banker's lamp, three tiles wide and two tiles deep",
        "a small steel safe with a four-digit keypad",
        "a white marble bust of an old man on a wooden pedestal",
        "a tall bookshelf with dark leather-bound books and one worn diary sticking out",
        "a wide framed antique map hung on a wall, twice as wide as tall",
        "a wide framed landscape painting of green mountains, twice as wide as tall",
        "a small wooden jewelry box with a brass lock",
    ])),
    "P5": ("4:3", "props", props([
        "a white bathtub seen from above in 3/4 view with its long side vertical, a shower curtain on a rod drawn "
        "along one side, one tile wide and two tiles long",
        "a white toilet seen from the front in 3/4 view",
        "a white pedestal wash basin with two toothbrushes in a cup",
        "a wall-mounted medicine cabinet with a mirror door",
        "a tall full-length mirror in a wooden frame",
        "a small framed painting of a green meadow",
        "a small framed painting of an orange sunset",
        "a small framed painting of a teal sea",
        "a tall narrow framed painting of misty mountains",
        "a small black and white wedding photo of a young couple in a simple frame",
        "a small color family photo in a frame: an elderly couple with a schoolboy between them",
        "a long narrow hallway runner rug with a red and cream pattern, seen from above, one tile wide and three "
        "tiles long",
    ])),
    "P6": ("4:3", "props", props([
        "a security keypad terminal on a short metal post with a small red screen, one tile wide and one and a half "
        "tiles tall",
        "the same security terminal with a green screen",
        "a desk with four small CCTV monitors showing grainy grey rooms, two tiles wide",
        "a front-loading washing machine",
        "a clothesline between two posts with a sweater and two shirts hanging, three tiles wide",
        "a small plain wooden table",
        "a small round wooden kitchen table",
        "a stack of taped cardboard boxes",
        "a tall metal storage shelf with paint cans and ramen boxes, one tile wide and two tiles tall",
        "a bare light bulb hanging from a cord, glowing warm",
        "the same hanging light bulb switched off, with an empty socket",
        "a long narrow hallway runner rug in green and cream, seen from above, one tile wide and three tiles long",
    ])),
    "P7": ("4:3", "props", props([
        "an old basement boiler with pipes and a small furnace door glowing orange, two tiles wide and two tiles tall",
        "a square coal chute opening high in a grey concrete wall, covered by a heavy iron grate, two tiles wide",
        "the same coal chute with the iron grate pushed up and propped open by a car jack",
        "a red metal tool cabinet with a padlock, one tile wide and two tiles tall",
        "the same red tool cabinet with its door open and empty inside",
        "the same red tool cabinet with its door bent and torn open",
        "a pile of black coal lumps",
        "an old wooden storage chest",
        "a steel crowbar lying on the floor",
        "an old olive military duffel bag",
        "a pile of empty instant noodle cups",
        "a folded newspaper lying on the floor",
    ])),
    "P8": ("4:3", "props", props([
        "a middle section of a neatly trimmed green hedge that continues on both sides",
        "the left end of the same hedge",
        "the right end of the same hedge",
        "a small round garden bush",
        "a tall pine tree, one tile wide and two tiles tall",
        "a small round ornamental shrub",
        "a small flower bed with muted flowers",
        "a wooden staircase going up, seen from above in 3/4 view, two tiles wide and two tiles long",
        "a staircase going down into darkness, seen from above, with a wooden railing, two tiles wide and two "
        "tiles long",
        "a black flashlight lying on its side",
        "a pair of white cotton work gloves",
        "a coiled length of clothesline rope",
    ])),
    "P9": ("4:3", "props", props([
        "a bottle of cooking oil",
        "a roll of clear sticky tape",
        "a pair of reading glasses",
        "a folded birthday card with a drawn cake",
        "a small round patterned rug seen from above, twice as wide as tall",
        "a small potted fern",
        "a small leafy potted plant",
        "a wall-mounted brass sconce lamp glowing warm",
        "a small table lamp with a cream shade",
        "a wooden coat stand with a hanging coat",
        "a low shoe rack with a few pairs of shoes",
        "an umbrella stand with two umbrellas",
    ])),
}

ICONS_HEAD = (
    "A sheet of 16 inventory item icons for a pixel-art escape game, drawn in the same style and palette as the "
    "reference image. Each icon is a single object, centered and filling most of its own square cell, on a flat "
    "pure magenta background (#FF00FF), arranged in a neat 4 by 4 grid, read left to right and top to bottom:"
)


def icons(items):
    body = " ".join("%d) %s." % (i + 1, t) for i, t in enumerate(items))
    return "%s\n\n%s %s No text, no labels, no numbers, no frames around the icons." % (STYLE, ICONS_HEAD, body)


SHEETS["I1"] = ("1:1", "props", icons([
    "a lock pick set of two thin metal picks", "a black flashlight", "a roll of clear tape",
    "a round powder compact", "a small heap of grey fireplace ash on a white cloth",
    "a strip of clear tape with a fingerprint on it", "a kitchen knife", "a cast-iron frying pan",
    "a coil of rope", "a pair of white cotton work gloves", "a bottle of cooking oil", "an orange pill bottle",
    "a sandwich wrapped in plastic", "a whisky bottle", "a steel crowbar", "a red car jack",
]))
SHEETS["I2"] = ("1:1", "props", icons([
    "a bare light bulb", "an old brown leather diary", "a handwritten memo note", "a birthday card",
    "a security system manual booklet", "a folded newspaper", "a pearl necklace", "two gold bars",
    "a paper cash envelope", "a silver candlestick", "a gold pocket watch", "a small spiral notebook with a pencil",
    "an old photograph", "a brass key", "a cheap flip phone", "a round coin",
]))


def walker(who, look):
    return (
        "%s\n\nA walking sprite sheet for a top-down RPG character in 3/4 overhead view, like classic JRPG and RPG "
        "Maker character sheets: exactly 4 rows and 3 columns of the SAME character on a flat pure magenta "
        "background (#FF00FF), evenly spaced, each figure centered in its cell with its feet at the bottom of the "
        "cell. Row 1 faces down toward the viewer, row 2 faces left, row 3 faces right, row 4 faces up with the "
        "back to the viewer. In every row, column 1 is standing still, column 2 is mid-step with the left foot "
        "forward, column 3 is mid-step with the right foot forward. About three heads tall, stylized but neither "
        "chibi nor realistic, full body visible. The character is %s: %s Match the face, hair and outfit colors "
        "of the reference portrait exactly. No text, no grid lines, no shadows on the background."
    ) % (STYLE, who, look)


SHEETS["C1"] = ("1:1", "thief", walker(
    "Oh Man-bok, a 31-year-old Korean small-time burglar",
    "slim build, charcoal knit beanie over short black hair, navy hoodie with light drawstrings, dark grey jeans, "
    "black sneakers."))
SHEETS["C2"] = ("1:1", "crook", walker(
    "Kwak Du-cheol, a 47-year-old burly Korean fugitive robber",
    "big broad build a head taller than an average man, buzz-cut black hair, short dark beard, a pale scar over "
    "his left eyebrow, worn brown leather jacket over a black t-shirt, dark work trousers, heavy brown boots."))

TEX_HEAD = (
    "A 2x2 grid of four seamless tileable top-down pixel art floor textures for a 32 pixel tile RPG interior, "
    "in the same style and palette as the reference image. Each texture is a flat square filling its whole "
    "quarter with no borders, frames, gaps or labels, and repeats seamlessly on all sides:"
)


def floors(tl, tr, bl, br):
    return "%s\n\n%s top-left %s, top-right %s, bottom-left %s, bottom-right %s. Night-time muted colors. No text." % (
        STYLE, TEX_HEAD, tl, tr, bl, br)


SHEETS["T1"] = ("1:1", "tex", floors(
    "warm honey-brown wooden floorboards running left to right", "beige and cream marble checkerboard tiles",
    "a dusty rose bedroom carpet with a very faint woven texture", "worn pale wooden floorboards with a few scuffs"))
SHEETS["T2"] = ("1:1", "tex", floors(
    "dark walnut floorboards running left to right", "cream and terracotta checkerboard kitchen tiles",
    "pale blue and white square bathroom tiles", "plain grey linoleum with a faint sheen-free texture"))
SHEETS["T3"] = ("1:1", "tex", floors(
    "short dark green lawn grass at night", "a packed brown dirt garden path",
    "large rough grey stone floor slabs", "a dark wooden deck of wide planks"))

WALL_HEAD = (
    "A sheet of four seamless horizontally tileable interior wall strips for a 3/4 top-down pixel art RPG with "
    "32 pixel tiles, in the same style and palette as the reference image. The image is four full-width "
    "horizontal bands stacked on top of each other, each band filling exactly a quarter of the image height, with "
    "no borders, frames or gaps. Each band shows a wall seen straight from the front from the floor up, and the "
    "pattern repeats seamlessly left to right:"
)


def walls(b1, b2, b3, b4):
    return "%s\n\n%s band 1 (top) %s; band 2 %s; band 3 %s; band 4 (bottom) %s. Night-time muted colors. No text, no furniture, no doors, no windows." % (
        STYLE, WALL_HEAD, b1, b2, b3, b4)


SHEETS["W1"] = ("1:1", "tex", walls(
    "deep burgundy wallpaper with a subtle vertical pattern above a dark wood wainscot and baseboard",
    "warm beige wallpaper above light oak wood panels and a baseboard",
    "white subway tiles above a band of blue tiles and a white tiled lower wall",
    "soft cream wallpaper with small muted rose sprigs spaced far apart above a white wainscot"))
SHEETS["W2"] = ("1:1", "tex", walls(
    "dark bottle-green wallpaper above dark walnut panels and a baseboard",
    "faded mustard yellow wallpaper above a simple wooden baseboard",
    "light blue ceramic wall tiles from floor to top with a darker blue border band near the bottom",
    "plain pale green painted concrete wall with a grey painted lower band"))
SHEETS["W3"] = ("1:1", "tex", walls(
    "a grey brick basement wall",
    "a sooty grey concrete basement wall with a few old pipes along the top",
    "white painted wooden wall planks above a grey baseboard",
    "dark wood paneling from floor to top"))

SHEETS["TITLE"] = ("16:9", "props", (
    "%s\n\nPixel art key visual for the title screen of a tense black-comedy escape game: a lonely two-story "
    "mountain villa at night under a large pale moon, dark pine trees on the hillside, iron security shutters "
    "pulled down over the ground-floor windows, one warmly lit window upstairs with a big man's silhouette in it, "
    "and a small burglar in a navy hoodie and beanie with a flashlight creeping near the back door. Wide 16:9 "
    "composition with the villa on the right half and empty dark sky on the left third for the title text. Deep "
    "blue night palette with warm yellow window light. No text, no letters, no logo." % STYLE))
