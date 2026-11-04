"""D1 sheet. Run with the PC's ComfyUI Python (Pillow installed)."""
import pathlib, sys, urllib.request, re, html, io
from PIL import Image, ImageDraw, ImageFont, ImageOps

out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
fontdir = pathlib.Path('C:/Windows/Fonts')
def font(n): return ImageFont.truetype(str(fontdir / 'segoeui.ttf'), n)
im = Image.new('RGB', (1920, 1320), '#151320'); d = ImageDraw.Draw(im)
d.text((54, 30), 'SHIP DEATHS / SPACE GRAMMAR', font=font(42), fill='#e9e2d3')
d.text((54, 90), 'Issue 137 | Four readable beats | Fixed exposure | Broad shapes, sparse sparks', font=font(24), fill='#b6adc8')
beats = [('01  POWER LOSS', '0.00 - 0.30 s', 'Section lights die.', 'Quiet blue-white tear.'), ('02  VENT', '0.30 - 0.80 s', 'Gas leaves the tear normal.', 'Flash, then snuff.'), ('03  BREAK', '0.80 - 1.60 s', '2 cruiser / 3 battleship cuts.', 'One core + at most 2 pops.'), ('04  DRIFT + COOL', '1.60 - 2.00 s', 'Sealed sections keep moving.', '14 s cheap cooling tail.')]
for i, b in enumerate(beats):
    x = 54 + i * 465
    d.rounded_rectangle((x, 158, x+440, 430), radius=16, fill='#252132')
    for y, text, size, col in [(180,b[0],26,'#d8c5a0'), (230,b[1],30,'#e2e3ef'), (300,b[2],21,'#bfb8cd'), (340,b[3],21,'#bfb8cd')]: d.text((x+20,y),text,font=font(size),fill=col)
d.text((54, 460), 'SMALL HULL: lights 0.00 / vent 0.12 / pop + chunks 0.55 / drift 0.85 / settled by 1.15 s',font=font(25),fill='#d2c7dd')
for i, (name, col) in enumerate([('HOT IVORY','#eee0bd'),('AMBER','#d08b42'),('DEEP RED','#80362e'),('COLD METAL','#302834'),('REACTOR','#bdcce6'),('VAPOUR','#70617e')]):
    x=54+i*310; d.rectangle((x,530,x+286,600),fill=col); d.text((x,610),name,font=font(21),fill='#bfb8cd')
refs = [
 ('HOMEWORLD 3', 'Broken silhouettes / local events', 'https://store.steampowered.com/news/app/1840080/view/3669906156890227103', 'homeworld'),
 ('EVE ONLINE', 'Staged flashes / optical-flow language', 'https://realtimevfx.com/uploads/default/original/2X/9/9d069e878ac3075561ff7435cb0c0c99502f618b.gif', 'eve'),
 ('THE EXPANSE', 'Coherent motion / space reference', 'https://vfxvoice.com/new-visual-vistas-propel-the-expanse-into-higher-orbit/', 'expanse')]
for i,(name,note,url,tag) in enumerate(refs):
    x=54+i*620
    try:
        req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})
        raw=urllib.request.urlopen(req,timeout=35).read()
        if tag=='homeworld':
            url='https://clan.fastly.steamstatic.com/images/41623886/13ce6fcf6c7c4608aa557c70215db1a727dff4e1.png'
            raw=urllib.request.urlopen(url,timeout=35).read()
        elif tag=='expanse':
            url='https://vfxvoice.com/wp-content/uploads/2020/09/PIX-8-Roci_Barb_Tow_Spacewalk_Final_1.3.1-copy.jpg'
            raw=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=35).read()
        elif tag!='eve':
            page=raw.decode('utf-8','replace')
            candidates=re.findall(r'(?:src|data-src)=[\"\']([^\"\']+\.(?:jpg|png|gif|webp)(?:\?[^\"\']*)?)[\"\']',page,re.I)
            candidates=[html.unescape(u) for u in candidates if (('steamstatic' in u or 'steamusercontent' in u) if tag=='homeworld' else ('EXPANSE' in u.upper() or 'Expanse' in u))]
            if not candidates: raise RuntimeError('No reference image on page')
            url=candidates[-1] if tag=='homeworld' else candidates[0]
            raw=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=35).read()
        ref=Image.open(io.BytesIO(raw)); ref.seek(min(12, getattr(ref,'n_frames',1)-1)); ref=ref.convert('RGB')
        if tag=='homeworld': ref=ref.crop((0,int(ref.height*.13),int(ref.width*.72),int(ref.height*.82)))
        ref.save(out/(tag+'_reference.jpg'))
        im.paste(ImageOps.fit(ref,(590,320)),(x,725))
        (out/(tag+'_source.txt')).write_text(url,encoding='utf-8')
    except Exception as e:
        d.rectangle((x,725,x+590,1045),fill='#292536'); d.text((x+12,850),'Reference unavailable: '+type(e).__name__,font=font(19),fill='#d3a7a7')
    d.text((x,670),name,font=font(27),fill='#e0d7c7'); d.text((x,1064),note,font=font(21),fill='#bbb1cc')
d.text((54,1130),'MAX: lit flow blend + vents + sparks + hot rims     HIGH: no fracture glow     LOW: flash + drifting sections',font=font(24),fill='#c3b7d0')
d.text((54,1180),'Three counted flashes per rolling second. Calm mode: quiet puff. R80 persistent damage stays unchanged.',font=font(23),fill='#a99ab9')
d.text((54,1230),'Published study frames only. Sources and exact timing: tools/blender/vfx/grammar.md',font=font(21),fill='#82768f')
im.save(out/'death_grammar.png')
