# Painted Nemesis scars (R42): Qwen-Image-Edit 2511 paints one scar onto a picked Nemesis portrait, so the first scar a
# Nemesis earns looks painted in, not stuck on. Runs with ComfyUI's embedded python on Ryan's PC, next to portrait_run.py.
#   portrait_edit.py <edits.json>
# edits.json: {"out": "n1s", "budget_s": 1050, "items": [{"id": "nem_corsair_3", "kind": "burn", "src": "n1/nem_corsair_3_zit_s23_00001_.png",
#              "prompt": "...", "seed": 11}]}
# src is relative to comfy_io\PORTRAITS\. LoadImage only lists the input folder's top level, so each source is copied there
# first as src_<id>.png. Output: comfy_io\PORTRAITS\<out>\<id>_<kind>_s<seed>_00001_.png (existing outputs are skipped,
# so a job that stops at its time budget can simply be queued again).
import os, sys, json, time, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import portrait_run as R


def main(path):
    B = json.load(open(path, encoding='utf-8')); out = B['out']; t0 = time.time(); n = 0; man = []
    if not R.ready('qie'):
        R.log('EDIT ABORT: Qwen-Image-Edit files missing'); return
    todo = [it for it in B['items'] if not os.path.exists(os.path.join(R.IO_, '%s/%s_%s_s%d_00001_.png' % (out, it['id'], it['kind'], it.get('seed', 11))))]
    R.log('edit', out, len(todo), 'to do of', len(B['items']))
    if not todo: return
    p = R.start()
    try:
        for it in todo:
            sd = it.get('seed', 11); pre = '%s/%s_%s_s%d' % (out, it['id'], it['kind'], sd)
            src = os.path.join(R.IO_, it['src'].replace('/', os.sep))
            if not os.path.exists(src): R.log('missing source', it['src']); continue
            flat = 'src_%s.png' % it['id']; shutil.copyfile(src, os.path.join(R.IO_, flat))
            r = R.run(R.qref(it['prompt'], sd, pre, flat), pre)
            n += 1; man.append({'id': it['id'], 'kind': it['kind'], 'seed': sd, 'src': it['src'],
                                'ok': bool(r and r.get('status', {}).get('status_str') == 'success')})
            if time.time() - t0 > B.get('budget_s', 1050): R.log('budget reached, stopping'); break
    finally:
        p.terminate()
        try: p.wait(30)
        except Exception: p.kill()
        with open(os.path.join(R.PD, 'manifest_%s_%s.json' % (out, time.strftime('%H%M%S'))), 'w', encoding='utf-8') as f: json.dump(man, f, indent=1)
    R.log('EDIT DONE', out, n, 'images', '%.0fs' % (time.time() - t0))


if __name__ == '__main__':
    main(sys.argv[1])
