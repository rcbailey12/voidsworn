"""Camera-170 broadside using the standing real-hull bench, with a warm pass.

python capture_t10.py --project PATH --out PATH
Run each version twice. The t10_perf row measures frames without image readback.
Generated drivers and logs stay in TEMP, via the existing kit adapter.
"""
import json
from pathlib import Path
import sys


def rows():
    base = dict(label='T10 Sunward broadside', group='T10', att=['voidsworn', 'Cruiser'],
        tgt=['hegemony', 'Cruiser'], tgt_at=[-18, 40], do='volley', kind='battery',
        weapon='hbattery', shots=8, on='hull', focus='path',
        windows=[['fire', 0.0, 90]], key=24)
    return [dict(base, id='t10'), dict(base, id='t10_calm', fx={'reduce_flashing': True}),
            dict(base, id='t10_perf', measure=True, windows=[['fire', 0.0, 150]])]


def main():
    adapter = Path(__file__).with_name('capture_kit.py')
    source = adapter.read_text()
    needle = "    code = (REPO / 'godot/bench/look_bench.gd').read_text()"
    # The adapter already owns cleanup, frame locking, source hashes and logs.
    # Add only this job's measurements, at the point it reads the standing bench.
    extra = """
    code = code.replace('for key in HT.AI_HULLS:', 'for key in ["voidsworn|Cruiser", "hegemony|Cruiser"]:', 1)
    code = code.replace('_ship("A", "voidsworn", "Frigate",', '_ship("A", "voidsworn", "Cruiser",')
    code = code.replace('w["next"] = steps + 2', 'w["next"] = steps + 1')
    code = code.replace('var guard := 0', 'var frame_ms: Array = []\\n\\tvar guard := 0')
    code = code.replace('var impacts: Array = []', 'var impacts: Array = []\\n\\tvar strokes: Array = []')
    code = code.replace('impacts = res.get("impacts", [])', '''impacts = res.get("impacts", [])
        var pool = fx.pools["stk"]
        var data: PackedFloat32Array = pool.pending
        for at in range(0, data.size(), 20 * pool.vpp):
            var speed := Vector3(data[at+8], data[at+9], data[at+10]).length()
            if absf(speed - 160.0 * fx.unit) < 0.01:
                strokes.append({"t": data[at+7] - t_ev, "width": data[at+17],
                    "intensity": data[at+15], "width_px": data[at+2]})'''.replace('    ', '\\t'))
    code = code.replace('var img := _grab()\\n\\t\\t\\tif img != null:',
        'var img: Image = null if bool(row.get("measure", false)) else _grab()\\n\\t\\t\\tif img != null:')
    code = code.replace('\\t\\tawait _step()\\n\\t\\tguard += 1',
        '\\t\\tvar tick := Time.get_ticks_usec()\\n\\t\\tawait _step()\\n\\t\\tframe_ms.append(float(Time.get_ticks_usec() - tick) / 1000.0)\\n\\t\\tguard += 1')
    code = code.replace('"impacts": impacts})', '"impacts": impacts, "frame_ms": frame_ms, "fires": fires, "strokes": strokes})')
"""
    assert needle in source
    source = source.replace(needle, needle + extra)
    namespace = dict(__file__=str(adapter), __name__='t10_adapter')
    exec(compile(source, str(adapter), 'exec'), namespace)
    namespace['rows'] = rows
    sys.argv += ['--cameras', '170', '--round3', '--only', 't10,t10_calm,t10_perf']
    namespace['main']()
    out = Path(sys.argv[sys.argv.index('--out') + 1])
    report = json.loads((out / 'bench.json').read_text())
    for record in report['stills']:
        if record['id'].startswith('t10'):
            print(record['id'], 'fires', record.get('fires'), 'frames', len(record.get('frame_ms', [])))


if __name__ == '__main__':
    main()
