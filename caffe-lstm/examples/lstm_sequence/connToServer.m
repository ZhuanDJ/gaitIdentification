socket = tcpip('127.0.0.1', 3001, 'NetworkRole', 'client');
set(socket, 'TIMEOUT', 10);

fopen(socket);
protoTxt = 'lstm_gait_matlab.prototxt';
caffeModel = 'snapshot/gait_iter_20000.caffemodel';
caffeModel2 = 'snapshot/gait_iter_20000.caffemodel';


MSG_BUFFSIZE = 22;
while 1
    msg = fread(socket, MSG_BUFFSIZE);
    msg = char(msg);
    fprintf('%s\n', msg);

    if ~isempty(msg)
        %csvread(msg);

        %result = evalFunc(protoTxt, caffeModel, sensorData);
        result = 'UNAUTHORIZED';

        % send result to node server
        fwrite(socket, result);
    end
end

