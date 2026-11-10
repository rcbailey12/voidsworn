# Opus #209 round 1, step G1: Qwen-Image-Edit 2511 on Ryan's PC (ComfyUI portable, headless).
# (a) image references for Arm A: side, top and front views of the C15s concept (multiple-angles LoRA);
# (b) Arm B inputs: each section crop and part crop redrawn as one separate, complete object on white, ready for TRELLIS.2.
# Run with ComfyUI's embedded python: python gen209_qwen.py GEN_DIR   (GEN_DIR holds in\*.png; writes q\*.png)
import os, sys, json, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'repo', 'tools', 'pc'))
import comfy_run as C
G = sys.argv[1]
def prompt(img, text, seed, prefix, angle_w):
    p = C.qwen_prompt(img, 'x', seed, prefix, angle_w=angle_w)
    p['10']['inputs']['prompt'] = text
    return p
SEC = ('Show only this cut piece of the spaceship as one complete, separate hull section module, alone on a plain white background, '
       'same camera angle, both cut ends closed with flat armoured bulkhead plates, crisp hard-surface detail, no lattice masts, no wires')
PART = 'shown alone as one complete object on a plain white background, three-quarter view, crisp hard-surface sci-fi detail, nothing else in the picture'
JOBS = [('ref_side', 'whole.png', '<sks> right side view eye-level shot medium shot', .9),
        ('ref_top', 'whole.png', '<sks> front view high-angle shot medium shot', .9),
        ('ref_front', 'whole.png', '<sks> front view eye-level shot medium shot', .9),
        ('ref_back', 'whole.png', '<sks> back view eye-level shot medium shot', .9)]
for k in range(3): JOBS.append((f'b1_s{k}', f'b1_s{k}.png', SEC, 0.0))
for k in range(6): JOBS.append((f'b2_s{k}', f'b2_s{k}.png', SEC, 0.0))
PARTS = {'casemate': 'A single armoured casemate gun mount: an octagonal armour plate with a ball turret and twin short cannon barrels, ',
         'drumrack': 'A rack of three large cylindrical missile drums with yellow bands lying side by side on a low frame, ',
         'bowguns': 'A pair of heavy forward cannons with orange glowing muzzles on one flat mounting plate, ',
         'cargo': 'A long armoured cargo container block with vertical ribbed panels, ',
         'sternblock': 'The rear engine block of a spaceship with large round engine nozzles, '}
for k, t in PARTS.items(): JOBS.append((f'p_{k}', f'p_{k}.png', t + PART, 0.0))
p = C.start(G)
try:
    for name, img, text, aw in JOBS:
        for s in (0, 1):
            C.run(prompt('in/' + img, text, 2090 + s, f'q/{name}_s{s}', aw), f'{name} s{s}', timeout=900)
finally:
    p.terminate(); p.wait(30)
open(os.path.join(G, 'q_done.txt'), 'w').write('done ' + time.strftime('%H:%M:%S'))
C.log('GEN209 QWEN DONE')
