data1 = load('1.csv');
data2 = load('2.csv');
X = data1;

figure;
subplot(1, 1, 1);
plot(0, 0);
ylim([-20 20]);
hold on;

n = 20000;
interval = 500;

t = 1;
while t < n
%     figure(fig1);
    clf;
    accel = zeros(interval, 3);
    accel_mag = zeros(interval, 1);
    for i=0:(interval-1)
        accel(i+1, :) = [X(t+i,2)  X(t+i,3)  X(t+i,4)]';
        accel_mag(i+1) = X(t+i, 5);
    end
    plot(...
    1:interval, accel_mag, '-',...
    1:interval, accel(:, 1), '-', ...
    1:interval, accel(:, 2), '-', ...
    1:interval, accel(:, 3), '-');


    t = t + 1;
    pause(0.001);
end

hold off;