// Deal the project cards face down into their grid slots, then flip them face up.
(function () {
  var grid = document.querySelector('.projects-cards');
  if (!grid) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if (!('IntersectionObserver' in window) || !Element.prototype.animate) return;

  var STAGGER = 130; // ms between cards in a batch
  var DURATION = 900;
  var cards = Array.prototype.slice.call(grid.querySelectorAll('.project-card'));

  // Deterministic pseudo-random so each card always spins the same way.
  function rand(n) {
    var x = Math.sin(n * 127.1 + 311.7) * 43758.5453;
    return x - Math.floor(x);
  }

  function burst(card) {
    var g = grid.getBoundingClientRect();
    var r = card.getBoundingClientRect();
    var x = r.left - g.left + r.width / 2;
    var y = r.top - g.top + r.height * 0.85;
    var index = cards.indexOf(card);
    var done = function (el) { return function () { el.remove(); }; };

    var ring = document.createElement('div');
    ring.className = 'deal-ring';
    ring.style.cssText = 'left:' + x + 'px;top:' + y + 'px';
    grid.appendChild(ring);
    ring.animate(
      [
        { transform: 'translate(-50%,-50%) scale(0.2)', opacity: 0.9 },
        { transform: 'translate(-50%,-50%) scale(1)', opacity: 0 }
      ],
      { duration: 650, easing: 'cubic-bezier(.1,.7,.3,1)' }
    ).finished.then(done(ring), done(ring));

    var hues = [42, 48, 8, 0, 55];
    var SPARKS = 6;
    for (var k = 0; k < SPARKS; k++) {
      var p = document.createElement('i');
      p.className = 'deal-spark';
      p.style.cssText = 'left:' + x + 'px;top:' + y + 'px;background:hsl(' + hues[k % hues.length] + ' 95% 60%)';
      grid.appendChild(p);
      var ang = (k / SPARKS) * Math.PI * 2 + rand(index * 20 + k);
      var dist = r.width * (0.3 + rand(k + index) * 0.5);
      p.animate(
        [
          { transform: 'translate(-50%,-50%) scale(1)', opacity: 1 },
          {
            transform: 'translate(calc(-50% + ' + Math.cos(ang) * dist + 'px), calc(-50% + ' + (Math.sin(ang) * dist * 0.6 - 10) + 'px)) scale(0)',
            opacity: 0
          }
        ],
        { duration: 500 + rand(k) * 300, easing: 'cubic-bezier(.1,.8,.3,1)' }
      ).finished.then(done(p), done(p));
    }
  }

  function deal(card) {
    var index = cards.indexOf(card);
    var g = grid.getBoundingClientRect();
    var r = card.getBoundingClientRect();
    // Fly up from just below the bottom edge of the screen, centred on the grid.
    var originX = g.left + g.width / 2;
    var originY = window.innerHeight + r.height / 2;
    var dx = originX - (r.left + r.width / 2);
    var dy = originY - (r.top + r.height / 2);
    var side = (rand(index) - 0.5) * 140;
    var spin = (rand(index + 3) > 0.5 ? 1 : -1) * (180 + rand(index) * 180);

    card.style.zIndex = 50;
    card.classList.add('is-dealt');

    var move = card.animate(
      [
        { offset: 0, transform: 'translate(' + dx + 'px,' + dy + 'px) rotate(' + -spin + 'deg) scale(0.35)', easing: 'cubic-bezier(.2,.8,.3,1)' },
        { offset: 0.55, transform: 'translate(' + (dx * 0.3 + side) + 'px,' + (dy * 0.3 - 70) + 'px) rotate(' + -spin * 0.2 + 'deg) scale(1.3)', easing: 'cubic-bezier(.5,0,.8,.4)' },
        { offset: 0.8, transform: 'translate(0,0) rotate(0deg) scale(0.93)', easing: 'ease-out' },
        { offset: 1, transform: 'translate(0,0) rotate(0deg) scale(1)' }
      ],
      { duration: DURATION }
    );
    card.classList.add('is-dealing');

    var land = function () {
      card.style.zIndex = '';
      card.classList.remove('is-dealing');
      burst(card);
      setTimeout(function () { card.classList.add('is-flipped'); }, 150);
    };
    move.finished.then(land, function () {});
  }

  // Hover tilt, once the card is face up.
  cards.forEach(function (card) {
    var tilt = card.querySelector('.project-card-tilt');
    card.addEventListener('pointermove', function (e) {
      if (e.pointerType !== 'mouse' || !card.classList.contains('is-flipped')) return;
      var r = card.getBoundingClientRect();
      var px = (e.clientX - r.left) / r.width - 0.5;
      var py = (e.clientY - r.top) / r.height - 0.5;
      tilt.style.transform = 'perspective(600px) rotateX(' + -py * 22 + 'deg) rotateY(' + px * 22 + 'deg) translateZ(12px)';
    });
    card.addEventListener('pointerleave', function () { tilt.style.transform = ''; });
  });

  function start() {
    var observer = new IntersectionObserver(function (entries) {
      var batch = entries
        .filter(function (e) { return e.isIntersecting; })
        .map(function (e) { return e.target; })
        .sort(function (a, b) { return cards.indexOf(a) - cards.indexOf(b); });
      batch.forEach(function (card, n) {
        observer.unobserve(card);
        setTimeout(function () { deal(card); }, n * STAGGER);
      });
    }, { threshold: 0.2 });
    cards.forEach(function (card) { observer.observe(card); });
  }

  grid.classList.add('deal-armed');

  // Don't fly in blank backs: wait for the back art to decode first.
  var img = new Image();
  img.src = getComputedStyle(grid).getPropertyValue('--card-back').trim().replace(/^url\(["']?|["']?\)$/g, '');
  var ready = img.decode ? img.decode() : Promise.resolve();
  ready.then(start, start);
})();
