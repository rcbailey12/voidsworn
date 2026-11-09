import sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'  # folder holding o1r.png to o3b.png and s1.png to s3.png
F='godot/ui/'  # run from the repo root
ox=lambda s: ImageFont.truetype(F+'campaign/fonts/Oxanium-Variable.ttf', s)
br=lambda s: ImageFont.truetype(F+'battle/fonts/BarlowSemiCondensed-SemiBold.ttf', s)
brr=lambda s: ImageFont.truetype(F+'battle/fonts/BarlowSemiCondensed-Regular.ttf', s)
rows=[('1','Command Dock','actions in a console along the bottom; roster left, log right'),
      ('2','Action Column','one right-hand column in decision order; End ship in the corner'),
      ('3','Chart Frame','ruled chart margins; the order card docks beside the ship that is up')]
W,TW,TH,G=1960,960,540,14
H=150+len(rows)*(TH+136)+20
sh=Image.new('RGB',(W,H),(10,14,24)); d=ImageDraw.Draw(sh)
d.text((G+6,22),'BATTLE SCREEN MOCKUPS, ROUND 1 (ISSUE 271)',font=ox(44),fill=(230,220,196))
d.text((G+6,84),'Three layouts, each restrained (left) and bold (right). One style for every faction. Pick a layout and a variation.',font=brr(32),fill=(179,170,149))
y=150
for n,name,desc in rows:
    d.text((G+6,y+8),f'{n}  {name.upper()}',font=ox(40),fill=(208,166,75))
    d.text((G+6+ d.textlength(f'{n}  {name.upper()}',font=ox(40))+22,y+16),desc,font=brr(30),fill=(179,170,149))
    y+=60
    for j,v in enumerate(['r','b']):
        x=G+j*(TW+G+12); lab=f'{n}{"A" if v=="r" else "B"}  {"RESTRAINED" if v=="r" else "BOLD"}'
        d.text((x+2,y),lab,font=ox(30),fill=(230,220,196))
    y+=44
    for j,v in enumerate(['r','b']):
        im=Image.open(f'{OUT}/o{n}{v}.png').convert('RGB').resize((TW,TH),Image.LANCZOS)
        x=G+j*(TW+G+12)
        sh.paste(im,(x,y)); d.rectangle((x-1,y-1,x+TW,y+TH),outline=(60,72,96))
    y+=TH+32
sh.save(f'{OUT}/contact_sheet.jpg',quality=90)
# 20-ship stress sheet
S=Image.new('RGB',(W,150+3*(TH+80)),(10,14,24)); d=ImageDraw.Draw(S)
d.text((G+6,22),'THE SAME THREE LAYOUTS WITH 20 SHIPS (RESTRAINED)',font=ox(40),fill=(230,220,196))
d.text((G+6,80),'Every roster holds all 20 at 1080 without scrolling.',font=brr(32),fill=(179,170,149))
y=140
for n,name,_ in rows:
    im=Image.open(f'{OUT}/s{n}.png').convert('RGB')
    d.text((G+6,y+4),f'{n}  {name.upper()}',font=ox(34),fill=(208,166,75)); y+=52
    a=im.resize((TW,TH),Image.LANCZOS); S.paste(a,(G,y))
    crop=im.crop((0,0,640,360)).resize((TW,TH),Image.LANCZOS)
    S.paste(crop,(G+TW+G+12,y)); y+=TH+28
S.save(f'{OUT}/stress_20_ships.jpg',quality=88)
print(sh.size,S.size)
