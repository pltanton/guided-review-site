const still = matchMedia("(prefers-reduced-motion: reduce)").matches;
const options = { fit: "width", idleTimeLimit: 2, theme: "gr", poster: "npt:0:6", preload: true, controls: false };
const inView = (e) => e.intersectionRatio >= 0.9 || e.intersectionRect.height >= 0.9 * e.rootBounds.height;
const whenSeen = (el, on) => new IntersectionObserver(([e]) => on(inView(e)), { threshold: [0, 0.5, 0.9, 1] }).observe(el);
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
  figure.firstElementChild.prepend(button);
  button.after(time);
  figure.append(seek);

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
  screen.addEventListener("click", toggle);
  seek.addEventListener("click", async (e) => {
    const box = seek.getBoundingClientRect();
    await player.seek(((e.clientX - box.left) / box.width) * (await player.getDuration()));
    draw();
  });
  return state;
}

for (const figure of document.querySelectorAll(".hero .term, .row .term")) {
  const s = attach(figure, { loop: true });
  if (!still) whenSeen(figure, (seen) => (seen && !s.held ? s.player.play() : s.player.pause()));
}

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
const [caption, screen] = dialog.querySelector("figure").children;
let big;
dialog.addEventListener("click", (e) => e.target === dialog && dialog.close());
dialog.addEventListener("close", () => {
  big.player.dispose();
  dialog.querySelectorAll(".pp, .time, .seek").forEach((el) => el.remove());
});
for (const figure of document.querySelectorAll(".zoom"))
  figure.firstElementChild.addEventListener("click", (e) => {
    if (e.target.closest("button")) return;
    caption.textContent = figure.closest(".row").querySelector("h2").textContent;
    screen.replaceChildren();
    screen.dataset.cast = figure.querySelector("[data-cast]").dataset.cast;
    dialog.showModal();
    big = attach(dialog.querySelector("figure"), { fit: "both", autoPlay: true, loop: true });
  });
