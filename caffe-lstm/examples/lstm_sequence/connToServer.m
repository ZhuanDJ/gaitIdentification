fclose all;
socket = tcpip('127.0.0.1', 3001, 'NetworkRole', 'client');
set(socket, 'TIMEOUT', 10);

fopen(socket);

caffe.reset_all;
protoTxt = 'lstm_gait_person_matlab.prototxt';
caffeModel1 = caffe.Net(protoTxt, 'snapshot/gait_21_iter_60000.caffemodel', 'test');
caffeModel2 = caffe.Net(protoTxt, 'snapshot/gait_22_iter_20000.caffemodel', 'test');
caffeModel3 = caffe.Net(protoTxt, 'snapshot/gait_23_iter_60000.caffemodel', 'test');

MSG_BUFFSIZE = 28;
while 1
    msg = fread(socket, MSG_BUFFSIZE);
    msg = char(msg);
    fprintf('%s\n', msg);
    
    if ~isempty(msg)
        sensorData = csvread(sprintf('../../../server/%s', msg));
        
        result1 = evalFunc(caffeModel1, sensorData);
        result2 = evalFunc(caffeModel2, sensorData);
        result3 = evalFunc(caffeModel3, sensorData);
        %         result = 'UNAUTHORIZED';
        
        % send result to node server
        result = strcat(num2str(result1), ',', num2str(result2), ',', num2str(result3) );
        fwrite(socket, result);
    end
end

