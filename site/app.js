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
  const stack = root.querySelector("[data-carousel-stack]");
  const bar = root.querySelector("[data-carousel-bar]");
  const count = root.querySelector("[data-count]");
  let current = 0;
  let visible = false;
  let frame = 0;

  const slides = tabs.map((tab, i) => {
    const layer = document.createElement("div");
    layer.className = "layer";
    stack.append(layer);
    const player = AsciinemaPlayer.create(tab.dataset.cast, layer, playerOptions);
    player.addEventListener("ended", () => {
      if (i === current && visible) show(current + 1, true);
    });
    return { layer, player, fill: tab.querySelector(".tab-progress i") };
  });

  const track = () => {
    cancelAnimationFrame(frame);
    const { player, fill } = slides[current];
    const tick = async () => {
      const [at, total] = await Promise.all([player.getCurrentTime(), player.getDuration()]);
      if (total) fill.style.width = `${Math.min(100, (at / total) * 100)}%`;
      frame = requestAnimationFrame(tick);
    };
    tick();
  };

  const show = async (i, play) => {
    const next = (i + tabs.length) % tabs.length;
    if (next !== current) slides[current].player.pause();
    current = next;
    tabs.forEach((t, n) => t.setAttribute("aria-selected", String(n === next)));
    slides.forEach((s, n) => {
      s.fill.style.width = "0";
      s.layer.classList.toggle("on", n === next);
    });
    bar.textContent = tabs[next].querySelector(".tab-title").textContent;
    count.textContent = `${next + 1} / ${tabs.length}`;
    await slides[next].player.seek(0);
    if (play) {
      slides[next].player.play();
      track();
    }
  };

  tabs.forEach((tab, i) => tab.addEventListener("click", () => show(i, !reduceMotion)));
  root.querySelector("[data-prev]").addEventListener("click", () => show(current - 1, !reduceMotion));
  root.querySelector("[data-next]").addEventListener("click", () => show(current + 1, !reduceMotion));
  slides[0].layer.classList.add("on");
  if (reduceMotion) return;
  stack.onVisible = (seen) => {
    visible = seen;
    if (seen) {
      slides[current].player.play();
      track();
    } else {
      slides[current].player.pause();
      cancelAnimationFrame(frame);
    }
  };
  visibility.observe(stack);
}

function createLightbox() {
  const dialog = document.querySelector("[data-lightbox]");
  const mount = dialog.querySelector("[data-lightbox-player]");
  const bar = dialog.querySelector("[data-lightbox-bar]");
  let player = null;

  const close = () => dialog.close();
  dialog.addEventListener("close", () => {
    player?.dispose();
    player = null;
    mount.replaceChildren();
  });
  dialog.addEventListener("click", (e) => e.target === dialog && close());
  dialog.querySelector("[data-close]").addEventListener("click", close);

  for (const figure of document.querySelectorAll(".row .term")) {
    const cast = figure.querySelector(".player").dataset.cast;
    figure.addEventListener("click", () => {
      bar.textContent = figure.closest(".row").querySelector("h2").textContent;
      dialog.showModal();
      player = AsciinemaPlayer.create(cast, mount, {
        ...playerOptions,
        autoPlay: true,
        loop: true,
        controls: true,
      });
    });
  }
}

document.fonts.load("14px 'JetBrains Mono'").finally(() => {
  createLooping();
  document.querySelectorAll("[data-carousel]").forEach(createCarousel);
  createLightbox();
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
