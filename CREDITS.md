# 크레딧

## 기획
- 원안 기획서: **2 BADDIES**, 13기 이서연 (잠긴 대저택, 좀도둑과 수배범, 제한 시간, 엔딩 표)

## 그림 (`assets/art/`)
인물 걷기 그림, 대화창 얼굴, 가구와 소품, 바닥과 벽지, 아이템 그림, 첫 화면 그림은 이 게임을 위해 VARCO 3D(gpt-image-2.5)로 뽑았다.
프롬프트는 `tools/art_prompts.py`, 잘라 쓰는 규칙은 `tools/art_manifest.py`, 잘라 낸 그림은 `art_src/` 에 있다.

아래는 아직 코드로 직접 찍은 그림을 두 배로 키워 쓴다. 만드는 코드는 `tools/` 에 있다.
- 철제 셔터, 옆벽 문, 열린 현관: `tools/draw.py`
- 벽 윗면과 그늘: `tools/build_art.py`

예전 판(16px)은 Kenney "Roguelike RPG Pack", "Roguelike Indoors" (CC0) 를 썼다. 새 그림이 없는 것이 생기면 여전히 이 묶음으로 채운다.

## 글꼴 (`assets/fonts/`)
| 파일 | 원본 | 라이선스 |
|---|---|---|
| `Galmuri14.ttf`, `Galmuri11.ttf` | 갈무리 by 이민서 (quiple) https://github.com/quiple/galmuri | SIL OFL 1.1 (`Galmuri-LICENSE.txt`). 자주 쓰는 한글 2,350자와 게임 글에 쓰인 글자만 남겨 줄였다 (`tools/subset_fonts.py`) |

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
