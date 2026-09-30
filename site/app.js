const still = matchMedia("(prefers-reduced-motion: reduce)").matches;
const options = { fit: "width", idleTimeLimit: 2, theme: "gr", poster: "npt:0:6", preload: true, controls: false };
const mount = (el, extra) => AsciinemaPlayer.create(el.dataset.cast, el, { ...options, ...extra });
const whenSeen = (el, on) => new IntersectionObserver(([e]) => on(e.isIntersecting), { threshold: 0.4 }).observe(el);

for (const el of document.querySelectorAll(".row [data-cast], .hero [data-cast]")) {
  const player = mount(el, { loop: true });
  if (!still) whenSeen(el, (seen) => (seen ? player.play() : player.pause()));
}

const deep = document.querySelector(".deep");
const radios = [...deep.querySelectorAll("input")];
const slides = [...deep.querySelectorAll(".slides [data-cast]")].map((el) => mount(el));
let seen = false;
const current = () => radios.findIndex((r) => r.checked);
const play = async () => {
  const player = slides[current()];
  deep.classList.remove("playing");
  await player.seek(0);
  deep.style.setProperty("--dur", `${await player.getDuration()}s`);
  void deep.offsetWidth;
  deep.classList.add("playing");
  player.play();
};
slides.forEach((player, i) => player.addEventListener("ended", () => {
  if (seen && i === current()) radios[(i + 1) % radios.length].click();
}));
radios.forEach((r, i) => r.addEventListener("change", () => {
  slides.forEach((p, n) => n !== i && p.pause());
  if (!still) play();
}));
if (!still) whenSeen(deep.querySelector(".slides"), (s) => {
  seen = s;
  deep.classList.toggle("paused", !s);
  if (s && !deep.classList.contains("playing")) play();
  else slides[current()][s ? "play" : "pause"]();
});

const dialog = document.querySelector("dialog");
let big;
dialog.addEventListener("click", (e) => e.target === dialog && dialog.close());
dialog.addEventListener("close", () => big.dispose());
for (const figure of document.querySelectorAll(".zoom")) figure.addEventListener("click", () => {
  const [caption, screen] = dialog.querySelector("figure").children;
  caption.textContent = figure.closest(".row").querySelector("h2").textContent;
  screen.replaceChildren();
  screen.dataset.cast = figure.querySelector("[data-cast]").dataset.cast;
  dialog.showModal();
  big = mount(screen, { autoPlay: true, loop: true, controls: true });
});
