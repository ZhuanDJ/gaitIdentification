var socket = io();

var windowSize = 200;
var sensorWindow = [];
var canvas;
var context;

Array.prototype.max = function() { return Math.max.apply(null, this); }
Array.prototype.min = function() { return Math.min.apply(null, this); }

function draw()
{
  var paddingLeft = 25;

  // clear
  context.clearRect(0, 0, canvas.width, canvas.height);

  // get min, max
  var windowMax = -1000;
  var windowMin = 1000;
  for (var i = 0 ; i < sensorWindow.length ; i++) {
    for (var k = 0 ; k < 3 ; k++) {
      windowMax = Math.max(sensorWindow[i].accel[k], windowMax);
      windowMin = Math.min(sensorWindow[i].accel[k], windowMin);
    }
  }
  windowMax = Math.max(windowMax, 10);
  windowMin = Math.min(windowMin, -10);

  function accelToY(val){
    var ratio = (val - windowMin) / (windowMax - windowMin);
    return (1 - ratio) * canvas.height;
  }

  context.beginPath();
  context.moveTo(paddingLeft, 0);
  context.lineTo(paddingLeft, canvas.height);
  context.lineTo(canvas.width, canvas.height);
  context.strokeStyle = '#000000';
  context.stroke();
  for (var yVal = -48 ; yVal <= 48 ; yVal += 3) {
    var y = accelToY(yVal);
    context.font = "16px Arial";
    context.textAlign = 'right';
    context.fillText(yVal, 15, y+6);
  }

  if (sensorWindow.length == 0) return;

  // draw plot
  var color = ['#ff0000', '#00ff00', '#0000ff'];
  for (var k = 0 ; k < 3 ; k++) {
    context.beginPath();
    context.moveTo(paddingLeft, accelToY(sensorWindow[0].accel[k]));
    for (var i = 0 ; i < sensorWindow.length; i++) {
      var item = sensorWindow[i];
      var x = canvas.width / (windowSize  - 20)* i + paddingLeft;
      var y = accelToY(item.accel[k]);
      context.lineTo(x, y);
    }

    context.strokeStyle = color[k];
    context.stroke();
  }
}

$(function(){
  canvas = document.getElementById('canvas');
  context = canvas.getContext('2d');

  socket.emit('web', "it's me!");
  socket.on('sensor', function(msg) {
    var data = msg.split("\t");
    var obj = {
      timestamp: data[0],
      accel: [data[1], data[2], data[3]]
    };
    sensorWindow.push(obj);
    if (sensorWindow.length > 200) {
      sensorWindow.shift();
    }

    draw();
  });
  draw();
  socket.on('authResult', function(data) {
    if (data[0] == 1) {
      found(1);
    } else if (data[1] == 1) {
      found(2);
    } else if (data[2] == 1) {
      found(3);
    }
  });
});


setInterval(function() {
  var size = 200;
  if (prog_ing) {
    if (sensorWindow.length >= size) {
      var data = [];
      for (var i = sensorWindow.length - size ; i < sensorWindow.length; i++) {
        data.push(sensorWindow[i]);
      }
      socket.emit('auth', data);
    }
  }
}, 200);
