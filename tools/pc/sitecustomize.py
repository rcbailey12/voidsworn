# Voidsworn PC test shim: lets the Linux smoke scripts run unchanged on Windows.
# Loaded automatically by every Python process because run_smoke.bat puts this folder on PYTHONPATH.
import os, sys, subprocess, builtins, tempfile, shutil
KIT=os.path.dirname(os.path.abspath(__file__))
TMP=tempfile.gettempdir()
NODE=os.path.join(KIT,'node','node.exe')
def _fix(cmd):
    if isinstance(cmd,(list,tuple)) and cmd:
        cmd=list(cmd)
        if cmd[0] in ('python3','python'): cmd[0]=sys.executable
        elif cmd[0]=='node' and os.path.exists(NODE): cmd[0]=NODE
        cmd=[(os.path.join(TMP,c[5:]) if isinstance(c,str) and c.startswith('/tmp/') else c) for c in cmd]
    return cmd
_run=subprocess.run
def run(cmd,*a,**k):
    if (k.get('text') or k.get('universal_newlines')) and 'encoding' not in k: k['encoding']='utf-8'; k.setdefault('errors','replace')
    return _run(_fix(cmd),*a,**k)
subprocess.run=run
_open=builtins.open
def _o(f,*a,**k):
    if isinstance(f,str) and f.startswith('/tmp/'): f=os.path.join(TMP,f[5:])
    if 'b' not in (a[0] if a else k.get('mode','r')) and 'encoding' not in k: k['encoding']='utf-8'
    return _open(f,*a,**k)
builtins.open=_o
# Real GPU instead of SwiftShader unless VS_SOFTGPU=1
if os.environ.get('VS_SOFTGPU')!='1':
    try:
        from playwright.sync_api._generated import BrowserType
        _launch=BrowserType.launch
        def launch(self,*a,**k):
            k['args']=['--use-angle=d3d11','--ignore-gpu-blocklist','--enable-gpu-rasterization']
            return _launch(self,*a,**k)
        BrowserType.launch=launch
    except Exception as e: print('shim: playwright patch skipped',e)

# file:// URLs built as 'file://'+windows_path need three slashes and forward slashes
try:
    from playwright.sync_api._generated import Page
    _goto=Page.goto
    def goto(self,url,*a,**k):
        if isinstance(url,str) and url.startswith('file://') and not url.startswith('file:///'):
            url='file:///'+url[7:].replace('\\','/')
        return _goto(self,url,*a,**k)
    Page.goto=goto
except Exception as e: print('shim: goto patch skipped',e)
