import sys, cv2, numpy as np
# Usage: python3 build_bg.py <bench207 scene_engagement as png> <out bg.png>. Paints out the old HUD panels and plates.
im=cv2.imread(sys.argv[1])
H,W=im.shape[:2]
plates=[(465,384,558,412),(435,426,542,452),(375,460,528,492),(275,506,398,532),(360,532,458,558),(325,616,420,642),
(615,522,820,546),(638,554,842,578),(1318,384,1420,412),(1430,402,1522,412),(1345,428,1450,454),(1450,428,1560,454),
(1420,466,1558,494),(1375,508,1465,520),(1395,520,1560,546),(1390,576,1495,604),(1430,654,1535,682)]
m=np.zeros((H,W),np.uint8)
for x0,y0,x1,y1 in plates: m[y0-2:y1+2,x0-3:x1+3]=255
im=cv2.inpaint(im,m,5,cv2.INPAINT_TELEA)
hud=[(0,0,1920,76),(0,64,272,752),(262,68,447,120),(754,62,1166,113),(1556,64,1920,896),(0,928,454,1080),(600,880,1320,1080)]
M=np.zeros((H,W),np.uint8)
for x0,y0,x1,y1 in hud: M[y0:y1,x0:x1]=255
q=4
sm=cv2.resize(im,(W//q,H//q),interpolation=cv2.INTER_AREA); sM=cv2.resize(M,(W//q,H//q),interpolation=cv2.INTER_NEAREST)
sM=cv2.dilate(sM,np.ones((3,3),np.uint8))
f=cv2.inpaint(sm,sM,15,cv2.INPAINT_TELEA)
f=cv2.GaussianBlur(f,(0,0),3)
f=cv2.resize(f,(W,H),interpolation=cv2.INTER_CUBIC)
# sprinkle stars into filled areas
rng=np.random.default_rng(7)
stars=np.zeros((H,W),np.float32)
n=int(W*H*0.0009)
ys=rng.integers(0,H,n); xs=rng.integers(0,W,n); stars[ys,xs]=rng.uniform(0.2,0.9,n)
stars=cv2.GaussianBlur(stars,(0,0),0.6)*3
f=np.clip(f.astype(np.float32)*0.82+stars[...,None]*120,0,255)
alpha=cv2.GaussianBlur(cv2.dilate(M,np.ones((9,9),np.uint8)).astype(np.float32)/255,(0,0),12)[...,None]
alpha=np.maximum(alpha,M[...,None]/255*0.0)
out=im.astype(np.float32)*(1-alpha)+f*alpha
cv2.imwrite(sys.argv[2],out.astype(np.uint8))
