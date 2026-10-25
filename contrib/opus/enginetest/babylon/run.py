# A2 engine test, Babylon half: serve the enginetest folder, open index.html in Chromium with the real GPU,
# run the benchmark (and optionally the three stills), write the result JSON in the SPEC.md format.
#
#   python run.py --res 3840x2160 --out bab_4k.json --shots shots_4k
#   python run.py --res 2560x1440 --out bab_1440.json
#
# Sandbox check only (no GPU): add --soft (SwiftShader) and use a small --res. Never use --soft for real numbers.
import argparse, base64, functools, http.server, json, os, shutil, subprocess, sys, threading, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ENGTEST = os.path.dirname(HERE)
VENDOR = os.path.join(HERE, 'vendor')
BJS = '8.20.0'
LIBS = {'babylon.js': 'https://cdn.jsdelivr.net/npm/babylonjs@%s/babylon.js' % BJS,
        'babylonjs.loaders.min.js': 'https://cdn.jsdelivr.net/npm/babylonjs-loaders@%s/babylonjs.loaders.min.js' % BJS}
ASSETS = ['V1b_r_23.glb', 'H4_11.glb', 'C19_51_shell.glb', 'C19_51_kit.glb', 'B16_23.glb', 'I8_37.glb', 'D22_23.glb']

ap = argparse.ArgumentParser()
ap.add_argument('--res', default='2560x1440')
ap.add_argument('--out', default=None, help='result JSON (runs the benchmark)')
ap.add_argument('--shots', default=None, help='folder for the five stills (battle_05, battle_12, battle_126, close_20, breach_30 .png)')
ap.add_argument('--seconds', type=float, default=20)
ap.add_argument('--warmup', type=float, default=3)
ap.add_argument('--msaa', type=int, default=4)
ap.add_argument('--soft', action='store_true', help='software WebGL (SwiftShader), sandbox validation only')
ap.add_argument('--headed', action='store_true', help='show the browser window instead of headless')
ap.add_argument('--angle', default=None, help='ANGLE backend (default d3d11 on Windows, default elsewhere)')
ap.add_argument('--debug-shots', action='store_true', help='also write the debug views (top-down, Hegemony close)')
ap.add_argument('--only', default='', help='comma list: render only these stills or debug views')
ap.add_argument('--extra', default='', help='extra query string for diagnostics, e.g. shadows=0')
ap.add_argument('--timeout', type=float, default=900, help='seconds to wait for load plus benchmark')
a = ap.parse_args()
W, H = [int(v) for v in a.res.lower().split('x')]
if not a.out and not a.shots: ap.error('give --out and/or --shots')

# ---- local copy of Babylon, so the load time does not include a CDN download ----
os.makedirs(VENDOR, exist_ok=True)
for name, url in LIBS.items():
    p = os.path.join(VENDOR, name)
    if not os.path.exists(p) or os.path.getsize(p) < 1000:
        try:
            print('fetching', url); urllib.request.urlretrieve(url, p + '.part'); os.replace(p + '.part', p)
        except Exception as e:
            print('could not fetch %s (%s); the page will fall back to the CDN, so load_s includes a download' % (name, e))
missing = [f for f in ASSETS if not os.path.exists(os.path.join(ENGTEST, 'assets', f))]
if missing: sys.exit('missing in %s: %s' % (os.path.join(ENGTEST, 'assets'), ', '.join(missing)))

# ---- local http server over the enginetest folder (big backlog, or loads can silently drop) ----
class Srv(http.server.ThreadingHTTPServer):
    request_queue_size = 256
    daemon_threads = True
class Quiet(http.server.SimpleHTTPRequestHandler):
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map, **{'.glb': 'model/gltf-binary', '.js': 'text/javascript'})
    def log_message(self, *x): pass
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store'); super().end_headers()
srv = Srv(('127.0.0.1', 0), functools.partial(Quiet, directory=ENGTEST))
threading.Thread(target=srv.serve_forever, daemon=True).start()
port = srv.server_address[1]

# ---- nvidia-smi sampler (total GPU memory in use; WebGL has no memory counter of its own) ----
SMI = shutil.which('nvidia-smi')
smi = {'base': None, 'peak': None, 'run': True}
def smi_read():
    try:
        out = subprocess.run([SMI, '--query-gpu=memory.used', '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=10).stdout
        return int(out.strip().splitlines()[0])
    except Exception: return None
def smi_loop():
    while smi['run']:
        v = smi_read()
        if v is not None: smi['peak'] = max(smi['peak'] or 0, v)
        time.sleep(0.5)
if SMI and not a.soft:
    smi['base'] = smi_read(); threading.Thread(target=smi_loop, daemon=True).start()

from playwright.sync_api import sync_playwright
try:  # the PC runner's sitecustomize.py replaces launch() args (dropping the vsync flags); call the original instead
    from playwright.sync_api._generated import BrowserType
    _sc = sys.modules.get('sitecustomize')
    if _sc is not None and getattr(BrowserType.launch, '__module__', '') == 'sitecustomize' and hasattr(_sc, '_launch'):
        BrowserType.launch = _sc._launch; print('note: bypassed the sitecustomize launch shim')
except Exception as e: print('shim check skipped:', e)

if a.soft:
    args = ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist']
else:
    angle = a.angle or ('d3d11' if sys.platform == 'win32' else 'default')
    args = ['--use-angle=' + angle, '--enable-gpu-rasterization', '--ignore-gpu-blocklist',
            '--disable-gpu-vsync', '--disable-frame-rate-limit']
args += ['--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows']

mode = 'bench' if a.out else 'shots'
url = 'http://127.0.0.1:%d/babylon/index.html?mode=%s&res=%dx%d&seconds=%g&warmup=%g&msaa=%d' % (port, mode, W, H, a.seconds, a.warmup, a.msaa) + ('&' + a.extra if a.extra else '')
errors = []
with sync_playwright() as p:
    T0 = time.time(); b = None
    try: b = p.chromium.launch(headless=not a.headed, channel='chromium', args=args)  # full Chromium (new headless), GPU capable
    except Exception as e: print('chromium channel unavailable, plain launch:', str(e)[:160])
    if b is None: b = p.chromium.launch(headless=not a.headed, args=args)
    launch_s = time.time() - T0
    ctx = b.new_context(viewport={'width': W, 'height': H}, device_scale_factor=1)
    pg = ctx.new_page()
    pg.on('pageerror', lambda e: errors.append('pageerror: ' + str(e)[:300]))
    pg.on('console', lambda m: errors.append('console.%s: %s %s' % (m.type, m.text[:300], (m.location or {}).get('url', ''))) if m.type in ('error', 'warning') else None)
    pg.goto(url, wait_until='commit')
    T1 = time.time()
    while not pg.evaluate('!!(window.__ready || window.__error)'):
        if any(e.startswith('pageerror') or 'Error compiling effect' in e for e in errors) or time.time() - T1 > a.timeout:
            for e in errors: print('  ', e)
            sys.exit('page failed to start')
        time.sleep(0.5)
    if pg.evaluate('window.__error || null'):
        for e in errors: print('  ', e)
        sys.exit('page error: ' + pg.evaluate('window.__error'))
    info = pg.evaluate('window.__info')
    print('loaded in %.2f s (page), GL: %s, %dx%d, ship tris %d' % (info['load_s'], info['gl'].get('renderer'), info['width'], info['height'], info['ship_tris']))
    soft = 'swiftshader' in str(info['gl']).lower()
    if soft and not a.soft: print('WARNING: the page is on SwiftShader (software), not the GPU; these numbers are not valid')
    res = None
    if a.out:
        pg.wait_for_function('window.__result', timeout=a.timeout * 1000, polling=1000)
        res = pg.evaluate('window.__result')
    if a.shots:
        os.makedirs(a.shots, exist_ok=True)
        names = pg.evaluate('window.__shotNames') + (pg.evaluate('window.__debugNames') if a.debug_shots or a.only else [])
        if a.only: names = [n for n in names if n in a.only.split(',')]
        for name in names:
            data = pg.evaluate('window.__shot(%s)' % json.dumps(name))
            with open(os.path.join(a.shots, name + '.png'), 'wb') as f: f.write(base64.b64decode(data.split(',', 1)[1]))
            print('shot', name)
    b.close()
smi['run'] = False
srv.shutdown()

if res is not None:
    ex = res.pop('_extra')
    notes = ['Chromium via Playwright, GL renderer: %s' % ex['gl'].get('renderer'),
             'MSAA %dx, HDR, bloom, ACES, 4 shadow cascades of 2048' % ex['msaa'],
             'frame time = time between requestAnimationFrame callbacks; median %s ms' % ex['median_ms']]
    if ex.get('gpu_frame_ms_avg') is not None: notes.append('GPU timer query average %.3f ms per frame' % ex['gpu_frame_ms_avg'])
    notes.append('load_s from navigation start to the first presented frame with all six ships and the sky; browser launch took %.2f s more' % launch_s)
    notes.append('gpu_mem_mb: WebGL has no GPU memory counter')
    if smi['base'] is not None and smi['peak'] is not None:
        notes.append('nvidia-smi total memory used: %d MB before launch, %d MB peak (%+d MB)' % (smi['base'], smi['peak'], smi['peak'] - smi['base']))
    rates = [1000.0 / hz for hz in (60, 75, 120, 144, 165, 240)]
    if ex['median_ms'] and any(abs(ex['median_ms'] - r) / r < 0.03 for r in rates):
        notes.append('WARNING: median frame time matches a display refresh rate; vsync or the frame limiter may still be on')
    if soft: notes.append('SOFTWARE RENDERER (SwiftShader): validation only, not a real measurement')
    errs = [e for e in errors if e.startswith('pageerror') or e.startswith('console.error')]
    if errs: notes.append('%d console errors (first: %s)' % (len(errs), errs[0][:160]))
    res['notes'] = '; '.join(notes)
    if os.path.dirname(os.path.abspath(a.out)): os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, 'w') as f: json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))
for e in errors: print('  ', e)
