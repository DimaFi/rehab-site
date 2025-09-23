document.addEventListener('DOMContentLoaded', function () {
  var buttons = document.querySelectorAll('.mini-btn');
  var topics = document.querySelectorAll('.mini-topic');
  if (!buttons.length || !topics.length) return;

  function activate(key) {
    buttons.forEach(function (b) {
      if (b.getAttribute('data-topic') === key) b.classList.add('active');
      else b.classList.remove('active');
    });
    topics.forEach(function (t) {
      if (t.getAttribute('data-topic') === key) t.classList.add('active');
      else t.classList.remove('active');
    });
  }

  buttons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      activate(btn.getAttribute('data-topic'));
    });
  });
});

