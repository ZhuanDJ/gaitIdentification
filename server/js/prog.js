var prog_interval = 50;
var prog_endtime = 5000;
var prog_ing = false;
var imgwho_ani_ing = false;
var prog_time = 0;
var img_num = 3;
var img_title = Array("Unknown", "Jang", "Tom", "Ko");

function imgwho_ani() {
	if(imgwho_ani_ing == true) return;
	imgwho_ani_ing = true;
	$("#imgwho").animate({
                opacity: 0.2,
        }, 1000, function () {
        	$("#imgwho").animate({
                opacity: 0.9,
        	}, 1000, function () {
			imgwho_ani_ing = false;
			imgwho_ani();
		});
        });
}

function prog_f() {

	prog_time += prog_interval;

	$("#imgwho").show();
	$("#progtxt").text("Detecting... (" + Math.floor(prog_time/100)/10 +" seconds)");

	if(prog_ing == false || prog_time > prog_endtime) {
		$("#imgwho").hide();
		$("#progtxt").text("");
		$("#button1").attr("value", "Start");
		prog_ing = false;
		if(prog_time > prog_endtime) {
			show_result(0); //not found
		}
		return;
	}

	setTimeout("prog_f()", prog_interval);

}

function hide_imgs() {
	for(var i = 0; i <= img_num; i++)
		$("#img"+i).hide();
}

function show_result(idx) {
	//$("#img"+idx).show();
	$("#img"+idx).fadeIn("slow");
	$("#progtxt").html("Hello <b>"+img_title[idx]+"</b>!!!");
}

function found(idx) {
	prog_ing = false;
	setTimeout("show_result("+idx+")", prog_interval*2);
}

function init() {
	hide_imgs();
	prog_ing = false;
	prog_time = 0;
	$("#progtxt").text("");
}

function button1_click() {
	var btn1 = document.getElementById('button1');

	if(btn1.value=="processing...") return;
	btn1.value="processing...";

	prog_ing = true;
	prog_time = 0;
	hide_imgs();
	imgwho_ani();
	setTimeout("prog_f()", prog_interval);
}

function button2_click() {
	init();
}

function button3_click() {
	found( Math.floor((Math.random()*img_num)+1) );
}

