"""Converte os SVGs do gen_art em pixel art estilo GBA:
render pequeno -> alfa binário -> paleta limitada -> contorno colorido seletivo."""
import re, subprocess, sys, colorsys, io
from PIL import Image
sys.path.insert(0, "/home/claude/art")
import gen_art as G
G.PIXEL = True

LAST_PAL = []

def svg_png(svg, zoom, stroke_mul):
    global LAST_PAL
    LAST_PAL = sorted(set(re.findall(r'#[0-9a-fA-F]{6}', svg)))
    svg = re.sub(r'stroke-width="([\d.]+)"', lambda m: f'stroke-width="{float(m.group(1))*stroke_mul:.2f}"', svg)
    r = subprocess.run(["rsvg-convert", "-z", str(zoom)], input=svg.encode(), capture_output=True, check=True)
    return Image.open(io.BytesIO(r.stdout)).convert("RGBA")

def darker(c, amt=0.32):
    r,g,b = [v/255 for v in c[:3]]
    h,l,s = colorsys.rgb_to_hls(r,g,b)
    l = max(0.05, l-amt); s=min(1,s+0.1)
    r,g,b = colorsys.hls_to_rgb(h,l,s)
    return (round(r*255),round(g*255),round(b*255),255)

def nearest(c, pal):
    best=None; bd=1e9
    for p in pal:
        d=(c[0]-p[0])**2*0.3+(c[1]-p[1])**2*0.59+(c[2]-p[2])**2*0.11
        if d<bd: bd=d; best=p
    return best

def pixelize(img, ncol=16):
    pal=[tuple(int(h[i:i+2],16) for i in (1,3,5)) for h in LAST_PAL]
    w,h = img.size
    px = img.load()
    # alfa binário
    for y in range(h):
        for x in range(w):
            r,g,b,a = px[x,y]
            px[x,y] = (r,g,b,255) if a >= 110 else (0,0,0,0)
    # paleta limitada só com os pixels opacos
    out = Image.new("RGBA",(w,h),(0,0,0,0))
    op = out.load()
    cache={}
    for y in range(h):
        for x in range(w):
            if px[x,y][3]:
                c=px[x,y][:3]
                if c not in cache: cache[c]=nearest(c,pal)
                op[x,y] = cache[c]+(255,)
    # contorno: pixel opaco na borda vira versão escura da própria cor
    edge = []
    for y in range(h):
        for x in range(w):
            if not op[x,y][3]: continue
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx,ny=x+dx,y+dy
                if nx<0 or ny<0 or nx>=w or ny>=h or op[nx,ny][3]==0:
                    edge.append((x,y)); break
    for x,y in edge:
        c = op[x,y]
        lum = 0.3*c[0]+0.59*c[1]+0.11*c[2]
        if lum > 70:
            op[x,y] = darker(c, 0.38)
    # remove pixels soltos
    for y in range(h):
        for x in range(w):
            if op[x,y][3]:
                n = sum(1 for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=x+dx<w and 0<=y+dy<h and op[x+dx,y+dy][3])
                if n == 0: op[x,y]=(0,0,0,0)
    return out

if __name__ == "__main__":
    zoom, sm = float(sys.argv[1]), float(sys.argv[2])
    tiles=[]
    for sp in ["brasinha","gotinha","brotinho","faisquinho"]:
        for fm in ["baby","rookie","champ_luz","champ_sombra","alma_luz","alma_sombra"]:
            svg = G.monster(sp, fm).replace("SCARFSH","#b83038").replace("SCARF","#e8484f")
            tiles.append(pixelize(svg_png(svg, zoom, sm)))
    w,h = tiles[0].size
    S=3
    sheet = Image.new("RGBA",(w*6*S,h*4*S),(232,240,216,255))
    for i,t in enumerate(tiles):
        sheet.alpha_composite(t.resize((w*S,h*S),Image.NEAREST),((i%6)*w*S,(i//6)*h*S))
    sheet.save(sys.argv[3])
    print(w,h)
