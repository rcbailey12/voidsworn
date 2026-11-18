"""Prove the review rejects undersized and oversized GLBs with an unchanged manifest.

Scratch copies are preserved under TEMP. No source or installed asset is edited.
"""
import copy
import json
import os
from pathlib import Path
import shutil
import struct
import sys
import tempfile

from check import glb_json, run


def main(out):
    raw=(out/'station_T2_review.glb').read_bytes()
    old_length=struct.unpack('<I',raw[12:16])[0]
    binary=raw[20+old_length:]
    original=glb_json(out/'station_T2_review.glb')
    scratch=Path(tempfile.mkdtemp(prefix='station373_range_',dir=os.environ['TEMP']))
    results=[]
    for name,factor in [('undersized',0.4),('oversized',4.0)]:
        dest=scratch/name
        dest.mkdir()
        for file in ('manifest.json','game_inputs.json','fit.json'):
            shutil.copyfile(out/file,dest/file)
        glb=copy.deepcopy(original)
        root=next(n for n in glb['nodes'] if n.get('name')=='station_T2')
        root['scale']=[v*factor for v in root['scale']]
        payload=json.dumps(glb,separators=(',',':')).encode('utf-8')
        payload+=b' '*((-len(payload))%4)
        changed=struct.pack('<III',0x46546c67,2,20+len(payload)+len(binary))
        changed+=struct.pack('<II',len(payload),0x4e4f534a)+payload+binary
        (dest/'station_T2_review.glb').write_bytes(changed)
        accepted=run(dest)
        report=json.loads((dest/'review_checks.json').read_text())
        row=next(c for c in report['checks'] if c['name']=='R247 exported station range')
        if accepted or row['pass_']:
            raise ValueError('Review accepted the '+name+' actual GLB')
        results.append(dict(fault=name,rejected=True,evidence=row['evidence']))
    result=dict(status='PASS',method='Changed actual GLB root scale; manifest and fit stayed unchanged',
                cases=results)
    (out/'range_selftest.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS station range self-test: actual undersized and oversized GLBs rejected')


if __name__=='__main__': main(Path(sys.argv[1]))
