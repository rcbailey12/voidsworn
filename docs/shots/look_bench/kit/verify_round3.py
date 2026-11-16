"""Validate real raster visibility, source/coverage and measured scene cost.

python verify_round3.py --root DIR
The declared frame margin is fixed here before measurements, not fitted later.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
from statistics import median
import numpy as np
from PIL import Image
from capture_kit import REPO, rows

FRAME_BASELINE=4.617
FRAME_MARGIN=.800
GPU_MARGIN=.300


def vector(text):
    return [float(n) for n in re.findall(r'-?\d+(?:\.\d+)?',text)]


def raster(root):
    records=json.loads((root/'raster_frames.json').read_text())
    measurements=[]
    for r in records:
        pixels=np.asarray(Image.open(root/r['file']).convert('RGB')).max(axis=2)
        phone=np.asarray(Image.open(root/(Path(r['file']).stem+'_phone.png')).convert('RGB')).max(axis=2)
        age,flight=r['age'],r['flight']
        xs=np.where((pixels>32).any(axis=0))[0]
        span=int(xs[-1]-xs[0]+1) if xs.size else 0
        start_x,end_x=vector(r['from'])[0],vector(r['to'])[0]
        axis=abs(end_x-start_x)
        head_x=start_x+(end_x-start_x)*min(age/flight,1.0)
        direction=1.0 if end_x>=start_x else -1.0
        rear_x=xs[0] if direction>0 and xs.size else (xs[-1] if xs.size else head_x)
        tail=max(0.0,(head_x-rear_x)*direction)
        record=dict(r,bright_span_px=span,projected_shot_px=axis,
            bright_tail_px=tail,bright_tail_fraction=tail/axis,
            phone_peak=int(phone.max()),phone_lit_pixels=int((phone>24).sum()))
        if age<=flight+1e-5:
            assert phone.max()>=40 and (phone>24).sum()>=2,('Invisible flight sample',record)
        if flight*.5<=age<=flight+1e-5:
            assert tail>=axis*.20,('Tracer behind head shorter than one fifth',record)
        if age>flight+.70:
            assert pixels.max()<=1,('Wake did not expire',record)
        measurements.append(record)
    assert len(records)==192,len(records)
    return measurements


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,required=True)
    a=p.parse_args()
    evidence=a.root
    expected={r['id'] for r in rows()}|{f'shield_{w}_{f}' for f in
        ['voidsworn','hegemony','ithar','corsair'] for w in ['torp','doom']}
    for version in ['before','after']:
        bench=json.loads((evidence/version/'bench.json').read_text())
        assert not bench['warnings']
        assert {(r['id'],r['cam']) for r in bench['stills']}=={(n,c) for n in expected for c in [170,60]}
        assert all('phone_file' in r for r in bench['stills'] if r['cam']==170)
        process=json.loads((evidence/version/'process.json').read_text())
        assert process['exit']==0 and all(c['exit']==0 and not c['stopped_after_completion'] for c in process['children'])
    hashes=json.loads((evidence/'after/source_hashes.json').read_text())
    for name,digest in hashes.items():
        assert hashlib.sha256((REPO/'godot'/name.replace('\\','/')).read_bytes()).hexdigest()==digest,name
    results=raster(evidence/'raster')
    (evidence/'raster/measurements.json').write_text(json.dumps(results,indent=1))
    gates={v:json.loads((evidence/f'gate_{v}/scene_gate.json').read_text()) for v in ['before','after']}
    cost={v:dict(frame_1080=median(r['frame_median'] for r in g['modes']['base']),
        gpu_1080=median(r['gpu_median'] for r in g['modes']['base']),
        gpu_4k=median(r['gpu_median'] for r in g['modes']['res_2160'])) for v,g in gates.items()}
    assert cost['after']['frame_1080']<=FRAME_BASELINE+FRAME_MARGIN,cost
    for mode in ['gpu_1080','gpu_4k']:
        assert cost['after'][mode]<=cost['before'][mode]+GPU_MARGIN,cost
    assert cost['after']['frame_1080']<12.5 and cost['after']['gpu_4k']<12.5,cost
    for path in (evidence/'sheets').iterdir():
        if path.suffix.lower() in ['.png','.gif']:
            with Image.open(path) as im:
                assert im.width<=1280 and im.height<=720,path
    summary=dict(rows=len(expected),raster_frames=len(results),cost=cost,
        historical_frame_baseline_ms=FRAME_BASELINE,declared_frame_margin_ms=FRAME_MARGIN,
        gpu_margin_ms=GPU_MARGIN,source_hashes_match=True,
        min_phone_peak=min(r['phone_peak'] for r in results if r['age']<=r['flight']+1e-5),
        min_bright_tail_fraction=min(r['bright_tail_fraction'] for r in results if r['flight']*.5<=r['age']<=r['flight']+1e-5))
    (evidence/'verified.json').write_text(json.dumps(summary,indent=1))
    print('ROUND3_VERIFIED',json.dumps(summary))


if __name__=='__main__':
    main()
