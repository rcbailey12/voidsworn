# game hull JSON -> OBJ (for clay renders of what the game actually draws)
import sys, json, base64, numpy as np
j = json.load(open(sys.argv[1])); ext = np.array(j['ext'])
P = np.frombuffer(base64.b64decode(j['p']), np.int16).reshape(-1, 3) / 32767 * ext
I = np.frombuffer(base64.b64decode(j['i']), np.uint32 if j.get('i32') else np.uint16).reshape(-1, 3)
with open(sys.argv[2], 'w') as f:
    for x, y, z in P: f.write(f'v {x:.5f} {-z:.5f} {y:.5f}\n')  # game y-up -> Blender z-up
    for a, b, c in I: f.write(f'f {a+1} {c+1} {b+1}\n')
print(len(P), len(I))
