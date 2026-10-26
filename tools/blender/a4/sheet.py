# A4: contact sheets from the PC check renders (studio views clay and painted, and the 9-cell blob sweep), via a2detail/checks_sheet.py.
# Needs PIL (ComfyUI's Python on the PC).   python sheet.py CHECK_DIR CODE [CODE ...]
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'a2detail'))
import checks_sheet

if __name__ == '__main__':
    for c in sys.argv[2:]:
        checks_sheet.make(sys.argv[1], c); print('sheets', c, flush=True)
