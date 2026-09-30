const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

function createPlayers() {
  const players = new Map();
  for (const el of document.querySelectorAll(".player[data-cast]")) {
    const player = AsciinemaPlayer.create(el.dataset.cast, el, {
      fit: "width",
      loop: true,
      idleTimeLimit: 2,
      theme: "gr",
      poster: "npt:0:6",
      preload: true,
      controls: "auto",
      terminalFontFamily: "'JetBrains Mono', ui-monospace, Menlo, monospace",
      terminalLineHeight: 1.25,
    });
    players.set(el, player);
  }
  if (reduceMotion) return;

  const seen = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        const player = players.get(e.target);
        if (e.isIntersecting) player.play();
        else player.pause();
      }
    },
    { threshold: 0.45 },
  );
  for (const el of players.keys()) seen.observe(el);
}

document.fonts.load("14px 'JetBrains Mono'").finally(createPlayers);

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
