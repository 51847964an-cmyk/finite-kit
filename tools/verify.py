"""独立验证 JSP-000690 (Erdos-Lovasz) 的 9 顶点 22 边显式构造 (Li 2025, arXiv:2512.24850)."""
from itertools import combinations
V = 9
E = [(1,2,3),(1,2,9),(1,3,8),(1,4,6),(1,4,8),(1,4,9),(1,5,7),(1,5,8),(1,5,9),(1,6,7),
     (2,3,6),(2,3,7),(2,4,9),(2,5,9),(2,6,7),(3,4,8),(3,5,8),(3,6,7),
     (4,6,8),(4,6,9),(5,7,8),(5,7,9)]
E0 = [tuple(x-1 for x in e) for e in E]          # 0-indexed

def mono(c, e):  # c: tuple of 9 bits
    return c[e[0]] == c[e[1]] == c[e[2]]
def two_colourable(edges):
    for m in range(1 << V):
        c = tuple((m >> i) & 1 for i in range(V))
        if not any(mono(c, e) for e in edges): return c
    return None
def three_colourable(edges):
    for m in range(pow(3, V)):
        c = []
        x = m
        for _ in range(V): c.append(x % 3); x //= 3
        if not any(c[e[0]] == c[e[1]] == c[e[2]] for e in edges): return tuple(c)
    return None

deg = [0]*V
for e in E0:
    for v in e: deg[v] += 1
print("edges:", len(E0), " min degree:", min(deg), " degrees:", deg)
print("3-uniform:", all(len(set(e)) == 3 for e in E0))
print("2-colourable:", two_colourable(E0) is not None, "(False => chi >= 3)")
psi = three_colourable(E0)
print("3-colouring exists:", psi is not None, psi)
# edge-critical
bad = [e for e in range(len(E0)) if two_colourable([f for j,f in enumerate(E0) if j != e]) is None]
print("edges whose removal keeps chi=3 (should be none):", bad)
# vertex-critical
badv = []
for v in range(V):
    rest = [e for e in E0 if v not in e]
    if two_colourable(rest) is None: badv.append(v+1)
print("vertices whose removal keeps chi=3 (should be none):", badv)
