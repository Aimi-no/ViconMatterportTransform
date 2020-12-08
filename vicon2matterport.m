vicon = load('D:/Documents/Work/MeshCollecting/Vicon_session_2020_12_02/markers_out.txt');
matterport = load('./matterport.txt');
pcMatterport = pcread('./B-315 (24th Feb 2020)/matterpak_yYyq78KjnaC/cloud - no ceiling - rotated.ply');
viconCalib = load('D:/Documents/Work/MeshCollecting/Vicon_session_2020_12_02/markers_out.txt');
figure();
for i = 1:8
    plot3(vicon(i, 1), vicon(i, 2), vicon(i, 3), 'ob');
    hold on;
    text(vicon(i, 1) + 0.5, vicon(i, 2)+ 0.5, vicon(i, 3)+ 0.5, num2str(i), 'Color', 'blue');
    hold on;
    plot3(matterport(i, 1), matterport(i, 2), matterport(i, 3), 'xr');
    hold on;
    text(matterport(i, 1)+ 0.5, matterport(i, 2)+ 0.5, matterport(i, 3)+ 0.5, num2str(i), 'Color', 'red');
    hold on;
end
axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');

title('Untransformed markers in Vicon and Matterport');
legend('Markers in Vicon','Markers in Matterport');

% figure();
% pcshow(pcMatterport);
% hold on;
% for i = 1:8
%     plot3(viconCalib(i, 1), viconCalib(i, 2), viconCalib(i, 3), 'xr');
%     hold on;
%     text(viconCalib(i, 1) + 0.1, viconCalib(i, 2)+ 0.1, viconCalib(i, 3)+ 0.1, num2str(i), 'Color', 'red');
%     hold on;
% end

%%
[D, Z, T] =  procrustes(vicon, matterport, 'reflection', false);

figure();

fileID = fopen('./matterport_transformed.txt','w');

for i = 1:8
    plot3(vicon(i, 1), vicon(i, 2), vicon(i, 3), 'ob');
    hold on;
    text(vicon(i, 1) + 0.5, vicon(i, 2)+ 0.5, vicon(i, 3)+ 0.5, num2str(i), 'Color', 'blue');
    hold on;
    plot3(Z(i, 1), Z(i, 2), Z(i, 3), 'xr');
    hold on;
    text(Z(i, 1)+ 0.5, Z(i, 2)+ 0.5, Z(i, 3)+ 0.5, num2str(i), 'Color', 'red');
    hold on;
    nbytes = fprintf(fileID,'%f %f %f \n',Z(i, 1), Z(i, 2), Z(i, 3));
end
fclose(fileID);
axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Transformed markers in Vicon and Matterport');
legend('Markers in Vicon','Transformed markers in Matterport');


matterportTransformed = zeros(pcMatterport.Count,3);

%%
%T.T = det(T.T) * T.T;
for i = 1:pcMatterport.Count
    matterportTransformed(i,:) = (T.b * pcMatterport.Location(i,:) * T.T + T.c(1,:));   
end

pcMatterportTransformed = pointCloud(matterportTransformed);
pcMatterportTransformed.Color = pcMatterport.Color;

figure();
pcshowpair(pcMatterport, pcMatterportTransformed);

pcwrite(pcMatterportTransformed,'matterport2vicon.ply');

axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');

title('Transformed and untransformed Matterport pointcloud');
legend('\color{white} untransformed Matterport','\color{white} transformed Matterport');

figure();
pcshow(pcMatterportTransformed);
hold on;
for i = 1:8
    plot3(vicon(i, 1), vicon(i, 2), vicon(i, 3), 'ob');
    hold on;
    text(vicon(i, 1) + 0.1, vicon(i, 2)+ 0.1, vicon(i, 3)+ 0.1, num2str(i), 'Color', 'blue');
    hold on;
end
axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');

title('Transformed markers in Vicon and Matterport in transformed Matterport pointcloud');
legend('\color{white} Matterport','\color{white} Vicon markers');
