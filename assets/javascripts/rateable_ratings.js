(function() {
  'use strict';

  document.addEventListener('DOMContentLoaded', function() {
    initRateableRatings();
  });

  // Also handle Turbolinks/Turbo if present
  document.addEventListener('turbolinks:load', function() {
    initRateableRatings();
  });

  document.addEventListener('turbo:load', function() {
    initRateableRatings();
  });

  function initRateableRatings() {
    var widgets = document.querySelectorAll('.rateable-rating-widget');
    if (widgets.length > 0) {
      console.log('RateableRatings: Found ' + widgets.length + ' widgets');
    }

    widgets.forEach(function(widget) {
      // Skip if already initialized
      if (widget.dataset.initialized === 'true') {
        return;
      }
      widget.dataset.initialized = 'true';

      var canRate = widget.dataset.canRate === 'true';
      if (!canRate) {
        widget.classList.add('rateable-readonly');
        // Add click listener to log why it's read-only
        var stars = widget.querySelectorAll('.rateable-star');
        stars.forEach(function(star) {
          star.addEventListener('click', function() {
            console.log('RateableRatings: Widget is read-only. Check permissions or self-rating settings.');
          });
        });
        return;
      }

      var stars = widget.querySelectorAll('.rateable-star');
      var rateableType = widget.dataset.rateableType;
      var rateableId = widget.dataset.rateableId;

      stars.forEach(function(star) {
        // Hover effects
        star.addEventListener('mouseenter', function() {
          var score = parseInt(star.dataset.score, 10);
          highlightStars(widget, score);
        });

        star.addEventListener('mouseleave', function() {
          var myScore = parseInt(widget.dataset.myScore, 10) || 0;
          highlightStars(widget, myScore);
        });

        // Click to rate
        star.addEventListener('click', function() {
          var score = parseInt(star.dataset.score, 10);
          if (isNaN(score)) {
            console.error('RateableRatings: Invalid score');
            return;
          }
          submitRating(widget, rateableType, rateableId, score);
        });
      });
    });
  }

  function highlightStars(widget, upToScore) {
    var stars = widget.querySelectorAll('.rateable-star');
    stars.forEach(function(star) {
      var starScore = parseInt(star.dataset.score, 10);
      if (starScore <= upToScore) {
        star.classList.add('highlighted');
        star.innerHTML = '&#9733;';
      } else {
        star.classList.remove('highlighted');
        star.innerHTML = '&#9734;';
      }
    });
  }

  function submitRating(widget, rateableType, rateableId, score) {
    widget.classList.add('rateable-loading');

    var csrfToken = getCSRFToken();

    fetch('/rateable_ratings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({
        rateable_type: rateableType,
        rateable_id: rateableId,
        score: score
      })
    })
    .then(function(response) {
      if (!response.ok) {
        return response.json().then(function(data) {
          throw new Error(data.error || 'Failed to save rating');
        });
      }
      return response.json();
    })
    .then(function(data) {
      // Update widget with new data
      widget.dataset.myScore = data.my_score;
      updateWidgetDisplay(widget, data);
      widget.classList.remove('rateable-loading');
    })
    .catch(function(error) {
      console.error('Rating error:', error);
      alert(error.message || 'Failed to save rating');
      widget.classList.remove('rateable-loading');
      // Restore original state
      var myScore = parseInt(widget.dataset.myScore, 10) || 0;
      highlightStars(widget, myScore);
    });
  }

  function updateWidgetDisplay(widget, data) {
    var avgSpan = widget.querySelector('.rateable-avg');
    var countSpan = widget.querySelector('.rateable-count');

    if (avgSpan) {
      avgSpan.textContent = data.avg > 0 ? data.avg.toFixed(1) : '-';
    }
    if (countSpan) {
      countSpan.textContent = data.count;
    }

    // Update stars display
    var stars = widget.querySelectorAll('.rateable-star');
    stars.forEach(function(star) {
      var starScore = parseInt(star.dataset.score, 10);
      star.classList.remove('filled', 'avg-filled', 'highlighted');

      if (starScore <= data.my_score) {
        star.classList.add('filled');
        star.innerHTML = '&#9733;';
      } else if (starScore <= Math.round(data.avg)) {
        star.classList.add('avg-filled');
        star.innerHTML = '&#9733;';
      } else {
        star.innerHTML = '&#9734;';
      }
    });
  }

  function getCSRFToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  }
})();
