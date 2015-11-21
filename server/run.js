var app = require('http').createServer(handler),
    url = require('url'),
    path = require('path'),
    io = require('socket.io').listen(app),
    fs = require('fs'),
    mime = require('mime');

var port = process.env.PORT || 3000;
app.listen(port);
console.log("Listening on " + port);

function handler (req, res) { //http server handler 
  var uri = url.parse(req.url).pathname; 
  var filename = path.join(process.cwd(), uri);
  var user_agent = req.headers['user-agent'];

  if (uri == "/"){
    fs.readFile(__dirname + "/index.htm", function(err, data){
      if (err){
        res.writeHead(200);
        return res.end("ERROR");
      }
      res.writeHead(200, {'Content-Type' : mime.lookup(__dirname + "/index.htm")});
      res.end(data);
    });
  }
  else {
    fs.readFile(__dirname + uri, function(err, data){
      if (err){
        res.writeHead(200);
        return res.end("ERROR");
      }
      //write header
      var filestat = fs.statSync(filename);
      var filemime = mime.lookup(filename);
      res.writeHead(200, {
        'Content-Type' : filemime,
        'Content-Length' : filestat.size
      });
      res.end(data);
    });
  }
}

var webSocket;
var appSocket;
io.sockets.on('connection', function (socket) {
  console.log('user connected!');
  socket.emit('hello', "hello world!");

  socket.on('sensor', function(msg) {
    //console.log('sensor : ' + msg);
    if (webSocket) {
      webSocket.emit('sensor', msg);
    }
    appSocket = socket;
  });
  socket.on('bye', function(msg) {
    console.log('bye...');
  });
  socket.on('web', function() {
    console.log('Web is connected');
    webSocket = socket;
  });
  socket.on('auth', function(data) {
    var filepath = 'sensordata/' + Math.floor(Date.now()) + '.csv';
    // write...
    var csvstr = "";  
    for (var i = 0 ; i < data.length ; i++){
      csvstr += data[i].timestamp + ',' + data[i].accel[0] + ', ' + data[i].accel[1] + ', ' + data[i].accel[2] + '\n';
    }
    fs.writeFile(filepath, csvstr, function(err) {
      if (err) throw err;
      // send
      if (matlabSocket) {
        matlabSocket.write(filepath);
      }
    });
  });
});


//tcp socket to connect to matlab client

var tcpserver=require('net').createServer();
var tcpport=3001;
var matlabSocket;
tcpserver.on('listening',function(){
  console.log('TCP/IP Server is listening on port', tcpport);
});
tcpserver.on('connection',function(socket) {
  matlabSocket = socket;

  console.log('TCP/IP Server has a new connection');
  
  matlabSocket.on('data', function(data){
    var result = data.toString().split(",");
    if (webSocket) {
      webSocket.emit('authResult', result);
    }
    console.log('TCP/IP Server Received:', data.toString());

    // send to app
    if (result.indexOf('1') != -1) {
      if (appSocket) {
        console.log('auth success!');
        appSocket.emit('authSuccess', 'success!');
      }
    }
  });
  matlabSocket.on('end',function(data){
    console.log('TCP/IP Server is now closing');
  });
});
tcpserver.on('close',function(){
  console.log('TCP/IP Server is now closed');
});
tcpserver.on('error',function(){
  console.log('Error occured:',err.message);
});
tcpserver.listen(tcpport);


