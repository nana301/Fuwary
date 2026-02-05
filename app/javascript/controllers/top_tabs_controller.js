document.addEventListener("DOMContentLoaded", () => {
  const tabs = document.querySelectorAll(".tab-btn");
  const contents = document.querySelectorAll(".tab-content");

  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      const target = tab.dataset.tab;

      tabs.forEach(t => t.classList.remove("tab-active"));
      tab.classList.add("tab-active");

      contents.forEach(c => c.classList.add("hidden"));
      document.getElementById(`tab-${target}`).classList.remove("hidden");
    });
  });
});
