
function setModalTabs(modalSelector, maxTabIndex) { 
  var maxTabIndex = maxTabIndex;
  var maxSelector = modalSelector + ' [tabindex=' + maxTabIndex + ']';
  var minSelector = modalSelector + ' [tabindex=1]';

  $(maxSelector).on('keydown', function(e) {
    if (e.keyCode == 9 && e.shiftKey == false) {
      e.preventDefault();
      $(minSelector).focus();
    };
  });

  $(minSelector).on('keydown', function(e) {
    if (e.keyCode == 9 && e.shiftKey == true) {
      e.preventDefault();
      $(maxSelector).focus();
    };
  });
};