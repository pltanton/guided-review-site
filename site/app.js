const still = matchMedia("(prefers-reduced-motion: reduce)").matches;
const options = { fit: "width", idleTimeLimit: 2, theme: "gr", poster: "npt:0:6", preload: true, controls: false };
const inView = (e) => e.intersectionRatio >= 0.9 || e.intersectionRect.height >= 0.9 * e.rootBounds.height;
const whenSeen = (el, on) => new IntersectionObserver(([e]) => on(inView(e)), { threshold: [0, 0.5, 0.9, 1] }).observe(el);
document.querySelector(".theme").addEventListener("click", () => {
  const root = document.documentElement;
  const dark = root.dataset.theme ? root.dataset.theme === "dark" : matchMedia("(prefers-color-scheme: dark)").matches;
  root.dataset.theme = dark ? "light" : "dark";
  try { localStorage.theme = root.dataset.theme; } catch {}
});
const clock = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

function attach(figure, extra) {
  const screen = figure.querySelector("[data-cast]");
  const player = AsciinemaPlayer.create(screen.dataset.cast, screen, { ...options, ...extra });
  const button = document.createElement("button");
  const time = document.createElement("span");
  const seek = document.createElement("div");
  button.className = "pp";
  time.className = "time";
  seek.className = "seek";
  seek.append(document.createElement("i"));
  const caption = figure.firstElementChild;
  caption.prepend(button);
  caption.querySelector("span").after(time);
  caption.append(seek);

  const state = { player, playing: false, held: false };
  let frame = 0;
  const draw = async () => {
    const [at, total] = await Promise.all([player.getCurrentTime(), player.getDuration()]);
    if (total) {
      seek.firstChild.style.width = `${(at / total) * 100}%`;
      time.textContent = `${clock(at)} / ${clock(total)}`;
    }
    if (state.playing) frame = requestAnimationFrame(draw);
  };
  const set = (playing) => {
    state.playing = playing;
    button.textContent = playing ? "❚❚" : "▶";
    button.setAttribute("aria-label", playing ? "Pause" : "Play");
    cancelAnimationFrame(frame);
    draw();
  };
  player.addEventListener("play", () => set(true));
  player.addEventListener("pause", () => set(false));
  player.addEventListener("ended", () => set(false));
  set(false);

  const toggle = (e) => {
    e.stopPropagation();
    state.held = state.playing;
    state.playing ? player.pause() : player.play();
  };
  button.addEventListener("click", toggle);
  screen.addEventListener("mousedown", () => {
    if (!state.playing) return;
    state.held = true;
    player.pause();
  });
  seek.addEventListener("click", async (e) => {
    const box = seek.getBoundingClientRect();
    await player.seek(((e.clientX - box.left) / box.width) * (await player.getDuration()));
    draw();
  });
  state.draw = draw;
  return state;
}

const hero = attach(document.querySelector(".hero .term"), { loop: true });
if (!still) whenSeen(document.querySelector(".hero .term"), (seen) => (seen && !hero.held ? hero.player.play() : hero.player.pause()));

const rows = [...document.querySelectorAll("#features .row")];
const shows = rows.map((row) => attach(row.querySelector(".term"), { loop: true }));
const sticky = matchMedia("(min-width: 981px)");
let active = -1;
const activate = (i) => {
  if (i === active) return;
  active = i;
  rows.forEach((row, n) => row.classList.toggle("on", n === i));
  shows.forEach((s, n) => (n === i && !still && !s.held ? s.player.play() : s.player.pause()));
};
const middle = new IntersectionObserver(
  (entries) => {
    if (!sticky.matches) return;
    for (const e of entries) if (e.isIntersecting) activate(rows.indexOf(e.target.parentElement));
  },
  { rootMargin: "-45% 0px -45% 0px" },
);
rows.forEach((row) => middle.observe(row.firstElementChild));
const leave = new IntersectionObserver(([e]) => {
  if (!sticky.matches) return;
  if (!e.isIntersecting) activate(-1);
  else if (active < 0) activate(e.boundingClientRect.top > 0 ? 0 : rows.length - 1);
});
leave.observe(document.querySelector("#features"));
shows.forEach((s, i) => {
  if (!still) whenSeen(rows[i].querySelector(".term"), (seen) => {
    if (sticky.matches) return;
    seen && !s.held ? s.player.play() : s.player.pause();
  });
});

const deep = document.querySelector(".deep");
const radios = [...deep.querySelectorAll("input")];
const slides = [...deep.querySelectorAll(".slides .term")].map((f) => attach(f));
let seen = false;
const current = () => radios.findIndex((r) => r.checked);
const play = async () => {
  const { player } = slides[current()];
  deep.classList.remove("playing");
  await player.seek(0);
  deep.style.setProperty("--dur", `${await player.getDuration()}s`);
  void deep.offsetWidth;
  deep.classList.add("playing");
  player.play();
};
slides.forEach(({ player }, i) => {
  player.addEventListener("play", () => deep.classList.remove("paused"));
  player.addEventListener("pause", () => deep.classList.add("paused"));
  player.addEventListener("ended", () => seen && i === current() && radios[(i + 1) % radios.length].click());
});
radios.forEach((r, i) =>
  r.addEventListener("change", () => {
    slides.forEach((s, n) => n !== i && s.player.pause());
    if (!still) play();
  }),
);
if (!still)
  whenSeen(deep.querySelector(".slides"), (s) => {
    seen = s;
    const slide = slides[current()];
    if (s && !deep.classList.contains("playing")) play();
    else if (!s || !slide.held) slide.player[s ? "play" : "pause"]();
  });

const dialog = document.querySelector("dialog");
const [dialogCaption, dialogScreen] = dialog.querySelector("figure").children;
const collapse = Object.assign(document.createElement("button"), { className: "act", textContent: "⤡", title: "Back (esc)" });
collapse.addEventListener("click", () => dialog.close());
let big;
let scrubbing = false;
dialog.addEventListener("click", (e) => e.target === dialog && dialog.close());
dialog.addEventListener("close", () => {
  big.player.dispose();
  dialog.querySelectorAll(".pp, .time, .seek").forEach((el) => el.remove());
});
dialog.addEventListener(
  "wheel",
  async (e) => {
    e.preventDefault();
    if (scrubbing || !big) return;
    scrubbing = true;
    const { player } = big;
    const [at, total] = await Promise.all([player.getCurrentTime(), player.getDuration()]);
    await player.seek(Math.min(total, Math.max(0, at + e.deltaY / 100)));
    big.draw();
    scrubbing = false;
  },
  { passive: false },
);
for (const figure of document.querySelectorAll(".zoom")) {
  const expand = Object.assign(document.createElement("button"), { className: "act", textContent: "⤢", title: "Larger" });
  figure.firstElementChild.append(expand);
  expand.addEventListener("click", () => {
    dialogCaption.firstElementChild.textContent = `${figure.closest(".row").querySelector("h2").textContent} · scroll to scrub`;
    dialogCaption.append(collapse);
    dialogScreen.replaceChildren();
    dialogScreen.dataset.cast = figure.querySelector("[data-cast]").dataset.cast;
    dialog.showModal();
    big = attach(dialog.querySelector("figure"), { autoPlay: true, loop: true });
  });
}

fetch("https://api.github.com/repos/pltanton/guided-review")
  .then((r) => (r.ok ? r.json() : null))
  .then((repo) => {
    const n = repo?.stargazers_count;
    if (!n) return;
    const count = document.querySelector(".star .count");
    count.textContent = n >= 1000 ? `${(n / 1000).toFixed(1)}k` : n;
    count.hidden = false;
  })
  .catch(() => {});
