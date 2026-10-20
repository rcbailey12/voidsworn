import sys
mode=sys.argv[1] if len(sys.argv)>1 else 'test'
src='node_modules/babylonjs/babylon.js' if mode=='test' else 'https://cdnjs.cloudflare.com/ajax/libs/babylonjs/8.20.0/babylon.js'
import subprocess, datetime
try: gh=subprocess.run(['git','rev-parse','--short','HEAD'],capture_output=True,text=True).stdout.strip() or 'nogit'
except Exception: gh='nogit'
build_id=datetime.datetime.now().strftime('%Y%m%d-%H%M')+'-'+gh
js=f"const BUILD_ID='{build_id}';\n"+''.join(open(f).read()+'\n' for f in ['data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','sfx_data.js','sfx.js','gfx3d.js','vfx3d.js','campaign_meta.js','campaign_run.js','ui3d.js','campaign3d.js','main3d.js'])
# v41 guards: the page must parse, and no top-level name may be declared twice (a later file would silently win)
import re, tempfile, os, collections
names=collections.Counter(m.group(1) for m in re.finditer(r'^(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',js,re.M))
dups=[n for n,c in names.items() if c>1]
if dups: sys.exit('BUILD FAILED: duplicate top-level functions: '+', '.join(sorted(dups)))
with tempfile.NamedTemporaryFile('w',suffix='.js',delete=False) as tf: tf.write(js); tmp=tf.name
chk=subprocess.run(['node','--check',tmp],capture_output=True,text=True); os.unlink(tmp)
if chk.returncode: sys.exit('BUILD FAILED: script does not parse\n'+chk.stderr[-600:])
flag='<script>window.PREVIEW_DEMO=true</script>\n' if mode=='preview' else ''
html=open('head.html').read()+f'<script src="{src}"></script>\n'+flag+f'<script>\n{js}</script>\n</body>\n</html>\n'
out='index_test.html' if mode=='test' else ('voidsworn-3d-preview.html' if mode=='preview' else 'voidsworn-3d.html')
open(out,'w').write(html); print(out,len(html))
