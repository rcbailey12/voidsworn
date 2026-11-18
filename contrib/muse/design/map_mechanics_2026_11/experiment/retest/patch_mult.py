# Per-controller split for multiplicative scoring, on top of the retest copy.
# These are the exact replacements applied on Nov 17, 2026 (late) to produce the mult test copy.
import sys

def patch(path, old, new):
    src = open(path, encoding='utf8').read()
    n = src.count(old)
    if n != 1:
        print(f'FAIL {path}: expected 1 of {old[:50]!r}, found {n}')
        sys.exit(1)
    open(path, 'w', encoding='utf8').write(src.replace(old, new))
    print('patched', path)

# veteran seat (battle.js): mult also enabled by multE
patch('battle.js',
  "let score=off-threat*tw; if(globalThis.MECHCFG&&MECHCFG.mult) score=",
  "let score=off-threat*tw; if(globalThis.MECHCFG&&(MECHCFG.mult||MECHCFG.multE)) score=")
# harness bot seat (measure_map.js): mult also enabled by multP
patch('measure_map.js',
  "if(globalThis.MECHCFG&&MECHCFG.mult) sc=Math.pow",
  "if(globalThis.MECHCFG&&(MECHCFG.mult||MECHCFG.multP)) sc=Math.pow")
print('MULT SPLIT APPLIED')
