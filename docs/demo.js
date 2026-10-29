// 억울해요 웹 체험: 민사 재판 한 번을 앱의 순서대로 짧게 열어 본다.
// 규칙은 앱과 같다 — 단계마다 차례와 대사(Store.trialSteps), 이야기 시간 120초 · 마지막 한마디 60초,
// 의사봉 소리는 Sound.swift 의 합성값(170Hz→55Hz 로 떨어지는 짧은 타격 3번), 타이머 끝은 880Hz 삐 3번.
// 어휘 난이도(쉬운 말 · 기본 · 법정 용어)를 바꾸면 역할 이름과 단계 이름이 앱처럼 바로 바뀐다(Vocab).
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const TIMER = [0, 120, 120, 60, 0], GAVEL = [true, false, false, false, true];
  let level = 1, step = 0, left = 0, ticking = null, verdict = -1;

  root.innerHTML = `
    <div class="ct-stage">
      <div class="ct-levels" role="group" aria-label="${T.levelLabel}">
        ${T.levels.map((l, i) => `<button type="button" data-level="${i}">${l}</button>`).join("")}
      </div>
      <ol class="ct-dots" aria-hidden="true">${TIMER.map(() => "<li></li>").join("")}</ol>
      <p class="ct-role"></p>
      <h3 class="ct-title" aria-live="polite"></h3>
      <p class="ct-script"></p>
    </div>
    <div class="ct-panel">
      <div class="ct-timer">
        <output class="ct-clock" aria-live="off"></output>
        <button type="button" class="ct-btn" data-act="timer"></button>
      </div>
      <div class="ct-verdicts" role="group"></div>
      <button type="button" class="ct-gavel" data-act="gavel" aria-label="${T.gavel}">
        <span aria-hidden="true">🔨</span><span>${T.gavel}</span>
      </button>
      <p class="ct-after muted small" aria-live="polite"></p>
      <div class="ct-nav">
        <button type="button" class="ct-btn" data-act="prev">${T.prev}</button>
        <button type="button" class="ct-btn primary" data-act="next">${T.next}</button>
      </div>
      <p class="muted small">${T.note}</p>
    </div>`;

  const $ = s => root.querySelector(s);
  const word = k => T[k][level];
  const fill = s => s.replace(/\{(judge|accuser|accused)\}/g, (_, k) => word(k));
  const mmss = s => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

  function render() {
    const s = T.steps[step];
    root.querySelectorAll("[data-level]").forEach(b => b.setAttribute("aria-pressed", String(+b.dataset.level === level)));
    root.querySelectorAll(".ct-dots li").forEach((d, i) => d.className = i < step ? "done" : i === step ? "on" : "");
    $(".ct-role").textContent = fill(s.role);
    $(".ct-title").textContent = `${step + 1}. ${fill(s.title[level])}`;
    $(".ct-script").textContent = fill(s.text);
    $(".ct-timer").hidden = !TIMER[step];
    $(".ct-clock").textContent = mmss(left);
    $(".ct-clock").classList.toggle("warn", ticking && left <= 10);
    $("[data-act=timer]").textContent = ticking ? T.pause : T.start;
    const last = step === T.steps.length - 1;
    $(".ct-verdicts").hidden = !last;
    $(".ct-verdicts").innerHTML = T.verdicts.map((v, i) =>
      `<button type="button" data-verdict="${i}" aria-pressed="${i === verdict}">${v[level]}</button>`).join("");
    $(".ct-gavel").hidden = !GAVEL[step];
    $(".ct-after").textContent = last && verdict >= 0 ? T.after : "";
    $("[data-act=prev]").disabled = step === 0;
    $("[data-act=next]").textContent = last ? T.again : T.next;
  }

  // 소리: 앱의 버퍼 합성과 같은 모양을 Web Audio 로 만든다.
  let ctx;
  function tone(at, freq, endFreq, gain, decay, len) {
    const o = ctx.createOscillator(), g = ctx.createGain();
    o.frequency.setValueAtTime(freq, at);
    if (endFreq) o.frequency.exponentialRampToValueAtTime(endFreq, at + 0.09);
    g.gain.setValueAtTime(gain, at);
    g.gain.setTargetAtTime(0.0001, at, decay);
    o.connect(g).connect(ctx.destination);
    o.start(at); o.stop(at + len);
  }
  function sound(kind) {
    ctx = ctx || new (window.AudioContext || window.webkitAudioContext)();
    ctx.resume();
    const t = ctx.currentTime + 0.02;
    [0, kind === "gavel" ? 0.28 : 0.3, kind === "gavel" ? 0.56 : 0.6].forEach(d => kind === "gavel"
      ? tone(t + d, 170, 55, 0.9, 0.045, 0.15) : tone(t + d, 880, 0, 0.4, 0.08, 0.22));
  }

  function stopTimer() { clearInterval(ticking); ticking = null; }
  function go(n) { stopTimer(); step = n; left = TIMER[n]; verdict = -1; render(); }

  root.addEventListener("click", e => {
    const b = e.target.closest("button");
    if (!b) return;
    if (b.dataset.level) level = +b.dataset.level;
    else if (b.dataset.verdict) { verdict = +b.dataset.verdict; sound("gavel"); }
    else if (b.dataset.act === "gavel") sound("gavel");
    else if (b.dataset.act === "prev") return go(step - 1);
    else if (b.dataset.act === "next") return go(step === T.steps.length - 1 ? 0 : step + 1);
    else if (b.dataset.act === "timer") {
      if (ticking) stopTimer();
      else {
        if (!left) left = TIMER[step];
        ticking = setInterval(() => {
          left -= 1;
          if (left <= 0) { left = 0; stopTimer(); sound("beep"); }
          render();
        }, 1000);
      }
    }
    render();
    if (b.dataset.verdict) root.querySelector(`[data-verdict="${verdict}"]`).focus();
    if (b.dataset.level) root.querySelector(`[data-level="${level}"]`).focus();
  });

  go(0);
})();
