#!/usr/bin/env python3
"""스토어 스크린샷 원본 캡처 — 언어마다 그 언어 화면과 그 언어 예시 기록으로 찍는다.

사용법: python3 scripts/capture_raw_screenshots.py <시뮬레이터 UDID> <앱 경로(.app, Debug)> [언어 ...] [--scenes caseTop,filing]
        (언어가 없으면 ko 빼고 전부, --scenes 가 없으면 모든 장면)

  1. 예시 기록(scripts/screenshot_demo.json + Localizable.xcstrings 의 법원 이름·기본 법·사건번호 꼴)을
     앱 Documents/familycourt.json 에 넣고
  2. 디버그 전용 실행 인자 `-FCScene <장면>` 으로 그 화면을 바로 연 뒤 (ContentView.swift ScreenshotScene)
  3. simctl 로 1320x2868 원본을 찍는다.

자리
  docs/screenshots/raw/<언어>/01-home.png … 06-learn.png       마케팅 스크린샷 원본 (make_marketing_screenshots.py)
  docs/screenshots/raw/creative/<언어>/01-home.png · 02-verdict.png   헤더·검색 결과 원본 (make_creative_assets.py)

⚠️ 시뮬레이터 하나만 쓴다. 다른 작업이 쓰는 시뮬레이터(예: DeployBar 의 iPhone Duo)는 쓰지 않는다.
"""
import json, pathlib, re, shutil, subprocess, sys, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
BUNDLE = "com.family.familycourt"
CATALOG = json.loads((ROOT / "FamilyCourt" / "Localizable.xcstrings").read_text(encoding="utf-8"))["strings"]
DEMO = json.loads((ROOT / "scripts" / "screenshot_demo.json").read_text(encoding="utf-8"))

# 앱 언어 → (AppleLanguages, AppleLocale)
LOCALE = {"ko": "ko_KR", "en": "en_US", "en-GB": "en_GB", "ja": "ja_JP", "zh-Hans": "zh_CN", "zh-Hant": "zh_TW",
          "ru": "ru_RU", "es": "es_ES", "de": "de_DE", "fr": "fr_FR", "it": "it_IT", "pt-BR": "pt_BR", "th": "th_TH",
          "vi": "vi_VN", "cs": "cs_CZ", "da": "da_DK", "el": "el_GR", "fi": "fi_FI", "id": "id_ID", "nb": "nb_NO",
          "nl": "nl_NL", "pl": "pl_PL", "sv": "sv_SE", "tr": "tr_TR"}

SHOTS = [  # (파일, 장면)
    ("01-home.png", "home"), ("02-filing.png", "filing"), ("03-trial.png", "trial"),
    ("04-verdict.png", "verdict"), ("05-laws.png", "laws"), ("06-learn.png", "learn"),
]


def tr(key, lang):
    """카탈로그에서 그 언어 번역(없으면 한국어 원문)."""
    e = CATALOG.get(key, {})
    if lang == "ko":
        return key
    return e.get("localizations", {}).get(lang, {}).get("stringUnit", {}).get("value", key)


def fmt(pattern, *args):
    """%lld / %@ / %1$lld 꼴을 채운다."""
    seq = iter(args)
    def rep(m):
        return str(args[int(m.group(1)) - 1]) if m.group(1) else str(next(seq))
    return re.sub(r"%(?:(\d+)\$)?(?:lld|@)", rep, pattern)


def demo_state(lang):
    d = DEMO[lang]
    year = 2569 if lang == "th" else 2026   # 태국은 불기 — 앱도 Calendar.current 의 해를 쓴다
    civil = lambda n: fmt(tr("%lld민사%lld호", lang), year, n)
    criminal = lambda n: fmt(tr("%lld형사%lld호", lang), year, n)
    laws = [("l1", "존중", "가족은 서로에게 나쁜 말이나 상처 주는 말을 하지 않는다."),
            ("l2", "내 물건과 남의 물건", "다른 사람의 물건은 주인에게 허락을 받고 사용한다."),
            ("l3", "정리정돈", "자기가 어지른 것은 자기가 정리한다."),
            ("l4", "약속", "한 번 한 약속은 지킨다. 지키기 어려울 때는 미리 말한다."),
            ("l5", "화해", "재판이 끝나면 결과와 상관없이 서로 안아주고 화해한다.")]
    no_roles = dict(lawyer="", clerk="")
    return {
        "courtName": tr("우리 집 가정법원", lang),
        "vocabLevel": "standard", "seq": 4, "caseSeq": 4,
        "members": [{"id": "m1", "name": d["dad"], "emoji": "👨"}, {"id": "m2", "name": d["mom"], "emoji": "👩"},
                    {"id": "m3", "name": d["son"], "emoji": "👦"}, {"id": "m4", "name": d["daughter"], "emoji": "👧"}],
        "laws": [{"id": i, "title": tr(t, lang), "text": tr(x, lang)} for i, t, x in laws]
                + [{"id": "l6", "title": d["law6_title"], "text": d["law6_text"]}],
        "cases": [
            {"id": "c4", "caseNo": criminal(3), "type": "criminal", "title": d["trial_title"], "desc": d["trial_desc"],
             "want": d["trial_want"], "lawIds": ["l6", "l4"], "status": "재판 대기", "createdAt": d["date_oct5"],
             "roles": dict(judge="m1", accuser="m4", accused="m3", **no_roles)},
            {"id": "c3", "caseNo": civil(4), "type": "civil", "title": d["open2_title"], "desc": "", "want": "",
             "lawIds": ["l2"], "status": "재판 대기", "createdAt": d["date_oct5"],
             "roles": dict(judge="m2", accuser="m4", accused="m3", **no_roles)},
            {"id": "c2", "caseNo": civil(2), "type": "civil", "title": d["verdict_title"], "desc": d["verdict_desc"],
             "want": d["verdict_want"], "lawIds": ["l2"], "status": "판결완료", "createdAt": d["date_oct3"],
             "roles": dict(judge="m1", accuser="m3", accused="m4", lawyer="m2", clerk=""),
             "verdict": {"result": "화해 권고", "text": d["verdict_text"], "penalty": d["verdict_penalty"],
                         "penaltyDone": False, "decidedAt": d["date_oct5"], "judge": "m1"}},
            {"id": "c1", "caseNo": civil(1), "type": "civil", "title": d["done2_title"], "desc": "", "want": "",
             "lawIds": ["l1"], "status": "판결완료", "createdAt": d["date_oct3"],
             "roles": dict(judge="m2", accuser="m4", accused="m3", **no_roles),
             "verdict": {"result": "원고 승소", "text": "", "penalty": "", "penaltyDone": True,
                         "decidedAt": d["date_oct3"], "judge": "m2"}},
        ],
    }


def sh(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True)


def capture(udid, lang, only=None):
    d = DEMO[lang]
    container = pathlib.Path(sh("xcrun", "simctl", "get_app_container", udid, BUNDLE, "data").stdout.strip())
    out = RAW / lang
    out.mkdir(parents=True, exist_ok=True)
    state = json.dumps(demo_state(lang), ensure_ascii=False)
    for fname, scene in SHOTS + [("caseTop", "caseTop")]:
        if only and scene not in only:
            continue
        sh("xcrun", "simctl", "terminate", udid, BUNDLE, check=False)
        (container / "Documents").mkdir(parents=True, exist_ok=True)
        (container / "Documents" / "familycourt.json").write_text(state, encoding="utf-8")
        args = ["xcrun", "simctl", "launch", udid, BUNDLE, "-AppleLanguages", f"({lang})", "-AppleLocale",
                LOCALE[lang], "-hasSeenOnboarding", "YES", "-FCScene", scene]
        if scene in ("trial",):
            args += ["-FCCase", "c4"]
        if scene in ("verdict", "caseTop"):
            args += ["-FCCase", "c2"]
        if scene == "filing":
            args += ["-FCTitle", d["filing_title"], "-FCDesc", d["filing_desc"], "-FCAccuser", "m3",
                     "-FCAccused", "m4", "-FCJudge", "m2", "-FCLaw", "l4"]
        sh(*args)
        time.sleep(6)   # 화면이 다 그려질 때까지 (부하가 있으면 늦다)
        target = (RAW / "creative" / lang / "02-verdict.png") if scene == "caseTop" else out / fname
        target.parent.mkdir(parents=True, exist_ok=True)
        sh("xcrun", "simctl", "io", udid, "screenshot", str(target))
        print("captured", target.relative_to(ROOT))
    if not only or "home" in only:
        shutil.copy(out / "01-home.png", RAW / "creative" / lang / "01-home.png")
    sh("xcrun", "simctl", "terminate", udid, BUNDLE, check=False)


def main():
    udid, app = sys.argv[1], sys.argv[2]
    rest = sys.argv[3:]
    only = None
    if "--scenes" in rest:   # 일부 장면만 다시 찍기: --scenes caseTop,filing
        i = rest.index("--scenes")
        only = set(rest[i + 1].split(","))
        rest = rest[:i] + rest[i + 2:]
    langs = rest or [l for l in DEMO if l != "ko"]
    sh("xcrun", "simctl", "bootstatus", udid, "-b")
    sh("xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged",
       "--batteryLevel", "100", "--cellularBars", "4", "--wifiBars", "3", "--dataNetwork", "wifi")
    sh("xcrun", "simctl", "install", udid, app)
    for lang in langs:
        capture(udid, lang, only)


if __name__ == "__main__":
    main()
