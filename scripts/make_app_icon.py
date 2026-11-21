#!/usr/bin/env python3
"""앱 아이콘 생성: 판사봉 캐릭터 SVG → 1024 PNG 세 벌(기본 · 다크 · 틴트) + 소개 페이지 아이콘.

사용법:
    python3 scripts/make_app_icon.py

그림은 이 파일의 art() 가 전부다. 고친 뒤 다시 돌리면 AppIcon.appiconset 과 docs/icon.png 가 바뀐다.
SVG → PNG 는 macOS 기본 그리기(scripts/render_svg.swift)로 한다. 따로 깔 것이 없다.
"""
import subprocess, pathlib, tempfile
here=pathlib.Path(__file__).parent

def art(mode):
    gray = mode=="tinted"
    def c(col, g):  # color or gray
        return g if gray else col
    bg = ""
    if mode=="light":
        bg = '<rect width="1024" height="1024" fill="url(#bg)"/><circle cx="512" cy="470" r="430" fill="url(#glow)"/>'
    elif mode=="tinted":
        bg = '<rect width="1024" height="1024" fill="url(#bgT)"/>'
    spark = c("#FFF6DC","#FFFFFF") if mode!="dark" else "#FFE9B8"
    line = c("#C9772B","#BDBDBD") if mode=="light" else c("#F2B45C","#BDBDBD")
    shadow = '<ellipse cx="350" cy="884" rx="236" ry="30" fill="#B5651D" opacity=".28"/>' if mode=="light" else ''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE3A3"/><stop offset="1" stop-color="#F5A63B"/></linearGradient>
<linearGradient id="bgT" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E2E2E"/><stop offset="1" stop-color="#121212"/></linearGradient>
<radialGradient id="glow"><stop offset="0" stop-color="#FFF4CF" stop-opacity=".75"/><stop offset="1" stop-color="#FFF4CF" stop-opacity="0"/></radialGradient>
<linearGradient id="head" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c('#F0A55A','#F2F2F2')}"/><stop offset="1" stop-color="{c('#D27D33','#BEBEBE')}"/></linearGradient>
<linearGradient id="handle" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{c('#C4813F','#D0D0D0')}"/><stop offset="1" stop-color="{c('#9C5B26','#9A9A9A')}"/></linearGradient>
<linearGradient id="block" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c('#C47435','#B0B0B0')}"/><stop offset="1" stop-color="{c('#A45A24','#8A8A8A')}"/></linearGradient>
<clipPath id="hc"><rect x="212" y="250" width="600" height="290" rx="92"/></clipPath>
</defs>
{bg}
{shadow}
<!-- 받침 -->
<rect x="150" y="790" width="400" height="92" rx="40" fill="url(#block)"/>
<rect x="150" y="790" width="400" height="34" rx="17" fill="{c('#D98A48','#CFCFCF')}"/>
<!-- 탕! -->
<g stroke="{line}" stroke-width="20" stroke-linecap="round" fill="none">
<path d="M150 700 L98 668"/><path d="M118 760 L62 752"/><path d="M204 664 L176 612"/>
</g>
<!-- 판사봉 -->
<g transform="translate(62 14) rotate(-24 512 512)">
<rect x="464" y="470" width="96" height="440" rx="48" fill="url(#handle)"/>
<rect x="484" y="560" width="20" height="300" rx="10" fill="#FFFFFF" opacity=".28"/>
<rect x="212" y="250" width="600" height="290" rx="92" fill="url(#head)"/>
<g clip-path="url(#hc)">
<rect x="212" y="250" width="92" height="290" fill="{c('#B9652A','#8F8F8F')}"/>
<rect x="720" y="250" width="92" height="290" fill="{c('#B9652A','#8F8F8F')}"/>
<rect x="304" y="250" width="22" height="290" fill="{c('#FFD27A','#FFFFFF')}"/>
<rect x="698" y="250" width="22" height="290" fill="{c('#FFD27A','#FFFFFF')}"/>
<rect x="340" y="272" width="344" height="40" rx="20" fill="#FFFFFF" opacity=".30"/>
</g>
<!-- 얼굴 -->
<ellipse cx="398" cy="436" rx="36" ry="24" fill="{c('#F58B6E','#9A9A9A')}" opacity=".85"/>
<ellipse cx="626" cy="436" rx="36" ry="24" fill="{c('#F58B6E','#9A9A9A')}" opacity=".85"/>
<ellipse cx="440" cy="388" rx="30" ry="34" fill="{c('#3F2415','#1C1C1C')}"/>
<ellipse cx="584" cy="388" rx="30" ry="34" fill="{c('#3F2415','#1C1C1C')}"/>
<circle cx="452" cy="374" r="11" fill="#FFFFFF"/><circle cx="596" cy="374" r="11" fill="#FFFFFF"/>
<path d="M474 438 Q512 478 550 438" stroke="{c('#3F2415','#1C1C1C')}" stroke-width="16" stroke-linecap="round" fill="none"/>
</g>
<!-- 반짝 -->
<g fill="{spark}">
<path transform="translate(40 -44)" d="M820 150 Q830 208 888 218 Q830 228 820 286 Q810 228 752 218 Q810 208 820 150Z"/>
<path d="M180 190 Q186 226 222 232 Q186 238 180 274 Q174 238 138 232 Q174 226 180 190Z"/>
<circle cx="900" cy="420" r="15"/><circle cx="300" cy="120" r="11"/>
</g>
</svg>'''

OUT = here.parent / "FamilyCourt" / "Assets.xcassets" / "AppIcon.appiconset"
SITE = here.parent / "docs" / "icon.png"

with tempfile.TemporaryDirectory() as tmp:
    tmp = pathlib.Path(tmp)
    render = tmp / "render"
    subprocess.run(["swiftc", "-O", str(here / "render_svg.swift"), "-o", str(render)], check=True)
    # 기본 · 틴트는 알파 없이(App Store 는 알파 있는 아이콘을 받지 않는다), 다크는 배경을 비운다.
    for mode, name, alpha in [("light", "AppIcon", "opaque"), ("dark", "AppIcon-Dark", "alpha"), ("tinted", "AppIcon-Tinted", "opaque")]:
        svg = tmp / f"{name}.svg"
        svg.write_text(art(mode))
        subprocess.run([str(render), str(svg), str(OUT / f"{name}.png"), alpha], check=True)
        print("✅", OUT / f"{name}.png")
# 소개 페이지 아이콘
subprocess.run(["sips", "-z", "256", "256", str(OUT / "AppIcon.png"), "--out", str(SITE)], check=True, capture_output=True)
print("✅", SITE)
