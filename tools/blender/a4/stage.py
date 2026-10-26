# A4: stage the PC files for ship jobs into a fresh folder (the PC bridge copies files from there; HANDOFF: always a fresh folder).
#   python3 stage.py STAGE_DIR TAG CODE [CODE ...]     -> STAGE_DIR/a4tools/... and STAGE_DIR/a4_<CODE>_<TAG>.bat (one queued job per ship)
#   python3 stage.py STAGE_DIR TAG --jobs-only CODE ...  (only the job files, when the tools are already on the PC)
import os, sys, shutil
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))


def crlf(s): return s.replace('\r\n', '\n').replace('\n', '\r\n')


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
    for c in codes:
        open(os.path.join(out, f'a4_{c}_{tag}.bat'), 'w', newline='').write(crlf(f'@echo off\nset A4CODE={c}\ncall a4tools\\a4_ship.bat\nset A4CODE=\nexit /b\n'))
    n = sum(len(fs) for _, _, fs in os.walk(out)); print('staged', n, 'files in', out)


if __name__ == '__main__':
    main()
