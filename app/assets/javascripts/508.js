// $(document).ready(function(){

// 	$("#siteSelectionModal #last_index").on("focus", function(){
//     $("button.close").focus();
//   });

// 	$("#siteSelectionModal input[type=radio]").on("change", function() {
// 		$("input[name=site_type]").forEach(function(radio){
// 			radio.attr("tabindex", 0);
// 		});
// 		$(this).attr("tabindex", 3);
// 	});

//   $("button.close").focusout(function(){
//       console.log("yoyo", $("#site_tree").attr("tabindex"))
//       siteTreeTabIndexTo(3);
//       $("button#select-site-in-modal").focus();
//   });

//   $("#siteSelectionModal input[type=radio]").on("change", function(){
//   	console.log('radio button changed');
//   	siteTreeTabIndexTo(3);
//   })

//   function siteTreeTabIndexTo(value) {
//   	var siteTree = $("#site_tree");
//   	siteTree.attr("tabindex", value);
//   }
// });