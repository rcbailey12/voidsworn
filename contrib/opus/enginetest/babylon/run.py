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
ASSETS = ['V1b_r_23.glb', 'H4_11.glb', 'C19_51_shell.glb', 'C19_51_kit.glb', 'B16_23.glb', 'I8_37.glb', 'D22_23.glb']

ap = argparse.ArgumentParser()
ap.add_argument('--res', default='2560x1440')
ap.add_argument('--bjs', default='9.30.0', help='Babylon.js release (9.30.0, or 8.20.0 to compare with the first runs)')
ap.add_argument('--webgpu', action='store_true', help='WebGPU engine instead of WebGL2 (renderer "webgpu")')
ap.add_argument('--out', default=None, help='result JSON (runs the benchmark)')
ap.add_argument('--shots', default=None, help='folder for the five stills (battle_05, battle_12, battle_126, close_20, breach_30 .png)')
ap.add_argument('--seconds', type=float, default=20)
ap.add_argument('--warmup', type=float, default=3)
ap.add_argument('--msaa', type=int, default=4)
ap.add_argument('--stress', action='store_true', help='SPEC.md stress run: 24 ships, 0.17 s stagger, destruction every 4 s')
ap.add_argument('--ships', type=int, default=0, help='ceiling round ship sweep: 48 or 96 (24 = the stress run)')
ap.add_argument('--rich', action='store_true', help='ceiling round rich effects (24-ship layout unless --ships)')
ap.add_argument('--max', action='store_true', help='max-detail round: rich effects, hi assets when present, detail features')
ap.add_argument('--board', action='store_true', help='game slice: max mode from the tactical camera over a hex board, with UI; measures click to visible ring')
ap.add_argument('--ui', default='gui', choices=['gui', 'html'], help='board labels: Babylon GUI (default) or HTML over the canvas')
ap.add_argument('--hi', default='auto', choices=['auto', 'on', 'off'], help='max-detail ships from assets/hi/ (auto: in max and board modes when all seven files are there)')
ap.add_argument('--noenv', action='store_true', help='ignore assets/env/ (diagnostics)')
ap.add_argument('--vsync', action='store_true', help='leave vsync and the frame limiter on; reports dropped frames against the display rate')
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

# ---- local copy of Babylon (per release), so the load time does not include a CDN download ----
HKV = '1.3.10' if a.bjs == '8.20.0' else '1.3.14'
LIBS = {('bjs-' + a.bjs, 'babylon.js'): 'https://cdn.jsdelivr.net/npm/babylonjs@%s/babylon.js' % a.bjs,
        ('bjs-' + a.bjs, 'babylonjs.loaders.min.js'): 'https://cdn.jsdelivr.net/npm/babylonjs-loaders@%s/babylonjs.loaders.min.js' % a.bjs,
        ('bjs-' + a.bjs, 'babylon.gui.min.js'): 'https://cdn.jsdelivr.net/npm/babylonjs-gui@%s/babylon.gui.min.js' % a.bjs,
        ('havok-' + HKV, 'HavokPhysics_umd.js'): 'https://cdn.jsdelivr.net/npm/@babylonjs/havok@%s/lib/umd/HavokPhysics_umd.js' % HKV,
        ('havok-' + HKV, 'HavokPhysics.wasm'): 'https://cdn.jsdelivr.net/npm/@babylonjs/havok@%s/lib/umd/HavokPhysics.wasm' % HKV}
for (sub, name), url in LIBS.items():
    os.makedirs(os.path.join(VENDOR, sub), exist_ok=True)
    p = os.path.join(VENDOR, sub, name)
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
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map, **{'.glb': 'model/gltf-binary', '.js': 'text/javascript', '.wasm': 'application/wasm'})
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
    args = ['--use-angle=' + angle, '--enable-gpu-rasterization', '--ignore-gpu-blocklist']
    if not a.vsync: args += ['--disable-gpu-vsync', '--disable-frame-rate-limit']
if a.webgpu: args += ['--enable-unsafe-webgpu']
args += ['--enable-precise-memory-info', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows']

HI_FILES = ['V1b_r_23.glb', 'H4_11.glb', 'C19_51_shell.glb', 'C19_51_kit.glb', 'B16_23.glb', 'I8_37.glb', 'D22_23.glb']
hi_ok = all(os.path.exists(os.path.join(ENGTEST, 'assets', 'hi', f)) for f in HI_FILES)
use_hi = a.hi == 'on' or (a.hi == 'auto' and (a.max or a.board) and hi_ok)
if use_hi and not hi_ok: sys.exit('--hi on, but assets/hi/ is missing some of: ' + ', '.join(HI_FILES))
print('ship assets:', 'assets/hi/ (max-detail)' if use_hi else 'assets/')
mode = 'bench' if a.out else 'shots'
url = 'http://127.0.0.1:%d/babylon/index.html?mode=%s&res=%dx%d&seconds=%g&warmup=%g&msaa=%d' % (port, mode, W, H, a.seconds, a.warmup, a.msaa) + '&bjs=' + a.bjs + ('&hi=1' if use_hi else '') + ('&webgpu=1' if a.webgpu else '') + ('&stress=1' if a.stress else '') + ('&ships=%d' % a.ships if a.ships else '') + ('&rich=1' if a.rich else '') + ('&max=1' if a.max else '') + ('&board=1' if a.board else '') + ('&ui=html' if a.ui == 'html' else '') + ('&envsky=1' if not a.noenv and os.path.exists(os.path.join(ENGTEST, 'assets', 'env', 'sky_deadstar_8k.png')) else '') + ('&envrocks=1' if not a.noenv and os.path.exists(os.path.join(ENGTEST, 'assets', 'env', 'asteroids.json')) else '') + ('&vsync=1' if a.vsync else '') + ('&' + a.extra if a.extra else '')
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
    print('Babylon %s, %s, hi assets %s, textures about %s MB' % (info.get('bjs'), info.get('renderer'), info.get('hi'), info.get('tex_mb')))
    print('loaded in %.2f s (page), pre-warm %.2f s, %d ships, GL: %s, %dx%d, ship tris %d' % (info['load_s'], info['prewarm_s'], info['ships_n'], info['gl'].get('renderer'), info['width'], info['height'], info['ship_tris']))
    soft = 'swiftshader' in str(info['gl']).lower()
    if soft and not a.soft: print('WARNING: the page is on SwiftShader (software), not the GPU; these numbers are not valid')
    res = None
    if a.out:
        pg.wait_for_function('window.__result', timeout=a.timeout * 1000, polling=1000)
        res = pg.evaluate('window.__result')
    click = None
    if a.board:   # hover a ship, click it, read how many frames until the selection ring was on screen
        pg.evaluate('window.__idle()'); pg.wait_for_timeout(1500)
        x, y = pg.evaluate('window.__shipScreen(2)')
        pg.mouse.move(x, y); pg.wait_for_timeout(400); pg.mouse.click(x, y)
        for _ in range(240):
            pg.wait_for_timeout(250); click = pg.evaluate('window.__clickToVisible()')
            if click: break
        print('click to visible ring:', click)
        if not click: print('  board state:', pg.evaluate('window.BRD_DBG ? JSON.stringify(BRD_DBG()) : null'))
    if a.shots:
        os.makedirs(a.shots, exist_ok=True)
        names = pg.evaluate('window.__shotNames') + (pg.evaluate('window.__debugNames') if a.debug_shots or a.only else [])
        if a.only: names = [n for n in names if n in a.only.split(',')]
        for name in names:
            data = pg.evaluate('window.__shot(%s)' % json.dumps(name))
            if data == 'canvas': pg.wait_for_timeout(300); pg.locator('#c').screenshot(path=os.path.join(a.shots, name + '.png'), timeout=300000)
            elif data == 'page': pg.wait_for_timeout(300); pg.screenshot(path=os.path.join(a.shots, name + '.png'), timeout=300000)
            else:
                with open(os.path.join(a.shots, name + '.png'), 'wb') as f: f.write(base64.b64decode(data.split(',', 1)[1]))
            print('shot', name)
    b.close()
smi['run'] = False
srv.shutdown()

if res is not None:
    trace_path = os.path.splitext(a.out)[0] + '_trace.json'
    ex = res.pop('_extra')
    trace = ex.pop('trace')
    notes = ['Chromium via Playwright, GL renderer: %s' % ex['gl'].get('renderer'),
             'MSAA %dx, HDR, bloom, ACES, 4 shadow cascades of 2048' % ex['msaa'],
             'frame time = time between requestAnimationFrame callbacks; median %s ms' % ex['median_ms']]
    if ex.get('gpu_frame_ms_avg') is not None: notes.append('GPU timer query average %.3f ms per frame' % ex['gpu_frame_ms_avg'])
    notes.append('load_s from navigation start to the first presented frame with all six ships and the sky; browser launch took %.2f s more' % launch_s)
    notes.append('gpu_mem_mb: WebGL has no GPU memory counter; textures estimated at %s MB as uncompressed RGBA8 with mips' % ex.get('tex_mb_estimate'))
    if smi['base'] is not None and smi['peak'] is not None:
        notes.append('nvidia-smi total memory used: %d MB before launch, %d MB peak (%+d MB)' % (smi['base'], smi['peak'], smi['peak'] - smi['base']))
    rates = [1000.0 / hz for hz in (60, 75, 120, 144, 165, 240)]
    if ex['median_ms'] and any(abs(ex['median_ms'] - r) / r < 0.03 for r in rates):
        notes.append('WARNING: median frame time matches a display refresh rate; vsync or the frame limiter may still be on')
    if soft: notes.append('SOFTWARE RENDERER (SwiftShader): validation only, not a real measurement')
    errs = [e for e in errors if e.startswith('pageerror') or e.startswith('console.error')]
    if errs: notes.append('%d console errors (first: %s)' % (len(errs), errs[0][:160]))
    worst = trace['worst_frames']['rows']
    notes.append('%d ships; shaders pre-warmed for %.2f s after load_s, before the warm-up' % (ex['ships'], ex['prewarm_s']))
    notes.append('JS work per frame (update plus render calls): worst 1%% %s ms, max %s ms' % (ex['work_p99_ms'], ex['work_max_ms']))
    notes.append('worst frames (scene t s: frame ms / JS work ms): ' + ', '.join('%.2f: %.1f/%.1f' % (r[0], r[1], r[2]) for r in worst[:8]))
    notes.insert(0, 'Babylon %s, ships from %s' % (ex.get('bjs'), 'assets/hi/ (max-detail, the files\' own PBR materials)' if ex.get('hi_assets') else 'assets/'))
    if ex.get('light_route'): notes.append('event lights: ' + ex['light_route'])
    if ex.get('rich_lights_avg') is not None: notes.append('rich lights: %s point lights in the scene, %s distinct event lights lit at once on average, %s at most' % (ex['point_lights'], ex['rich_lights_avg'], ex['rich_lights_max']))
    notes.append('environment: %s' % (('dead-star sky' if ex['env']['sky'] else 'starfield sky') + ', %d rocks' % ex['env']['rocks'] if ex.get('env') else 'none (assets/env/ missing or not this mode)'))
    notes.append('%d shader compiles and %d heap drops (GC) during the bench, listed in the trace' % (len(trace['shader_compiles']['rows']), len(trace['heap_drops']['rows'])))
    if res.get('physics_step_avg_ms') is not None: notes.append('physics: %s Havok bodies, step %s ms per frame on average, %s ms at most' % (ex.get('physics_bodies'), res['physics_step_avg_ms'], res['physics_step_max_ms']))
    if res.get('vsync'): notes.append('vsync on: %s Hz, %s frames dropped (%s%%)' % (res['refresh_hz'], res['dropped_frames'], res['dropped_pct']))
    notes.append('per-second trace in ' + os.path.basename(trace_path))
    if click: res['click_to_visible_frames'] = click['frames']; res['click_to_visible_ms'] = click['ms']; notes.append('click to visible selection ring: %s frames, %s ms' % (click['frames'], click['ms']))
    res['notes'] = '; '.join(notes)
    if os.path.dirname(os.path.abspath(a.out)): os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, 'w') as f: json.dump(res, f, indent=1)
    with open(trace_path, 'w') as f: json.dump(dict(trace, warmup_s=ex['warmup_s'], note='second = second of the counted window; scene t = that + warmup_s'), f, indent=1)
    print(json.dumps(res, indent=1))
for e in errors: print('  ', e)
