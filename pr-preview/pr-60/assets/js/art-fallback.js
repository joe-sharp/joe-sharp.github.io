// Show the GitHub copy of a card's art when Cloudinary cannot serve it.
// The art is an <image> inside the sprite's <defs>; every card is a <use> of those,
// so switching the original switches every card that shows it.
(function () {
  var grid = document.querySelector('.projects-cards');
  if (!grid) return;
  var fallbackBase = grid.getAttribute('data-art-fallback');
  if (!fallbackBase) return;

  var TIMEOUT = 6000; // ms before a slow Cloudinary response counts as down
  var images = Array.prototype.slice.call(document.querySelectorAll('defs image[href*="res.cloudinary.com"]'));

  images.forEach(function (image) {
    var url = image.getAttribute('href');
    var match = url.match(/([0-9a-f]{32})\.jpg$/);
    if (!match) return;

    var swap = function () { image.setAttribute('href', fallbackBase + match[1] + '.webp'); };

    // A separate probe, because SVG <image> elements don't reliably report errors.
    // The browser's cache serves the probe, so this costs no extra download.
    var probe = new Image();
    var timer = setTimeout(swap, TIMEOUT);
    probe.onload = function () { clearTimeout(timer); };
    probe.onerror = function () { clearTimeout(timer); swap(); };
    probe.src = url;
  });
})();
