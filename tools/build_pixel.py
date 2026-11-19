import sys, os
sys.argv=['x']
exec(open('/home/claude/pix/pixelize.py').read().split('if __name__')[0])
OUT=sys.argv_out if hasattr(sys,'argv_out') else '/home/claude/pix/out'
os.makedirs(OUT, exist_ok=True)
Z=0.24; SM=0.75
def go(name, svg, z=Z, sm=SM):
    pixelize(svg_png(svg, z, sm)).save(f"{OUT}/{name}.png")
for sp in G.SPECIES:
    for fm in G.FORMS:
        svg=G.monster(sp,fm)
        if fm.startswith("alma"):
            for i,t in enumerate(G.TAMERS):
                go(f"m_{sp}_{fm}_{i}", svg.replace("SCARFSH",G.shade(t[3],-0.15)).replace("SCARF",t[3]))
        else:
            go(f"m_{sp}_{fm}", svg)
for i in range(len(G.TAMERS)):
    go(f"t_{i}", G.tamer(i), 0.26, 0.7)
for el in G.ELEM:
    go(f"g_{el}", G.glitch(el,False))
    go(f"g_{el}_boss", G.glitch(el,True))
go("egg", G.egg(), 0.26, 0.7)
go("poop", G.poop(), 0.3, 0.7)
print("ok", len(os.listdir(OUT)))
