import numpy as np, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
GF='/home/claude/voidsworn/godot/ui/theme/fonts/'; F='/home/claude/rail/fonts/'
def font(path,size,wght=None):
    f=ImageFont.truetype(path,size)
    if wght is not None:
        try: f.set_variation_by_axes([wght])
        except Exception as e: pass
    return f
CP=lambda s,w='Regular': font(GF+f'ChakraPetch-{w}.ttf',s)
MONO=lambda s,w=500: font(GF+'AzeretMono-VF.ttf',s,w)
BSD=lambda s,w=700: font(F+'BigShouldersDisplay[wght].ttf',s,w)
BAR=lambda s,w='Regular': font(F+f'Barlow-{w}.ttf',s)
BARC=lambda s,w='SemiBold': font(F+f'BarlowCondensed-{w}.ttf',s)
SP=lambda s,w='Regular': font(F+f'Spectral-{w}.ttf',s)
SPSC=lambda s,w='Medium': font(F+f'SpectralSC-{w}.ttf',s)
BONE=(236,230,216); DIM=(163,157,143); FAINT=(112,106,96); EMBER=(255,138,58); EMBER2=(200,96,34); RED=(255,96,80); INK=(14,12,10)
base=Image.open('base.png').convert('RGB'); W,H=base.size; RAIL=480
portrait=base.crop((44,708,128,792))
def scene():
    a=np.asarray(base).astype(np.float32); r,g,b=a[...,0],a[...,1],a[...,2]
    m=(g>120)&(r>90)&(b<140)&(g>r*1.05)&((g-b)>70)
    lum=(0.3*r+0.6*g+0.1*b)/ (0.3*200+0.6*245+0.1*58)
    for i,c in enumerate(EMBER): a[...,i]=np.where(m,np.clip(c*lum,0,255),a[...,i])
    return Image.fromarray(a.astype(np.uint8))
SC=scene()
def wrap(d,text,f,width):
    words=text.split(); lines=[]; cur=''
    for w in words:
        t=(cur+' '+w).strip()
        if d.textlength(t,font=f)<=width: cur=t
        else: lines.append(cur); cur=w
    if cur: lines.append(cur)
    return lines
def para(d,x,y,text,f,fill,width,lh):
    for l in wrap(d,text,f,width): d.text((x,y),l,font=f,fill=fill); y+=lh
    return y
def pips(d,x,y,n,of,col,size=9,gap=4,off=FAINT):
    for i in range(of):
        box=(x+i*(size+gap),y,x+i*(size+gap)+size,y+size)
        fill=col if i+1<=n else None
        if fill: d.rectangle(box,fill=fill)
        else:
            d.rectangle(box,outline=off)
            if n>i: d.rectangle((box[0],box[1],box[0]+int(size*(n-i)),box[3]),fill=col)
def rtext(d,xr,y,t,f,fill): d.text((xr-d.textlength(t,font=f),y),t,font=f,fill=fill)
FLEET=[('Cold Fury','Cruiser Mk I','135','135',True),('Edge of Winter','Destroyer Mk I','98','98',False),('Black Anvil','Frigate Mk I','50','50',False)]

# ---------- R1: keep and correct ----------
def r1():
    im=SC.copy(); d=ImageDraw.Draw(im); d.rectangle((0,0,RAIL,H),fill=(15,15,14)); d.line((RAIL,0,RAIL,H),fill=(40,38,34))
    x=40; R=RAIL-40
    d.text((x,38),'Sector I of III',font=CP(17,'Medium'),fill=DIM); rtext(d,R,38,'Jump 1 of 7',CP(17),FAINT)
    d.text((x,66),'Old Battlefield',font=CP(44,'SemiBold'),fill=BONE)
    y=para(d,x,124,'Held by Ashfall Hullbreakers. Ion season: ion storms sweep every battlefield, and shields recharge 25% slower on both sides.',CP(17),DIM,R-x,24)
    y+=22; d.line((x,y,R,y),fill=(48,46,41)); y+=18
    d.text((x,y),'Routes from Engagement',font=CP(16),fill=FAINT); y+=36
    d.rectangle((x,y,x+3,y+186),fill=EMBER)
    d.text((x+20,y-6),'1',font=CP(40,'Bold'),fill=EMBER); d.text((x+58,y),'Relay',font=CP(32,'SemiBold'),fill=BONE)
    pips(d,R-92,y+16,1,4,BONE,8,3); rtext(d,R,y+10,'Easy',CP(16),DIM)
    yy=y+48; d.text((x+20,yy),'Fight an Ashfall Hullbreakers hulk den',font=CP(17),fill=BONE); yy+=28
    yy=para(d,x+20,yy,'Have a ship next to the relay, with no enemy there, at the start of 3 rounds.',CP(16),DIM,R-x-20,22); yy+=8
    d.text((x+20,yy),'Pays',font=CP(15),fill=FAINT); d.text((x+62,yy),'Signal of Kharon',font=CP(16,'Medium'),fill=BONE)
    d.text((x+226,yy),'then',font=CP(15),fill=FAINT); d.text((x+268,yy),'Shipyard',font=CP(16,'Medium'),fill=BONE)
    y+=206
    for n,name,meta in [('2','Breakthrough','Easy · Signal of Astra'),('3','Unknown signal','No fight · Unknown')]:
        d.text((x+20,y),n,font=CP(22,'SemiBold'),fill=DIM); d.text((x+58,y),name,font=CP(22,'Medium'),fill=(200,194,180)); rtext(d,R,y+5,meta,CP(15),FAINT); y+=40
    y+=14; d.rectangle((x,y,R,y+54),fill=EMBER); d.text((x+18,y+14),'Jump to Relay',font=CP(21,'SemiBold'),fill=INK); rtext(d,R-18,y+18,'Enter',CP(15,'Medium'),(90,44,12)); y+=54+30
    d.line((x,y,R,y),fill=(48,46,41)); y+=20
    im.paste(portrait.resize((64,64)),(x,y)); d.rectangle((x,y,x+63,y+63),outline=(70,66,60))
    d.text((x+80,y-2),'Nemesis',font=CP(15,'Medium'),fill=RED); rtext(d,R,y-2,'Dossier',CP(15),FAINT)
    d.text((x+80,y+18),'High Nadir Essane',font=CP(20,'SemiBold'),fill=BONE); d.text((x+80,y+46),'Eclipse. Cruel: finishes crippled ships first.',font=CP(14),fill=DIM)
    y+=80; d.text((x,y),'Hunt clock',font=CP(15),fill=FAINT); pips(d,x+92,y+5,0.5,4,RED,10,4); d.text((x+156,y),'0.5 of 4',font=MONO(14),fill=DIM)
    y=H-212; d.line((x,y,R,y),fill=(48,46,41)); y+=18; d.text((x,y),'Fleet',font=CP(16),fill=FAINT); rtext(d,R,y,'Fleet and refits',CP(15),FAINT); y+=32
    for name,cls,hp,mx,flag in FLEET:
        d.text((x,y),name,font=CP(18,'Medium'),fill=BONE); d.text((x+178,y+3),cls+('  flagship' if flag else ''),font=CP(14),fill=EMBER2 if flag else FAINT); rtext(d,R,y+1,hp,MONO(17,600),BONE); y+=30
    y+=6; d.text((x,y),'Faction action: Keep the dawn watch',font=CP(15),fill=DIM); rtext(d,R,y,'40 credits',MONO(14),DIM)
    return im

def dark_left(width,strength=1.0):
    im=SC.copy(); a=np.asarray(im).astype(np.float32)
    random.seed(4); left=np.zeros((H,RAIL,3),np.float32)+np.array([5,5,6])
    for _ in range(260):
        px,py=random.randrange(RAIL),random.randrange(H); v=random.choice([40,60,60,90,140]); left[py,px]=v
    a[:,:RAIL]=left
    xs=np.arange(W); k=np.clip(1-(xs/width),0,1)**1.4*0.92*strength; a=a*(1-k)[None,:,None]+np.array([8,7,7])[None,None,:]*k[None,:,None]
    return Image.fromarray(a.astype(np.uint8))

# ---------- R2: orders sheet ----------
def r2():
    im=dark_left(760); d=ImageDraw.Draw(im); x=56; R=470
    # approach strip: three legs to the star
    y=46
    for i,lab in enumerate(['I','II','III']):
        x0=x+i*74; col=EMBER if i==0 else FAINT
        d.line((x0,y+8,x0+58,y+8),fill=col,width=3 if i==0 else 1); d.text((x0,y+16),lab,font=BARC(17),fill=col)
    d.ellipse((x+226,y+1,x+240,y+15),outline=EMBER2,width=2); d.text((x+254,y-2),'Jump 1 of 7',font=BAR(17),fill=DIM)
    d.text((x-3,90),'OLD BATTLEFIELD',font=BSD(68,800),fill=BONE)
    d.text((x,172),'Held by the Ashfall Hullbreakers',font=BAR(20,'Medium'),fill=BONE)
    y=para(d,x,202,'Ion season. Storms sweep every battlefield; shields recharge 25% slower for both sides.',BAR(17),DIM,R-x,24)
    y+=26
    d.text((x-6,y-22),'1',font=BSD(150,800),fill=EMBER)
    d.text((x+84,y),'RELAY',font=BSD(56,700),fill=BONE)
    d.text((x+86,y+66),'Hullbreaker hulk den',font=BAR(19,'Medium'),fill=BONE); pips(d,x+86,y+100,1,4,BONE,8,3); d.text((x+138,y+93),'Easy',font=BAR(17),fill=DIM)
    y+=150
    y=para(d,x,y,'Hold a ship beside the relay, with no enemy near it, at the start of 3 rounds.',BAR(18),BONE,R-x,26); y+=8
    d.text((x,y),'Pays Signal of Kharon. Leads to a shipyard.',font=BAR(17),fill=DIM); y+=44
    d.line((x,y,R,y),fill=EMBER,width=2); y+=12
    d.text((x,y),'JUMP TO RELAY',font=BSD(34,700),fill=EMBER); rtext(d,R-22,y+10,'Enter',BAR(17,'Medium'),EMBER); d.polygon([(R-12,y+14),(R,y+21),(R-12,y+28)],fill=EMBER); y+=62
    for n,name,meta in [('2','BREAKTHROUGH','Easy.  Pays Signal of Astra'),('3','UNKNOWN SIGNAL','No fight.  Anything can happen')]:
        d.text((x,y-2),n,font=BSD(34,700),fill=DIM); d.text((x+34,y),name,font=BSD(30,600),fill=(196,190,176)); y+=36
        d.text((x+34,y),meta,font=BAR(16),fill=FAINT); y+=32
    y+=10
    im.paste(portrait.resize((58,58)),(x,y)); d.rectangle((x,y,x+57,y+57),outline=RED)
    d.text((x+74,y-4),'Hunting you',font=BAR(15,'Medium'),fill=RED); d.text((x+74,y+14),'HIGH NADIR ESSANE',font=BSD(30,700),fill=BONE)
    y+=64; d.text((x,y),'Eclipse. Cruel: finishes crippled ships first.',font=BAR(16),fill=DIM); y+=26
    pips(d,x,y+4,0.5,4,RED,12,5); d.text((x+78,y),'half a step of four before she strikes',font=BAR(15),fill=FAINT)
    y=H-150; d.line((x,y-14,R,y-14),fill=(56,52,46))
    for name,cls,hp,mx,flag in FLEET:
        d.text((x,y),name.upper(),font=BSD(24,600),fill=BONE)
        if flag: d.text((x+d.textlength(name.upper(),font=BSD(24,600))+10,y+3),'flagship',font=BAR(14),fill=EMBER2)
        d.text((x+250,y+5),cls,font=BAR(15),fill=FAINT); rtext(d,R,y+2,hp,MONO(18,600),BONE); y+=32
    y+=10; d.text((x,y),'Keep the dawn watch',font=BAR(16),fill=DIM); rtext(d,R,y,'40 cr',MONO(15),DIM)
    
    return im

# ---------- R3: chart margin ----------
def r3():
    im=dark_left(600,0.9); d=ImageDraw.Draw(im); x=44; R=330
    d.line((R+26,0,R+26,H),fill=(74,68,58))
    for i in range(0,H,27): d.line((R+26,i,R+26+(10 if (i//27)%5==0 else 5),i),fill=(92,84,70))
    d.text((x,40),'Sector I of III  ·  jump 1 of 7',font=SP(17,'Italic'),fill=DIM)
    d.text((x,70),'Old',font=SPSC(52),fill=BONE); d.text((x,124),'Battlefield',font=SPSC(52),fill=BONE)
    y=para(d,x,200,'Held by the Ashfall Hullbreakers.',SP(19,'Medium'),BONE,R-x,26)
    y=para(d,x,y+4,'Ion season: storms sweep every battlefield, and shields recharge a quarter slower for both sides.',SP(17,'Italic'),DIM,R-x,24)
    y+=30; d.line((x,y,R,y),fill=(74,68,58)); y+=20
    d.text((x,y),'The Nemesis',font=SPSC(19),fill=RED); y+=30
    im.paste(portrait.resize((56,56)),(x,y)); d.rectangle((x,y,x+55,y+55),outline=(110,100,86))
    d.text((x+70,y-2),'High Nadir',font=SP(21,'Medium'),fill=BONE); d.text((x+70,y+24),'Essane',font=SP(21,'Medium'),fill=BONE); y+=68
    y=para(d,x,y,'Eclipse. Cruel: finishes crippled ships first.',SP(16,'Italic'),DIM,R-x,22); y+=8
    pips(d,x,y+5,0.5,4,RED,10,4); d.text((x+68,y),'hunt clock, 0.5 of 4',font=SP(15,'Italic'),fill=FAINT)
    y=H-300; d.line((x,y,R,y),fill=(74,68,58)); y+=18; d.text((x,y),'The Fleet',font=SPSC(19),fill=DIM); y+=34
    for name,cls,hp,mx,flag in FLEET:
        d.text((x,y),name,font=SP(19,'Medium'),fill=BONE); rtext(d,R,y+2,hp,MONO(16,600),BONE); y+=24
        d.text((x,y),cls+(', flagship' if flag else ''),font=SP(15,'Italic'),fill=FAINT); y+=30
    d.text((x,y+4),'Keep the dawn watch',font=SP(16,'Italic'),fill=DIM); rtext(d,R,y+6,'40 cr',MONO(14),DIM)
    # annotations on the chart, by each choice
    def note(px,py,lines,sel=False):
        d.line((px-14,py-6,px-14,py+len(lines)*23-2),fill=EMBER if sel else (120,110,94),width=2 if sel else 1)
        for i,(t,f,c) in enumerate(lines):
            for dx,dy in [(-1,0),(1,0),(0,1),(0,-1),(1,1),(-1,-1)]: d.text((px+dx,py+i*23+dy),t,font=f,fill=(6,6,6))
            d.text((px,py+i*23),t,font=f,fill=c)
    it=SP(17,'Italic'); md=SP(17,'Medium')
    note(606,330,[('Hulk den, easy',md,BONE),('Hold the relay for 3 rounds',it,BONE),('Pays Signal of Kharon',it,DIM)],True)
    note(826,386,[('Hulk convoy, easy',it,DIM),('Pays Signal of Astra',it,DIM)])
    note(962,612,[('No fight: anything can happen',it,DIM)])
    # action at the foot of the chart
    bx,by=1920//2+120,H-92
    d.line((bx-250,by-14,bx+250,by-14),fill=EMBER,width=2)
    t='Jump to Relay'; f=SPSC(30); tw=d.textlength(t,font=f); d.text((bx-tw/2,by-6),t,font=f,fill=EMBER)
    t2='press Enter'; f2=SP(16,'Italic'); d.text((bx-d.textlength(t2,font=f2)/2,by+34),t2,font=f2,fill=DIM)
    return im

# ---------- R2b: orders sheet after the readability pass ----------
def r2b():
    TXT=(240,234,222); SEC=(196,190,176); TER=(150,144,132)
    im=dark_left(820,1.08); d=ImageDraw.Draw(im); x=52; R=500
    y=40
    for i,lab in enumerate(['I','II','III']):
        x0=x+i*80; col=EMBER if i==0 else TER
        d.line((x0,y+8,x0+62,y+8),fill=col,width=4 if i==0 else 2); d.text((x0,y+16),lab,font=BARC(20),fill=col)
    d.ellipse((x+244,y,x+260,y+16),outline=EMBER,width=2); d.text((x+276,y-4),'Jump 1 of 7',font=BAR(19,'Medium'),fill=SEC)
    d.text((x-3,86),'OLD BATTLEFIELD',font=BSD(70,800),fill=TXT)
    d.text((x,170),'Held by the Ashfall Hullbreakers',font=BAR(21,'Medium'),fill=TXT)
    y=para(d,x,202,'Ion season: storms sweep every battlefield, and shields recharge 25% slower for both sides.',BAR(19),SEC,R-x,26)
    y+=22
    d.text((x-6,y-20),'1',font=BSD(132,800),fill=EMBER)
    d.text((x+78,y),'RELAY',font=BSD(54,700),fill=TXT)
    d.text((x+80,y+62),'Fight a Hullbreaker hulk den',font=BAR(20,'Medium'),fill=TXT)
    pips(d,x+80,y+98,1,4,TXT,10,4,TER); d.text((x+144,y+90),'Easy',font=BAR(19,'Medium'),fill=SEC)
    y+=136
    y=para(d,x,y,'Hold a ship beside the relay, with no enemy near it, at the start of 3 rounds.',BAR(20),TXT,R-x,28); y+=6
    d.text((x,y),'Pays',font=BAR(19),fill=TER); d.text((x+48,y),'Signal of Kharon',font=BAR(19,'Medium'),fill=TXT)
    d.text((x+210,y),'then',font=BAR(19),fill=TER); d.text((x+256,y),'a shipyard',font=BAR(19,'Medium'),fill=TXT); y+=42
    d.rectangle((x,y,R,y+56),outline=EMBER,width=2)
    d.text((x+16,y+8),'JUMP TO RELAY',font=BSD(34,700),fill=EMBER); rtext(d,R-38,y+16,'Enter',BAR(19,'Medium'),EMBER); d.polygon([(R-28,y+20),(R-14,y+28),(R-28,y+36)],fill=EMBER); y+=56+26
    for n,name,meta in [('2','BREAKTHROUGH','Fight, easy.  Pays Signal of Astra'),('3','UNKNOWN SIGNAL','No fight.  Anything can happen')]:
        d.text((x,y-2),n,font=BSD(36,700),fill=SEC); d.text((x+36,y),name,font=BSD(32,600),fill=TXT); y+=38
        d.text((x+36,y),meta,font=BAR(18),fill=SEC); y+=36
    y+=6; d.line((x,y,R,y),fill=(70,64,56)); y+=18
    im.paste(portrait.resize((64,64)),(x,y)); d.rectangle((x,y,x+63,y+63),outline=RED,width=2)
    d.text((x+80,y-4),'Nemesis, hunting you',font=BAR(17,'Medium'),fill=RED); d.text((x+80,y+18),'HIGH NADIR ESSANE',font=BSD(32,700),fill=TXT); rtext(d,R,y-4,'Dossier',BAR(17),TER)
    y+=74; d.text((x,y),'Eclipse. Cruel: finishes crippled ships first.',font=BAR(18),fill=SEC); y+=30
    pips(d,x,y+4,0.5,4,RED,13,5,TER); d.text((x+84,y),'Hunt clock 0.5 of 4',font=BAR(18),fill=SEC)
    y=H-152; d.line((x,y-14,R,y-14),fill=(70,64,56))
    for name,cls,hp,mx,flag in FLEET:
        d.text((x,y),name.upper(),font=BSD(28,600),fill=TXT)
        d.text((x+214,y+5),cls,font=BAR(17),fill=SEC); rtext(d,R,y+3,hp+' hull',MONO(18,600),TXT)
        if flag: d.text((x+340,y+5),'flagship',font=BAR(17,'Medium'),fill=EMBER)
        y+=34
    y+=8; d.text((x,y),'Faction action: keep the dawn watch',font=BAR(18),fill=SEC); rtext(d,R,y+1,'40 credits',MONO(16),SEC)
    return im

# ---------- R2c: trimmed (Ryan: do not explain everything; fleet text overlap fixed; faction action off the rail) ----------
def r2c():
    TXT=(240,234,222); SEC=(196,190,176); TER=(150,144,132)
    im=dark_left(820,1.08); d=ImageDraw.Draw(im); x=52; R=500
    y=40
    for i,lab in enumerate(['I','II','III']):
        x0=x+i*80; col=EMBER if i==0 else TER
        d.line((x0,y+8,x0+62,y+8),fill=col,width=4 if i==0 else 2); d.text((x0,y+16),lab,font=BARC(20),fill=col)
    d.ellipse((x+244,y,x+260,y+16),outline=EMBER,width=2); d.text((x+276,y-4),'Jump 1 of 7',font=BAR(19,'Medium'),fill=SEC)
    d.text((x-3,86),'OLD BATTLEFIELD',font=BSD(70,800),fill=TXT)
    d.text((x,170),'Held by the Ashfall Hullbreakers',font=BAR(21,'Medium'),fill=TXT)
    d.text((x,202),'Ion season: shields recharge 25% slower.',font=BAR(19),fill=SEC)
    y=262
    d.text((x-6,y-20),'1',font=BSD(132,800),fill=EMBER)
    d.text((x+78,y),'RELAY',font=BSD(54,700),fill=TXT)
    d.text((x+80,y+62),'Fight a Hullbreaker hulk den',font=BAR(20,'Medium'),fill=TXT)
    pips(d,x+80,y+98,1,4,TXT,10,4,TER); d.text((x+144,y+90),'Easy',font=BAR(19,'Medium'),fill=SEC)
    y+=140
    y=para(d,x,y,'Hold a ship beside the relay for 3 rounds.',BAR(20),TXT,R-x,28); y+=4
    d.text((x,y),'Pays',font=BAR(19),fill=TER); d.text((x+48,y),'Signal of Kharon',font=BAR(19,'Medium'),fill=TXT); y+=44
    d.rectangle((x,y,R,y+56),outline=EMBER,width=2)
    d.text((x+16,y+8),'JUMP TO RELAY',font=BSD(34,700),fill=EMBER); rtext(d,R-38,y+16,'Enter',BAR(19,'Medium'),EMBER); d.polygon([(R-28,y+20),(R-14,y+28),(R-28,y+36)],fill=EMBER); y+=56+34
    for n,name,meta in [('2','BREAKTHROUGH','Easy fight. Pays Signal of Astra'),('3','UNKNOWN SIGNAL','No fight')]:
        d.text((x,y-2),n,font=BSD(36,700),fill=SEC); d.text((x+36,y),name,font=BSD(32,600),fill=TXT); y+=38
        d.text((x+36,y),meta,font=BAR(18),fill=SEC); y+=42
    y=H-322; d.line((x,y,R,y),fill=(70,64,56)); y+=22
    im.paste(portrait.resize((64,64)),(x,y)); d.rectangle((x,y,x+63,y+63),outline=RED,width=2)
    d.text((x+80,y-2),'Nemesis',font=BAR(17,'Medium'),fill=RED); d.text((x+80,y+20),'HIGH NADIR ESSANE',font=BSD(32,700),fill=TXT); rtext(d,R,y-2,'Dossier',BAR(17),TER)
    y+=78; pips(d,x,y+4,0.5,4,RED,13,5,TER); d.text((x+84,y),'Hunt clock 0.5 of 4',font=BAR(18),fill=SEC)
    y=H-166; d.line((x,y-18,R,y-18),fill=(70,64,56))
    for name,cls,hp,mx,flag in FLEET:
        if flag: d.polygon([(x,y+17),(x+7,y+10),(x+14,y+17),(x+7,y+24)],fill=EMBER)
        d.text((x+24,y),name.upper(),font=BSD(28,600),fill=TXT); rtext(d,R,y+3,hp,MONO(19,600),TXT); y+=36
    d.text((x+24,y+4),'Fleet and refits',font=BAR(17),fill=TER)
    return im
for name,fn in [('R1',r1),('R2',r2),('R3',r3),('R2b',r2b),('R2c',r2c)]:
    im=fn(); im.save(f'out/{name}.png'); im.resize((1280,720),Image.LANCZOS).save(f'out/{name}_small.jpg',quality=88)

names={'R1':'R1  Keep and correct: same layout, the tells removed','R2':'R2  Orders sheet: no panel, one big focus','R3':'R3  Chart margin: details sit on the map'}
sheet=Image.new('RGB',(1280,(720+56)*3),(0,0,0)); dd=ImageDraw.Draw(sheet)
for i,n in enumerate(['R1','R2','R3']):
    y=i*776; dd.rectangle((0,y,1280,y+56),fill=(22,21,19)); dd.text((20,y+12),names[n],font=BAR(26,'Medium'),fill=BONE)
    sheet.paste(Image.open(f'out/{n}.png').resize((1280,720),Image.LANCZOS),(0,y+56))
sheet.save('out/rail_options.jpg',quality=87); print(sheet.size)
