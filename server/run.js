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
io.sockets.on('connection', function (socket) {
  console.log('user connected!');
  socket.emit('hello', "hello world!");

  socket.on('sensor', function(msg) {
    console.log('sensor : ' + msg);
    webSocket.emit('sensor', msg);
  });
  socket.on('bye', function(msg) {
    console.log('bye...');
  });
  socket.on('web', function() {
    console.log('Web is connected');
    webSocket = socket;
  });
});

