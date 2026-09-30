const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

const playerOptions = {
  fit: "width",
  idleTimeLimit: 2,
  theme: "gr",
  poster: "npt:0:6",
  preload: true,
  controls: false,
  terminalFontFamily: "'JetBrains Mono', ui-monospace, Menlo, monospace",
};

const visibility = new IntersectionObserver(
  (entries) => {
    for (const e of entries) e.target.onVisible?.(e.isIntersecting);
  },
  { threshold: 0.4 },
);

function createLooping() {
  for (const el of document.querySelectorAll(".player[data-cast]")) {
    const player = AsciinemaPlayer.create(el.dataset.cast, el, { ...playerOptions, loop: true });
    if (reduceMotion) continue;
    el.onVisible = (seen) => (seen ? player.play() : player.pause());
    visibility.observe(el);
  }
}

function createCarousel(root) {
  const tabs = [...root.querySelectorAll(".tab")];
  const mount = root.querySelector("[data-carousel-player]");
  const bar = root.querySelector("[data-carousel-bar]");
  let current = 0;
  let player = null;
  let visible = false;
  let frame = 0;

  const progress = () => {
    cancelAnimationFrame(frame);
    const fill = tabs[current].querySelector(".tab-progress i");
    const tick = async () => {
      if (!player) return;
      const [at, total] = await Promise.all([player.getCurrentTime(), player.getDuration()]);
      if (total) fill.style.width = `${Math.min(100, (at / total) * 100)}%`;
      frame = requestAnimationFrame(tick);
    };
    tick();
  };

  const show = (i, play) => {
    current = (i + tabs.length) % tabs.length;
    tabs.forEach((t, n) => {
      t.setAttribute("aria-selected", String(n === current));
      t.querySelector(".tab-progress i").style.width = "0";
    });
    bar.textContent = tabs[current].querySelector(".tab-title").textContent;
    cancelAnimationFrame(frame);
    player?.dispose();
    mount.replaceChildren();
    player = AsciinemaPlayer.create(tabs[current].dataset.cast, mount, {
      ...playerOptions,
      autoPlay: play,
    });
    player.addEventListener("play", progress);
    player.addEventListener("pause", () => cancelAnimationFrame(frame));
    player.addEventListener("ended", () => {
      cancelAnimationFrame(frame);
      if (visible) show(current + 1, true);
    });
  };

  tabs.forEach((tab, i) => tab.addEventListener("click", () => show(i, !reduceMotion)));
  show(0, false);
  if (reduceMotion) return;
  mount.onVisible = (seen) => {
    visible = seen;
    if (seen) player.play();
    else player.pause();
  };
  visibility.observe(mount);
}

document.fonts.load("14px 'JetBrains Mono'").finally(() => {
  createLooping();
  document.querySelectorAll("[data-carousel]").forEach(createCarousel);
});

for (const button of document.querySelectorAll("[data-copy]")) {
  button.addEventListener("click", async () => {
    const text = document.getElementById(button.dataset.copy).textContent;
    try {
      await navigator.clipboard.writeText(text);
      button.textContent = "Copied";
      button.classList.add("done");
      setTimeout(() => {
        button.textContent = "Copy";
        button.classList.remove("done");
      }, 1600);
    } catch {
      button.textContent = "Select it";
    }
  });
}
