// The boring mode switch: swaps the sprite cards for the plain list and remembers the choice.
// The class is also set before first paint by the script in _layouts/base.html.
(function () {
  var root = document.documentElement;
  var toggle = document.querySelector('.boring-toggle');
  if (!toggle) return;

  function sync() {
    toggle.setAttribute('aria-checked', root.classList.contains('boring') ? 'true' : 'false');
  }

  toggle.addEventListener('click', function () {
    var on = !root.classList.contains('boring');
    root.classList.toggle('boring', on);
    try { localStorage.setItem('boring', on ? '1' : '0'); } catch (e) {}
    sync();
  });

  sync();
})();
