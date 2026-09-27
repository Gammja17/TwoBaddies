# 2 BADDIES (두 악당)

잠긴 별장에 갇힌 좀도둑과 수배범. 경찰이 오기까지 20분. 13기 이서연 기획서 "2 BADDIES"를 바탕으로 만든 도트 탈출 게임. Godot 4.7, 웹판(휴대폰, PC).

설계는 `docs/design.md`, 에셋 출처는 `CREDITS.md`.

## 조작
| | PC | 휴대폰 |
|---|---|---|
| 걷기 | 방향키, WASD | 왼쪽 방향 패드 |
| 뛰기 (발소리가 커짐) | Shift 누른 채 | B 누른 채 |
| 조사, 말 걸기, 대화 넘기기 | Z, 스페이스, 엔터 | A, 대화창 누르기 |
| 취소 | X | B |
| 주머니 | C, Tab | 주머니 |
| 멈춤 | Esc | II |

## 실행
Godot 에디터로 이 폴더를 열고 F5.

## 검사
```
godot --headless --fixed-fps 60 --path . res://tools/sim.tscn -- all    # 엔딩표, 곽두철 혼자 탈출, 협력, 비밀번호, 지문, 덫, 추격, 배신
godot --headless --fixed-fps 60 --path . res://tools/sim.tscn -- fuzz   # 모든 물건을 세 가지 상황에서 조사
```
화면 확인 (창이 뜨지 않는다): 디버그 웹판을 내보내고 `python tools/serve.py 18760 <폴더>` 로 띄운 뒤 `python tools/webdrive.py <plan.json> <폴더>` (헤드리스 크롬).

## 그림 다시 만들기
칸은 32px, 화면은 640x360. 그림은 VARCO 로 뽑은 시트를 잘라 쓴다 (`tools/art_prompts.py` 프롬프트).
뽑은 시트 원본과 Kenney 묶음은 `_packs/` (git 에 안 올림), 잘라 낸 그림은 `art_src/` (git 에 올림).
```
python tools/varco_cut.py      # _packs/varco/<시트>.png -> art_src/ (자르는 규칙: tools/art_manifest.py)
python tools/build_art.py      # art_src/ -> 타일, 소품, 아이템, 인물, 얼굴 아틀라스와 첫 화면 (없는 그림은 옛 16px 그림을 두 배로)
python tools/subset_fonts.py   # 글꼴 줄이기 (새 글자를 넣었으면)
python tools/preview_map.py <폴더> --grid   # 지도 미리보기
```

## 구조
- `data/map.txt`: 층별 지도 글자판. `#` 벽 윗면, `F` 벽면, `.` `,` `:` `_` 바닥, `D` 문, `B` 뒷문, `O` 현관
- `data/objects.json`: 가구와 소품 (자리, 그림, 층)
- `scripts/world.gd`: 지도 그리기 (방마다 바닥과 벽지), 방 찾기, 길찾기, 안개, 불빛
- `scripts/actor.gd`, `player.gd`, `crook.gd`: 칸 이동, 조작, 곽두철 AI
- `scripts/content.gd`: 물건마다 조사하면 일어나는 일, 퍼즐, 대화, 사건
- `scripts/endings.gd`: 엔딩 15가지 글
- `scripts/game.gd` (오토로드): 시간, 주머니, 호감도, 관계, 엔딩 판정, 저장
- `scripts/play.gd`: 한 판을 굴리는 쪽 (대본 실행, 시간 이벤트, 계단, 추격)
- `scripts/main.gd`: 첫 화면, 엔딩, 엔딩 모음, 멈춤, 웹 배경 처리
