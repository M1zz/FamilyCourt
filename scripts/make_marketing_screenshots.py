#!/usr/bin/env python3
"""App Store 마케팅 스크린샷: 원본 캡처 + 헤드라인 → HTML → 헤드리스 Chrome (appstore-assets 스킬).

사용법: python3 scripts/make_marketing_screenshots.py [언어 ...]   (없으면 전부)

자리
  docs/screenshots/raw/<언어>/NN-….png          원본 캡처 (1320x2868, 스토어에 안 올라감)
  docs/screenshots/marketing/<로케일>/NN-….png   제출본 1242x2688 — DeployBar 가 이 폴더를 그대로 올린다
슬라이드마다 배치(layout)를 달리한다: hero-bleed · left-text · text-bottom · flat-rotate · dark
"""
import subprocess, sys, pathlib, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 아이폰 제출 규격

# 앱 언어 → App Store 로케일
STORE = {"ko": "ko", "en": "en-US", "en-GB": "en-GB", "ja": "ja", "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant", "ru": "ru", "es": "es-ES", "de": "de-DE", "fr": "fr-FR"}

# 파일 · 배치 · 언어별 (헤드라인, 보조 문장)
SHOTS = [
    ("01-home.png",    "hero-bleed",  {"ko": ("억울하면<br>재판을 열어요", "아이도 부모도 직접 소송을 걸 수 있어요"),
        "en": ("Feeling wronged?<br>Open court", "Kids and parents can both file a case"),
        "en-GB": ("Feeling wronged?<br>Open court", "Children and parents can both file a case"),
        "ja": ("「ずるい！」は<br>裁判で解決", "子どもも親も、訴えを起こせます"),
        "zh-Hans": ("觉得委屈？<br>开庭解决", "孩子和家长都可以提起诉讼"),
        "zh-Hant": ("覺得委屈？<br>開庭解決", "孩子和家長都可以提起訴訟"),
        "ru": ("Обидно?<br>Открывайте суд", "Подать иск могут и дети, и родители"),
        "es": ("¿Algo injusto?<br>Abrid sesión", "Niños y padres pueden presentar un caso"),
        "de": ("Ungerecht behandelt?<br>Gericht eröffnen", "Kinder und Eltern können Klage einreichen"),
        "fr": ("Une injustice ?<br>Ouvrez l’audience", "Enfants et parents peuvent porter plainte")}),
    ("02-filing.png",  "left-text",   {"ko": ("고소장은<br>내가 직접 써요", "피고도 판사도 접수하는 사람이 골라요"),
        "en": ("File the complaint<br>yourself", "The filer picks the defendant and the judge"),
        "en-GB": ("File the complaint<br>yourself", "The filer picks the defendant and the judge"),
        "ja": ("訴状は<br>自分で書こう", "被告も裁判官も、提出する人が選びます"),
        "zh-Hans": ("起诉状<br>自己来写", "被告和法官由提交的人选"),
        "zh-Hant": ("起訴狀<br>自己來寫", "被告和法官由提出的人選"),
        "ru": ("Иск пишете<br>сами", "Ответчика и судью выбирает подавший иск"),
        "es": ("Presenta la demanda<br>tú mismo", "Quien presenta elige acusado y juez"),
        "de": ("Die Klage<br>schreibst du selbst", "Wer klagt, wählt Angeklagten und Richter"),
        "fr": ("Rédigez la plainte<br>vous-même", "Celui qui dépose choisit défendeur et juge")}),
    ("03-trial.png",   "text-bottom", {"ko": ("대사를 따라 하면<br>진짜 재판이 돼요", "누가 무슨 말을 할 차례인지 알려줘요"),
        "en": ("Follow the script<br>for a real trial", "Every line tells you whose turn it is"),
        "en-GB": ("Follow the script<br>for a real trial", "Every line tells you whose turn it is"),
        "ja": ("せりふをまねして<br>本格的な裁判に", "誰が何を言う番か、教えてくれます"),
        "zh-Hans": ("照着台词念<br>就是真庭审", "每句台词都提示轮到谁"),
        "zh-Hant": ("照著台詞念<br>就是真庭審", "每句台詞都提示輪到誰"),
        "ru": ("По репликам —<br>как в настоящем суде", "Каждая реплика подскажет, чья очередь"),
        "es": ("Sigue el guion<br>y será un juicio real", "Cada línea indica a quién le toca"),
        "de": ("Mit dem Skript wird<br>es ein echter Prozess", "Jede Zeile sagt, wer an der Reihe ist"),
        "fr": ("Suivez le texte :<br>un vrai procès", "Chaque réplique indique qui doit parler")}),
    ("04-verdict.png", "flat-rotate", {"ko": ("판결은 벌보다<br>약속으로", "지킬 약속을 정하고 끝까지 체크해요"),
        "en": ("Verdicts end with<br>a promise", "Set a promise and check it off to the end"),
        "en-GB": ("Verdicts end with<br>a promise", "Set a promise and tick it off to the end"),
        "ja": ("判決は罰より<br>約束で", "守る約束を決めて、最後までチェック"),
        "zh-Hans": ("判决以承诺<br>代替惩罚", "定下承诺，勾选到完成"),
        "zh-Hant": ("判決以承諾<br>代替處罰", "訂下承諾，勾選到完成"),
        "ru": ("Приговор —<br>это обещание", "Дайте обещание и отмечайте его до конца"),
        "es": ("Los veredictos acaban<br>en una promesa", "Fija una promesa y márcala hasta el final"),
        "de": ("Urteile enden<br>mit einem Versprechen", "Versprechen festlegen und bis zum Ende abhaken"),
        "fr": ("Le verdict se finit<br>par une promesse", "Fixez une promesse et cochez-la jusqu’au bout")}),
    ("05-laws.png",    "dark",        {"ko": ("우리 집 법은<br>가족이 함께 정해요", "조문을 더하고 고칠 수 있어요"),
        "en": ("Write your family<br>laws together", "Add and edit articles any time"),
        "en-GB": ("Write your family<br>laws together", "Add and edit articles any time"),
        "ja": ("わが家の法律は<br>家族で決めよう", "条文はいつでも追加・修正できます"),
        "zh-Hans": ("家里的法律<br>全家一起定", "条文随时可以增加和修改"),
        "zh-Hant": ("家裡的法律<br>全家一起訂", "條文隨時可以新增和修改"),
        "ru": ("Законы семьи<br>пишем вместе", "Статьи можно добавлять и менять"),
        "es": ("Escribid juntos<br>las leyes de casa", "Añade y edita artículos cuando quieras"),
        "de": ("Familiengesetze<br>gemeinsam schreiben", "Artikel jederzeit ergänzen und ändern"),
        "fr": ("Écrivez ensemble<br>les lois de la famille", "Ajoutez et modifiez les articles à tout moment")}),
    ("06-learn.png",   "left-text",   {"ko": ("판사, 원고, 변호인<br>모두 배워요", "역할과 재판 순서를 쉬운 말로 알려줘요"),
        "en": ("Judge, plaintiff, counsel:<br>learn every role", "Roles and trial steps in plain words"),
        "en-GB": ("Judge, plaintiff, counsel:<br>learn every role", "Roles and trial steps in plain words"),
        "ja": ("裁判官、原告、弁護人<br>全部学べます", "役割と裁判の流れをやさしい言葉で"),
        "zh-Hans": ("法官、原告、辩护人<br>全都学会", "用浅显的话讲解角色和流程"),
        "zh-Hant": ("法官、原告、辯護人<br>全都學會", "用淺顯的話講解角色和流程"),
        "ru": ("Судья, истец, защитник:<br>узнайте все роли", "Роли и этапы суда простыми словами"),
        "es": ("Juez, demandante, abogado:<br>aprende cada papel", "Papeles y pasos del juicio, en palabras sencillas"),
        "de": ("Richter, Kläger, Verteidiger:<br>alle Rollen lernen", "Rollen und Ablauf in einfachen Worten"),
        "fr": ("Juge, demandeur, avocat :<br>apprenez chaque rôle", "Rôles et étapes du procès en mots simples")}),
]

# 색은 헤더·검색 결과 그림(make_creative_assets.py)과 맞춘다.
THEME = dict(bg="linear-gradient(160deg,#FFF6E4 0%,#FDE7BC 60%,#F8D48E 100%)", ink="#4A2C12", sub="#8A6440",
             dark_bg="#3A2414", dark_ink="#FFF3DC", dark_sub="#D9B98A", frame="#2a1d12", rim="#6b4a2c",
             glow="rgba(248,212,142,.30)")

BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:%(bg)s; font-family:-apple-system, "Apple SD Gothic Neo", "Hiragino Sans", sans-serif; position:relative; }
.headline { font-size:96px; font-weight:800; color:%(ink)s; letter-spacing:-2px; line-height:1.22; text-wrap:balance; }
.sub { font-size:50px; font-weight:500; color:%(sub)s; letter-spacing:-1px; line-height:1.35; text-wrap:balance; }
:lang(ko) .headline, :lang(ko) .sub { word-break:keep-all; }
.phone { background:%(frame)s; border-radius:112px; border:3px solid %(rim)s; padding:24px;
  box-shadow: 60px 90px 120px rgba(0,0,0,.24), 20px 30px 50px rgba(0,0,0,.14); }
.phone img { width:100%%; display:block; border-radius:89px; }
"""

LAYOUTS = {
    "hero-bleed": """
.headline { text-align:center; margin-top:270px; padding:0 70px; }
.sub { text-align:center; margin-top:46px; padding:0 80px; }
.wrap { display:flex; justify-content:center; margin-top:130px; }
.phone { width:970px; }
""",
    "left-text": """
.headline { text-align:left; margin:280px 90px 0 105px; }
.sub { text-align:left; margin:44px 90px 0 109px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:290px; top:960px; }
.phone { width:815px; transform:rotateY(16deg) rotateX(2deg); }
""",
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:160px; }
.phone { width:850px; transform:rotateY(-10deg) rotateX(2deg); }
.headline { text-align:center; margin-top:110px; padding:0 70px; }
.sub { text-align:center; margin-top:44px; padding:0 80px; }
""",
    "flat-rotate": """
.headline { text-align:center; margin-top:250px; padding:0 70px; }
.sub { text-align:center; margin-top:46px; padding:0 80px; }
.wrap { position:absolute; left:115px; top:980px; }
.phone { width:980px; transform:rotate(-6deg); }
""",
    "dark": """
body { background:%(dark_bg)s; }
.headline { color:%(dark_ink)s; text-align:center; margin-top:270px; padding:0 70px; }
.sub { color:%(dark_sub)s; text-align:center; margin-top:46px; padding:0 80px; }
.wrap { display:flex; justify-content:center; margin-top:130px; }
.phone { width:900px; border-color:#48484e; box-shadow: 0 0 160px %(glow)s, 40px 70px 110px rgba(0,0,0,.55); }
""",
}

TEXT_FIRST = '<div class="headline">{h}</div><div class="sub">{s}</div><div class="wrap"><div class="phone"><img src="{img}"></div></div>'
PHONE_FIRST = '<div class="wrap"><div class="phone"><img src="{img}"></div></div><div class="headline">{h}</div><div class="sub">{s}</div>'
HTML = '<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>{css}</style></head><body>{body}</body></html>'


def raw_for(lang, fname):
    p = RAW / lang / fname
    return p if p.exists() else RAW / fname


def main(langs):
    tmp = pathlib.Path(tempfile.mkdtemp())
    vals = dict(THEME, W=W, H=H)
    for lang in langs:
        out_dir = OUT / STORE[lang]
        out_dir.mkdir(parents=True, exist_ok=True)
        for fname, layout, texts in SHOTS:
            h, s = texts[lang]
            src = raw_for(lang, fname)
            assert src.exists(), f"원본 없음: {src}"
            tpl = PHONE_FIRST if layout == "text-bottom" else TEXT_FIRST
            css = BASE_CSS % vals + LAYOUTS[layout] % vals if "%(" in LAYOUTS[layout] else BASE_CSS % vals + LAYOUTS[layout]
            html = tmp / f"{lang}-{fname}.html"
            html.write_text(HTML.format(lang=lang, css=css, body=tpl.format(h=h, s=s, img=src.as_uri())), encoding="utf-8")
            out = out_dir / fname
            # Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
            for _ in range(3):
                try:
                    r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out}", f"--window-size={W},{H}",
                                        "--force-device-scale-factor=1", "--hide-scrollbars", "--disable-gpu",
                                        "--virtual-time-budget=3000", "--allow-file-access-from-files",
                                        html.as_uri()], capture_output=True, timeout=90)
                except subprocess.TimeoutExpired:
                    continue
                if r.returncode == 0 and out.exists():
                    break
            else:
                raise SystemExit(f"Chrome 이 그리지 못했다: {out}")
            print("rendered", out.relative_to(ROOT))


if __name__ == "__main__":
    main(sys.argv[1:] or list(STORE))
