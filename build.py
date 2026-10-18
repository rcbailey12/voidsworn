import sys
mode=sys.argv[1] if len(sys.argv)>1 else 'test'
src='node_modules/babylonjs/babylon.js' if mode=='test' else 'https://cdnjs.cloudflare.com/ajax/libs/babylonjs/8.20.0/babylon.js'
import subprocess, datetime
try: gh=subprocess.run(['git','rev-parse','--short','HEAD'],capture_output=True,text=True).stdout.strip() or 'nogit'
except Exception: gh='nogit'
build_id=datetime.datetime.now().strftime('%Y%m%d-%H%M')+'-'+gh
js=f"const BUILD_ID='{build_id}';\n"+''.join(open(f).read()+'\n' for f in ['data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','campaign_meta.js','campaign_run.js','ui3d.js','campaign3d.js','main3d.js'])
flag='<script>window.PREVIEW_DEMO=true</script>\n' if mode=='preview' else ''
html=open('head.html').read()+f'<script src="{src}"></script>\n'+flag+f'<script>\n{js}</script>\n</body>\n</html>\n'
out='index_test.html' if mode=='test' else ('voidsworn-3d-preview.html' if mode=='preview' else 'voidsworn-3d.html')
open(out,'w').write(html); print(out,len(html))
