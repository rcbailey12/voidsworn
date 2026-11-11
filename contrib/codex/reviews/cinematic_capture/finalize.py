from pack import *
import hashlib, re, subprocess

ROOT=OUT.parents[2]
REPORT=ROOT/'contrib/codex/reviews/cinematic_audit_capture.md'

def receipt():
    ranges={
        'godot/scenes/battle/battle.gd':'171-243;244-284;398-466;481-650;648-734;1491-1564;1604-1656;1773-1800;1936-2018;2396-2430;4246-4329;4633-4672;4705-4739;4864-4959;5004-5069;5099-5120',
        'godot/render/ship_view.gd':'741-785;856-877;981-1191;last line',
        'godot/fx/fx_weapons.gd':'1-135;146-195;196-255;561-605;861-915;926-964;1059-1117;last line',
        'godot/audio/sfx.gd':'1-25;37-65;137-180;176-235;253-299;371-435;last line',
        'godot/fx/fx.gd':'1-38;196-223;last line',
        'godot/fx/fx_death.gd':'1-85;1729-1810;last line',
        'godot/bench/look_bench.gd':'1-240;421-465;466-600;last line',
        'docs/playbooks/effects.md':'1-92',
        'docs/playbooks/deaths_and_hits.md':'1-153',
        'docs/playbooks/sound.md':'1-39',
        'docs/REVIEW_PROTOCOL.md':'1-35',
        'docs/ship_pipeline/AUDIT_BRIEF.md':'task context, not a ship-pipeline audit',
        'CODEX_TASK.md':'all',
        'godot/audio/cues.json':'hit and gun_las objects, final line',
        'godot/audio/clips/index.json':'hullHit, hullTick, laserLarge and laserLR pools, final line',
    }
    entries=[]
    for name,parts in ranges.items():
        b=(ROOT/name).read_bytes(); lines=b.decode('utf-8-sig').splitlines()
        entries.append({'file':name,'lines':len(lines),'bytes':len(b),'last_line_first_40':lines[-1][:40] if lines else '', 'sha256':hashlib.sha256(b).hexdigest(),'inspected_ranges':parts})
    (Path(__file__).parent/'read_receipt.json').write_text(json.dumps(entries,indent=2))
    table='## Read receipt\n\nLocal commit above is the reviewed source of truth. Raw main views were also opened through the GitHub connector for the cited code and playbooks. Main can advance independently. This is a capture audit with targeted code attribution, not a claim to have audited every line. The [read receipt](cinematic_capture/read_receipt.json) records SHA-256 hashes and the exact inspected ranges, including ranges for large files. Last-line strings below use JSON escaping for tabs or an empty line.\n\n| File | Total lines | First 40 characters of last line |\n|---|---:|---|\n'
    for e in entries:
        table+='| '+e['file']+' | '+str(e['lines'])+' | `'+json.dumps(e['last_line_first_40'])+'` |\n'
    s=REPORT.read_text();s=s.replace('43 PASS and 2 KNOWN','41 PASS and 2 KNOWN')
    s=s.replace('## Not checked\n',table+'\n## Not checked\n')
    REPORT.write_text(s)

def videos():
    dest=RAW/'motion_videos';dest.mkdir(exist_ok=True)
    for kind in ['straight','turn','final','obstacle']:
        data=json.loads((RAW/('motion_'+kind)/'motion.json').read_text())
        for row in data:
            if 'telemetry' not in row:continue
            ts=row['telemetry']; end=max(p['t'] for p in ts if p['moving'])+.15
            frames=[p for p in sorted((RAW/('motion_'+kind)/row['cls']).glob('*.jpg')) if int(p.stem)<len(ts) and ts[int(p.stem)]['t']<=end]
            writer=imageio_ffmpeg.write_frames(str(dest/(row['cls'].lower()+'_'+kind+'.mp4')),(1280,720),fps=10,codec='libx264',quality=6,ffmpeg_log_level='error')
            writer.send(None)
            for f in frames:
                im=Image.open(f).resize((1280,720));dr=ImageDraw.Draw(im)
                text(dr,(12,12),'%s | %s | t %.2f s | camera 170'%(row['cls'],kind,ts[int(f.stem)]['t']))
                writer.send(im.tobytes())
            writer.close()

def validate():
    files=list(OUT.glob('*.jpg'))
    assert len(files)==20, len(files)
    for p in files:
        im=Image.open(p);im.verify()
        assert Image.open(p).size==(1280,720),(p,Image.open(p).size)
    s=REPORT.read_text()
    assert '\u2014' not in s
    quoted=re.findall(r'(godot/[^:\s]+):(\d+), `([^`]+)`',s)
    assert len(quoted)==6,quoted
    for path,line,quote in quoted:
        actual=(ROOT/path).read_text().splitlines()[int(line)-1]
        assert quote in actual,(path,line,quote,actual)
        assert len(quote.split())<20,(path,quote)
        print('Verified quote:',path+':'+line,actual.strip())
    for target in re.findall(r'\]\(([^)]+)\)',s):
        assert (REPORT.parent/target).exists(),target
    assert len(json.loads((OUT/'movement_measurements.json').read_text()))==12
    for kind in ['straight','turn','final','obstacle']:
        b=(RAW.parent/('cine487_motion_'+kind+'.log')).read_bytes()
        log=b.decode('utf-16') if b'\x00' in b else b.decode('utf-8-sig',errors='replace')
        assert 'MOTION_DONE '+kind in log
    assert json.loads((RAW/'small/telemetry.json').read_text())['ended']
    assert not json.loads((RAW/'bench/bench.json').read_text())['warnings']
    changed=subprocess.check_output(['git','diff','--name-only'],cwd=ROOT,text=True)
    assert not changed.strip(),changed
    print('PASS: 20 labelled JPGs at 1280 x 720, 12 measured movement cases, report links, no em dashes, capture markers, no tracked game diff')

if __name__=='__main__':
    import sys
    {'receipt':receipt,'videos':videos,'validate':validate}[sys.argv[1]]()
