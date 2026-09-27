# 크레딧

## 기획
- 원안 기획서: **2 BADDIES**, 13기 이서연 (잠긴 대저택, 좀도둑과 수배범, 제한 시간, 엔딩 표)

## 그림 (`assets/art/`)
| 쓰인 곳 | 원본 | 라이선스 |
|---|---|---|
| 바닥, 벽, 문, 창문, 책장, 벽난로, 금고, 옷장, 화장대, 나무와 울타리 | "Roguelike RPG Pack" by Kenney | CC0: https://kenney.nl/assets/roguelike-rpg-pack |
| 식탁, 의자, 소파, 피아노, 부엌 찬장, 가스레인지, 깔개, 액자, 촛대, 화분, 빨랫줄 | "Roguelike Indoors" by Kenney | CC0: https://kenney.nl/assets/roguelike-indoors |

아래 그림은 이 게임을 위해 코드로 직접 찍었다 (Kenney 색감에 맞춤). 만드는 코드는 `tools/` 에 있다.
- 인물 걷기 그림 (오만복, 곽두철, 경찰, 노부부): `tools/chars.py`
- 대화창 얼굴 그림 (표정 4가지씩): `tools/portraits.py`
- Kenney 묶음에 없는 소품 (철제 셔터, 보안 단말기, CCTV 책상, 텔레비전, 보일러, 석탄 구멍 쇠창살, 공구함, 세탁기, 욕조, 변기, 약장, 냉장고, 계단, 전등, 침대, 가방, 컵라면, 신문, 달력, 사진, 작은 소품들)과 아이템 그림: `tools/draw.py`
- 첫 화면 달밤의 별장: `tools/title_art.py`

## 글꼴 (`assets/fonts/`)
| 파일 | 원본 | 라이선스 |
|---|---|---|
| `Galmuri11.ttf`, `Galmuri9.ttf` | 갈무리 by 이민서 (quiple) https://github.com/quiple/galmuri | SIL OFL 1.1 (`Galmuri-LICENSE.txt`). 자주 쓰는 한글 2,350자와 게임 글에 쓰인 글자만 남겨 줄였다 (`tools/subset_fonts.py`) |

## 효과음 (`assets/sfx/`)
| 파일 | 원본 | 라이선스 |
|---|---|---|
| `door_open`, `door_close`, `pick`, `cloth`, `coins`, `lock_click`, `latch`, `bonk`, `knife`, `book_open`, `page`, `book_close`, `creak1~2`, `chop` | "RPG Audio" by Kenney | CC0: https://kenney.nl/assets/rpg-audio |
| `step_*`, `shutter1~2`, `metal`, `punch`, `thud`, `glass`, `wood_hit`, `plank` | "Impact Sounds" by Kenney | CC0: https://kenney.nl/assets/impact-sounds |
| `ui_*`, `tick`, `success`, `fail`, `beep`, `buzz`, `notice`, `pluck`, `scratch`, `text`, `drop`, `glitch` | "Interface Sounds" by Kenney | CC0: https://kenney.nl/assets/interface-sounds |
| `jingle_*` | "Music Jingles" by Kenney | CC0: https://kenney.nl/assets/music-jingles |
| `alarm`, `siren`, `yelp` | "Sirens and Alarm Noise" by aquinn (OpenGameArt), 필요한 구간만 잘라 씀 | CC0: https://opengameart.org/content/sirens-and-alarm-noise |

## 배경 음악 (`assets/music/`)
| 파일 | 원곡 | 라이선스 |
|---|---|---|
| `title.ogg` | "Jazzy blues" by LushoGames (OpenGameArt) | CC0: https://opengameart.org/content/jazzy-blues |
| `sneak.ogg` | "Covert Operations" by artisticdude (OpenGameArt) | CC0: https://opengameart.org/content/covert-operations |
| `chase.ogg` | "Catch me if you can!" by poinl (OpenGameArt) | CC0: https://opengameart.org/content/catch-me-if-you-can |
| `tension.ogg` | "dodging_lights" from "Sneaky Music Pack" by Umplix (OpenGameArt) | CC0: https://opengameart.org/content/sneaky-music-pack |

음악은 모두 OGG 로 바꾸고 소리 크기를 맞췄다.
