// Player hit
$(document).on('click', '#hit-form', function() {
  $.ajax({
    type: 'POST',
    url: '/game/player/hit'
  }).done(function(msg) {
    $('#game').replaceWith(msg);
  });
  return false
});

// Player stand
$(document).on('click', '#stand-form', function() {
  $.ajax({
    type: 'POST',
    url: '/game/player/stand'
  }).done(function(msg) {
    $('#game').replaceWith(msg);
  });
  return false
});

// Dealer hit
$(document).on('click', '#dealer-hit-form', function() {
  $.ajax({
    type: 'POST',
    url: '/game/dealer/hit'
  }).done(function(msg) {
    $('#game').replaceWith(msg);
  });
  return false
});