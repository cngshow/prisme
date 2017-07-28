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

  function setTabOrderForAppDeployModal(e) {
    //elements outside of modal is untabbable
    $('a, button, select').each(function(){
       var $this = $(this);
       if(!$this.closest('#app_deploy_modal').length){
           $this.attr('tabIndex', '-1');
       };
    });

     //box label
    $('ul[role="tablist"] li[aria-disabled="false"] a').attr('tabIndex', 2);
    // radio button
    var activeRadio = $('input[type="radio"]');
    activeRadio.attr('tabIndex', 3)

    //previous & next button
    var nextTabIndex = activeRadio.attr('tabIndex');
    $("#app_deployer_form ul[role='menu'] a").each(function(i){
        $(this).attr('tabIndex', ++nextTabIndex)
    });

    $('a[href="#next"]').on('keydown', function(e){                
        var e = getEvent(e);
        var keyCode = getKeyCode(e);

        if (keyCode == 13) { //enter
            setTimeout(function(){
                setHeaderTabIndex(2);
            }, 100);
        } else {
            e.preventDefault();
        };
        
        if (keyCode == 9 && !e.shiftKey) {
            $('[tabindex=1]').focus();
        };

        if (keyCode == 9 && e.shiftKey) {
            $('input[type="radio"]:checked, a[tabindex="4"]').focus();
        };
    });

    $('a[href="#previous"]').on('keydown', function(e){
      var keyCode = getKeyCode(e);
      if (keyCode == 13) {
        setTimeout(function(){
          setHeaderTabIndex(2);
        }, 100);
      };
    });

    $('[tabindex=1]').on('keydown', function(e){
        var e = getEvent(e);
        var keyCode = getKeyCode(e);
        if (e.keyCode == 13) {
          return;
        };
        e.preventDefault();
        if (keyCode == 9 && !e.shiftKey) {
            $('[tabindex=2]').focus();
        };
        if (keyCode == 9 && e.shiftKey) {
            $('a[href="#next"]').focus();
        };
    });

    $('[tabindex=2]').focus();
  }; //setTabOrderForAppDeployModal

  function setHeaderTabIndex(i) { 
    $('ul[role="tablist"] li[aria-selected="false"] a').attr("tabIndex", "-1");
    $('ul[role="tablist"] li[aria-selected="true"] a').attr("tabIndex", i);

    $('.close').attr('tabIndex', 1);

    $('[tabindex="2"]').on('keydown', function(e){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (keyCode == 9 && e.shiftKey) { 
        e.preventDefault();
        $("[tabindex='1']").focus();
      };
    }); 

    $('a[href="#finish"]').on('keydown', function(){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (keyCode == 9 && !e.shiftKey) {
        e.preventDefault();
        $("[tabindex='1']").focus();
      };
    });

    $('[tabindex="1"]').on('keydown', function(){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (keyCode == 9 && e.shiftKey) {
        $('a[href="#finish"]').focus();
      };
    });
  };

  function getEvent(e){
    return (e || window.event);
  };
  function getKeyCode(e) {
    return (e.keyCode ? e.keyCode : e.which);
  }; 




