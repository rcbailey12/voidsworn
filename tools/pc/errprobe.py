import os, threading, http.server, socketserver, functools, time
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__))
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
srv=socketserver.ThreadingTCPServer(('127.0.0.1',0),functools.partial(Q,directory=HERE)); threading.Thread(target=srv.serve_forever,daemon=True).start()
url='http://127.0.0.1:%d/index_test.html?shots'%srv.server_address[1]
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=d3d11']); pg=b.new_page(viewport={'width':1600,'height':900})
    errs=[]; pg.on('console',lambda m: errs.append(m.type+': '+m.text[:400]) if m.type in('error','warning') else None); pg.on('pageerror',lambda e: errs.append('PAGEERR '+str(e)[:600]))
    pg.goto(url); pg.wait_for_function("!!document.querySelector('.title .menu')",timeout=120000,polling=1000)
    for i in range(30):
        n=pg.evaluate("typeof AI_HULL_DATA!=='undefined'?Object.keys(AI_HULL_DATA).length:-1"); 
        if n>=30: break
        time.sleep(2)
    print('hulls loaded', n)
    r=pg.evaluate("""async()=>{ const out=[]; const ms=[]; for(const id of ['c_boss','reliquary','warden','i_song','b_razor']){ try{ const t=HULLS[id]; const m=buildShipModel(Object.assign({id:'t'+id,tpl:id},t)); if(m&&m.root){ m.root.setEnabled(true); m.root.getChildMeshes(false).forEach(x=>{x.setEnabled(true); ms.push([id,x]);}); } out.push(id+': '+(m?('ok meshes '+(m.meshes?m.meshes.length:'?')):'null')); }catch(e){ out.push(id+' ERR '+String(e.stack||e).slice(0,500)); } }
      for(let i=0;i<40;i++){ ms.forEach(([id,x])=>{ try{ x.material&&x.subMeshes&&x.material.isReady(x,true); }catch(e){} }); await new Promise(r=>setTimeout(r,100)); }
      const seen=new Set(); for(const [id,x] of ms){ const sm=x.subMeshes&&x.subMeshes[0]; const ef=sm&&(sm.effect||(sm._drawWrapper&&sm._drawWrapper.effect)); const err=ef&&ef.getCompilationError&&ef.getCompilationError(); const k=(x.material?x.material.name:'-'); if(err&&!seen.has(k)){ seen.add(k); out.push('SHADER ERR '+id+' mesh '+x.name+' mat '+k+': '+String(err).slice(0,900)); } if(!ef&&x.material&&!seen.has('noeffect'+k)){ seen.add('noeffect'+k); out.push('no effect yet '+id+' '+x.name+' '+k); } }
      return out.join('\\n') }""")
    print(r); time.sleep(3)
    print('\n'.join(errs[:40])); b.close()
