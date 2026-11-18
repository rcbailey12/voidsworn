# Kept checkout scan

Read-only scan for issue 1113 on the Windows PC on Nov 18, 2026. Git returned a status for all 49 copies.
For each checkout the scan ran `git status --porcelain=v1 --ignored --untracked-files=all`
with optional index writes disabled. Counts are Git status entries, including repeated paths across copies.

The [path list](paths.txt) lists every status entry by kind. Each group in that file names the
copy IDs that contain every path in the group. The copy table below maps IDs to full directory names.
Ship entries are inventory only. The runner verifies their bytes against the shared build before allowing reuse.

## Counts by lane

| Kind | Code | `board` | `board_b` | `board_c` | `board_d` | Entries | Copies |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Copies scanned | | 15 | 10 | 12 | 12 |  | 49 |
| Campaign golden | CG | 240 | 210 | 270 | 330 | 1050 | 35 |
| Campaign out | CO | 256 | 224 | 288 | 352 | 1120 | 35 |
| Campaign log | CL | 8 | 7 | 9 | 11 | 35 | 35 |
| Rules golden | RG | 0 | 0 | 0 | 0 | 0 | 0 |
| Rules out | RO | 0 | 0 | 0 | 0 | 0 | 0 |
| Rules log | RL | 0 | 0 | 0 | 0 | 0 | 0 |
| Godot UIDs | UID | 1212 | 1032 | 0 | 0 | 2244 | 11 |
| Godot cache | GC | 16823 | 15173 | 0 | 240 | 32236 | 12 |
| Godot imports | IMP | 7060 | 6126 | 0 | 307 | 13493 | 12 |
| Python cache | PY | 99 | 120 | 4 | 5 | 228 | 16 |
| Ship files | SHIP | 1144 | 1090 | 0 | 306 | 2540 | 11 |
| Other ignored | OTHER | 982 | 741 | 0 | 181 | 1904 | 12 |
| Untracked | NEW | 3 | 0 | 34 | 1 | 38 | 3 |
| Tracked changes | EDIT | 5 | 0 | 11 | 0 | 16 | 3 |

Campaign output was present in 35 copies, including 11 of the 12 lane D copies. Ten lane D copies had only
campaign parity outputs. The other two held additional ignored files or an untracked file.
The 30 golden JSONL files and the 30 output JSONL files occurred together with `out/cmp.txt`,
`out/tables_check.json` and the campaign log in all of those copies. The rules output paths had zero
entries in this scan. Their ignore rules still cover outputs from earlier rules parity runs.
The other ignored group includes generated assets under `godot/gen/` and files under `.onboarding_checks/`.
It stays outside the file types added by this issue. The path list includes tracked changes and untracked files for review.

## Counts by copy

| ID | Lane | Kept directory | CG | CO | CL | RG | RO | RL | UID | GC | IMP | PY | SHIP | OTHER | NEW | EDIT |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 01 | board | `repo-kept-07c6123d6da743c4bd4fbccee6fbf1d0` | 0 | 0 | 0 | 0 | 0 | 0 | 204 | 2488 | 996 | 0 | 16 | 39 | 0 | 0 |
| 02 | board | `repo-kept-3bd3944fc4834d278bb62b9b3093f243` | 0 | 0 | 0 | 0 | 0 | 0 | 203 | 2797 | 1145 | 0 | 165 | 187 | 0 | 0 |
| 03 | board | `repo-kept-63035504f3fe4d1fb7eeb0e090a559ed` | 0 | 0 | 0 | 0 | 0 | 0 | 193 | 3067 | 1253 | 26 | 259 | 187 | 0 | 0 |
| 04 | board | `repo-kept-64b7f32ffa4849c7a4bd726da6ea4cb4` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 23 | 0 | 0 | 0 | 0 |
| 05 | board | `repo-kept-70f1a89ca7014f369e1696c81db59112` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 22 | 0 | 0 | 0 | 0 |
| 06 | board | `repo-kept-79f819ff302543b29659629a19b3a701` | 0 | 0 | 0 | 0 | 0 | 0 | 205 | 2668 | 1164 | 0 | 184 | 193 | 0 | 0 |
| 07 | board | `repo-kept-81506ef10ec64d3c96aa8cacc744b33c` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 08 | board | `repo-kept-836469265b074cdd9b34aa7964afd780` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 09 | board | `repo-kept-90abf105d7264e4199201f89edfc9646` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 5 |
| 10 | board | `repo-kept-a4bb755b3da34e32878a333da08d5c04` | 0 | 0 | 0 | 0 | 0 | 0 | 203 | 3100 | 1249 | 9 | 269 | 188 | 0 | 0 |
| 11 | board | `repo-kept-a96a526aa67d494fbbf7d841454ca0cb` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 12 | board | `repo-kept-aceb3473930c4e27ad65642d23ce25fa` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 13 | board | `repo-kept-cb9c4e3c05c8424cba7a86cb5a9de9cb` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 0 |
| 14 | board | `repo-kept-d084110f41ff45c69bea582ef588917c` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 0 |
| 15 | board | `repo-kept-e0c2dc019fb94e358b55ac7d1d479849` | 0 | 0 | 0 | 0 | 0 | 0 | 204 | 2703 | 1253 | 12 | 251 | 188 | 0 | 0 |
| 16 | board_b | `repo-kept-25e45b7ab14b47f6ac5b84cab0ae9943` | 30 | 32 | 1 | 0 | 0 | 0 | 211 | 3339 | 1320 | 0 | 290 | 181 | 0 | 0 |
| 17 | board_b | `repo-kept-31c6ea45e6704bbfa0d4517bc62cdb7b` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 23 | 0 | 0 | 0 | 0 |
| 18 | board_b | `repo-kept-5d8322cd44564d0482dbf5bbf2740441` | 0 | 0 | 0 | 0 | 0 | 0 | 203 | 3067 | 1253 | 16 | 259 | 187 | 0 | 0 |
| 19 | board_b | `repo-kept-8c54864d2d5448fea410dd2bf3d231ab` | 0 | 0 | 0 | 0 | 0 | 0 | 204 | 2455 | 980 | 23 | 0 | 4 | 0 | 0 |
| 20 | board_b | `repo-kept-a186a8be2af84cceb7e4823aca9cf619` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 21 | 0 | 0 | 0 | 0 |
| 21 | board_b | `repo-kept-a89882fa7a7143cebaecd9fc731ff308` | 30 | 32 | 1 | 0 | 0 | 0 | 211 | 3202 | 1320 | 0 | 290 | 181 | 0 | 0 |
| 22 | board_b | `repo-kept-d4683f7fa55344b5ac99552f8411ae4e` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 0 |
| 23 | board_b | `repo-kept-d6e097cc724f4d2daff2e834c07f325f` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 24 | board_b | `repo-kept-f252f10ad8464e37a7376c6bcbf3d1c3` | 0 | 0 | 0 | 0 | 0 | 0 | 203 | 3110 | 1253 | 10 | 251 | 188 | 0 | 0 |
| 25 | board_b | `repo-kept-f8363263ab9f4b60ba086d2177333ac3` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 23 | 0 | 0 | 0 | 0 |
| 26 | board_c | `repo-kept-21f1637f37cd4c49b04eae1a5492281b` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 9 |
| 27 | board_c | `repo-kept-7103eb6705144c7da25ef676a676852a` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| 28 | board_c | `repo-kept-8dd5fc6e7acf42969eae2fa889c4513e` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 29 | board_c | `repo-kept-9075e39696d7483bb9cafb50b653e185` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 30 | board_c | `repo-kept-96274c5e12614a6fa657520bb5ea5cd5` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 31 | board_c | `repo-kept-a36f2cdee24b4113ae0dda302bec15b4` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 32 | board_c | `repo-kept-a3fa48601ec14a92a61aec42e3f5433d` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 33 | board_c | `repo-kept-baf094fa7e524314913e246510826cbc` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 34 | board_c | `repo-kept-c7c6705abe3a484e9c6740d259d70ae2` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 34 | 0 |
| 35 | board_c | `repo-kept-cd65042adcce4cad8afca2973f280396` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 36 | board_c | `repo-kept-f0742ce10f714821ac62c915a53d8454` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 37 | board_c | `repo-kept-fa05aa510ae4426e8cf1f35e7d08dc04` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 38 | board_d | `repo-kept-01a3b7f7387643f880f1de1126fd278c` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 240 | 307 | 0 | 306 | 181 | 0 | 0 |
| 39 | board_d | `repo-kept-1d6395062edb4a2cb505165f2b440e1a` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 40 | board_d | `repo-kept-37959aaa46ad4ea281acdb2fe481d061` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 | 0 | 0 | 1 | 0 |
| 41 | board_d | `repo-kept-504e8e94128d451497229b0a79abe0d4` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 42 | board_d | `repo-kept-68ed43f0c2dc4af69f2a757ee5a3803d` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 43 | board_d | `repo-kept-7e5ca41309f54b0bac39ab01793e8956` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 44 | board_d | `repo-kept-94823a9a26254d1cb25c6803855e4c3a` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 45 | board_d | `repo-kept-a33601c53c494045a22001e910104490` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 46 | board_d | `repo-kept-b4cc493db87445ffa2cd38ce2ed73624` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 47 | board_d | `repo-kept-bc9691cf2d0640fea9af30188e8fe58d` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 48 | board_d | `repo-kept-c1874ee7f54a4f52a8165ef7a8b08f3c` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 49 | board_d | `repo-kept-d3e3c247d2d9420cb99cae7ee47816e2` | 30 | 32 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
