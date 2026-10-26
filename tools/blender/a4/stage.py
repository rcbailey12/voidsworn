# A4: stage the PC files for ship jobs into a fresh folder (the PC bridge copies files from there; HANDOFF: always a fresh folder).
#   python3 stage.py STAGE_DIR TAG CODE [CODE ...]     -> STAGE_DIR/a4tools/... and STAGE_DIR/a4_<CODE>_<TAG>.bat (one queued job per ship)
#   python3 stage.py STAGE_DIR TAG --jobs-only CODE ...  (only the job files, when the tools are already on the PC)
#   python3 stage.py STAGE_DIR TAG --jobs-only --lineups  (the seven faction lineup jobs: voidsworn_test\a4\lineups\<faction>.webp)
import os, sys, shutil
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))


def crlf(s): return s.replace('\r\n', '\n').replace('\n', '\r\n')


LINEUPS = [('corsair', 'Corsair line', 'C19_51 C16s_23 C15s_23 C14s_23 C13s_23'),
           ('voidsworn', 'Voidsworn line', 'V1b_r_23 V17_37 V18_51 V16_37 V15_37 V14_23'),
           ('hegemony', 'Hegemony line', 'H4_11 H10_23 H9_23 H8_23 H7_23'),
           ('chorus', 'Chorus line', 'B16_23 B22_11 B21_11 B20_11 B19_11 B23_51'),
           ('ithar', 'Ithar line', 'I8_37 I16_11 I15_11 I11_37 I14_23'),
           ('deathless', 'Deathless line', 'D22_23 D21_23 D20_23 D9_23'),
           ('zcraft', 'Squadron craft and objectives', 'O1_37 O2_37 O3_11 S2_23 S1_51 B23_51')]


def main():
    a = sys.argv[1:]; out, tag = a[0], a[1]; codes = [c for c in a[2:] if not c.startswith('--')]
    if os.path.exists(out): raise SystemExit(f'{out} exists: use a fresh folder')
    os.makedirs(out)
    if '--jobs-only' not in a:
        for sub, src, pat in (('a4', os.path.join(REPO, 'tools/blender/a4'), '.py'), ('a2detail', os.path.join(REPO, 'tools/blender/a2detail'), '.py')):
            d = os.path.join(out, 'a4tools', sub); os.makedirs(d)
            for f in sorted(os.listdir(src)):
                if f.endswith(pat): shutil.copy(os.path.join(src, f), d)
        d = os.path.join(out, 'a4tools', 'hs'); os.makedirs(d)
        for f in ('hs_lib.py', 'detail_lib.py'): shutil.copy(os.path.join(REPO, 'tools/blender/hs', f), d)
        for b in ('a4_ship.bat', 'a4_looks.bat', 'a4_lineup.bat', 'a4_barge.bat', 'a4_damage.bat'):
            if os.path.exists(os.path.join(REPO, 'tools/pc/jobs', b)):
                open(os.path.join(out, 'a4tools', b), 'w', newline='').write(crlf(open(os.path.join(REPO, 'tools/pc/jobs', b)).read()))
    if '--looks' in a:
        open(os.path.join(out, f'a4_looks_{tag}.bat'), 'w', newline='').write(crlf(f'@echo off\nset A4LOOK={" ".join(codes)}\ncall a4tools\\a4_looks.bat\nset A4LOOK=\nexit /b\n'))
        codes = []
    if '--lineups' in a:
        for k, (ftag, title, ships) in enumerate(LINEUPS):
            open(os.path.join(out, f'a4_lineup{k}_{ftag}_{tag}.bat'), 'w', newline='').write(crlf(
                f'@echo off\nset A4TAG={ftag if ftag != "zcraft" else "craft_objectives"}\nset A4TITLE={title}\nset A4SHIPS={ships}\n'
                f'call a4tools\\a4_lineup.bat\nset A4TAG=\nset A4TITLE=\nset A4SHIPS=\nexit /b\n'))
        codes = []
    for c in codes:
        open(os.path.join(out, f'a4_{c}_{tag}.bat'), 'w', newline='').write(crlf(f'@echo off\nset A4CODE={c}\ncall a4tools\\a4_ship.bat\nset A4CODE=\nexit /b\n'))
    n = sum(len(fs) for _, _, fs in os.walk(out)); print('staged', n, 'files in', out)


if __name__ == '__main__':
    main()
