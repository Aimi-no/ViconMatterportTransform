viconPath = readtable('./MeshCollecting/Vicon_session_2020_12_02/hololens_seq02.txt');
pvhololens = readtable('./MeshCollecting/Vicon_session_2020_12_02/HoloLensRecording__2020_12_02__12_47_05/pv.csv');
viconCalib = load('./MeshCollecting/Vicon_session_2020_12_02/markers_out.txt');
matterport = load('./B-315/matterport_transformed.txt');
indexes = viconPath.Var4(:) ~= 1;

viconPoints = [viconPath.Var5(indexes), viconPath.Var6(indexes), viconPath.Var7(indexes)];
viconRotations = [viconPath.Var8(indexes), viconPath.Var9(indexes), viconPath.Var10(indexes)];


cmatrix = ones(size(pvhololens,1),3).*[0 1 0];
pcHoloLens = pointCloud([pvhololens.Position_X(:), pvhololens.Position_Y(:), pvhololens.Position_Z(:)], 'Color', cmatrix);

% R = [1 0 0; 0 cos(-90) -sin(-90); 0 sin(-90) cos(-90)];
% 
% for i = 1:size(viconPoints,1)
%    viconPoints(i,:) = (R * viconPoints(i,:)')'; 
% end

cmatrix = ones(size(viconPoints)).*[1 0 0];
pcVicon = pointCloud(viconPoints, 'Color', cmatrix);
pcMatterport = pcread('./B-315/matterport2vicon.ply');

figure();
pcshow(pcMatterport);
hold on;
pcshow(pcVicon);
hold on;
pcshow(pcHoloLens);
hold on;

for i = 1:8
    plot3(viconCalib(i, 1), viconCalib(i, 2), viconCalib(i, 3), 'ob');
    hold on;
    text(viconCalib(i, 1) + 0.5, viconCalib(i, 2)+ 0.5, viconCalib(i, 3)+ 0.5, num2str(i), 'Color', 'blue');
    hold on;
    
    plot3(matterport(i, 1), matterport(i, 2), matterport(i, 3), 'xr');
    hold on;
    text(matterport(i, 1) + 0.5, matterport(i, 2)+ 0.5, matterport(i, 3)+ 0.5, num2str(i), 'Color', 'red');
    hold on;
end
axis equal;
grid on;


axis on;
xlabel('X');
ylabel('Y');
zlabel('Z');

title('Vicon tracking and Hololens untransformed tracking in transformed Matterport');
legend('\color{white} pcMatterport','\color{white} Vicon tracking', '\color{white} Hololens tracking', '\color{white} Vicon markers', '\color{white} Matterport markers');

function R = euler2mat(e)
    x = e(1);
    y = e(2);
    z = e(3);
    R = [(cos(y) * cos(z)) (-1 * cos(y) * sin(z)) sin(y);
         (cos(x) * sin(z) + sin(x) * sin(y) * cos(z)) (cos(x) * cos(z) - sin(x) * sin(y) * sin(z)) (-1 * sin(x) * cos(y));
         (sin(x) * sin(z) - cos(x) * sin(y) * cos(z)) (sin(x) * cos(z) + cos(x) * sin(y) * sin(z)) (cos(x) * cos(y))];

end