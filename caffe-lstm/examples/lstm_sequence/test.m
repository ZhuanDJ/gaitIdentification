% X = csvread('gait-dataset/w021day1-raw.csv', 1, 0);
% X2 = csvread('gait-dataset/w022day1-raw.csv', 1, 0);

% [~,a] = parseData(1,1);
% [~,b] = parseData(2,1);
% [~,c] = parseData(18,1);
% [~,d] = parseData(20,1);
% X{1} = structToArray(a);
% X{2} = structToArray(b);
% X{3} = structToArray(c);
% X{4} = structToArray(d);

figure;

n = 20000;
interval = 200;

t = 1;
while t < n
    
    for x=1:2
        for y=1:2
            plotIdx = (x-1)*2 + y;
            subplot(2,2,plotIdx);
            accel = zeros(interval, 3);
            for i=0:(interval-1)
                accel(i+1, :) = X{plotIdx}(t+i, 2:4);
            end
            plot(...
            1:interval, accel(:, 1), 'r-', ...
            1:interval, accel(:, 2), 'g-', ...
            1:interval, accel(:, 3), 'b-');
            ylim([-20 20]);

        end
    end

    t = t + 1;
    pause(0.001);
end


