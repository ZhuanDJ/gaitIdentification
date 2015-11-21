fclose all;
socket = tcpip('127.0.0.1', 3001, 'NetworkRole', 'client');
set(socket, 'TIMEOUT', 10);

fopen(socket);

caffe.reset_all;
protoTxt = 'prototxt/lstm_gait_person_demo_matlab.prototxt';
caffeModel1 = caffe.Net(protoTxt, 'snapshot/gait_21_iter_100000.caffemodel', 'test');
caffeModel2 = caffe.Net(protoTxt, 'snapshot/gait_22_iter_100000.caffemodel', 'test');
caffeModel3 = caffe.Net(protoTxt, 'snapshot/gait_23_iter_100000.caffemodel', 'test');


MSG_BUFFSIZE = 28;
windowSize = 100; % modify lstm_gait_person_demo_matlab.prototxt
while 1
    msg = fread(socket, MSG_BUFFSIZE);
    msg = char(msg);
    fprintf('%s\n', msg);
    
    if ~isempty(msg)
        sensorData = csvread(sprintf('../../../server/%s', msg));
%         processedData = preprocessing(sensorData, windowSize);
        processedData = sensorData((200-windowSize+1):200, :);
        
        fprintf('processedDataSize: %.0f\n', size(processedData, 1));
        if size(processedData, 1) >= windowSize
            
            result1 = evalFunc(caffeModel1, processedData);
            result2 = evalFunc(caffeModel2, processedData);
            result3 = evalFunc(caffeModel3, processedData);
        else
            result1 = 0;
            result2 = 0;
            result3 = 0;
        end
%         result2 = 0;
%         result3 = 1;
        
        % send result to node server
        result = strcat(num2str(result1), ',', num2str(result2), ',', num2str(result3) );
        fwrite(socket, result);
    end
end

