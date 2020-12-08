croppingStart = 0;
croppingEnd = 0;
Binit = 120;
BMax = 160;
vicom = readtable('./Vicom_2020_08_20/2020_08_20_Vicon_HoloLens_Session/seq1.txt');
pvhololens = readtable('./Vicom_2020_08_20/HoloLensRecording__2020_08_20__08_36_27/pv.csv');


figure();

indexes = vicom.Var4(:) ~= 1;


pcVicom = pointCloud([vicom.Var5(indexes), vicom.Var6(indexes), vicom.Var7(indexes)]);
pcHoloLens = pointCloud([pvhololens.Position_X(croppingStart+1:end-croppingEnd), pvhololens.Position_Y(croppingStart+1:end-croppingEnd), pvhololens.Position_Z(croppingStart+1:end-croppingEnd)]);
pcshowpair(pcHoloLens, pcVicom, 'MarkerSize', 50);

axis equal;
xlabel("x");
ylabel("y");
zlabel("z");
title('Hololens and Vicom tracking before registration');


ax = 269;
ay = 69;
az = 248;


Rx = [1 0 0 0; 0 cos(ax) -sin(ax) 0; 0 sin(ax) cos(ax) 0; 0 0 0 1];
Ry = [cos(ay) 0 sin(ay) 0; 0 1 0 0; -sin(ay) 0 cos(ay) 0; 0 0 0 1];
Rz = [cos(az) -sin(az) 0 0; sin(az) cos(az) 0 0; 0 0 1 0; 0 0 0 1];

R = Rx * Ry * Rz;

tform_rotate = affine3d(R);
ptrotHolol = pctransform(pcHoloLens,tform_rotate);

[tform,hololensReg] = pcregrigid(ptrotHolol, pcVicom, 'MaxIterations', 1000);

figure();
pcshowpair(hololensReg, pcVicom, 'MarkerSize', 50);
axis equal;
xlabel("x");
ylabel("y");
zlabel("z");
title(['Registered Hololens tracking and Vicom tracking, ax = ', num2str(ax), ', ay = ', num2str(ay), ', az = ', num2str(az)]);

%% --------------------------------------------------------------

numHolol = size(pvhololens,1);
numVicom = size(vicom,1);

params = [];
indexes = [];
vals = [];
initvals = [];


% holFPS = pvhololens.Timestamp(end - croppingEnd) - pvhololens.Timestamp(1 + croppingStart);
% holFPS = time / 10^7;
% holFPS = size(pvhololens,1) / holFPS;
% a = 100/holFPS;
% k = 1 : hololensReg.Count;

hol = hololensReg.Location(k, :);
minB = 0;

timediff = pvhololens.Timestamp(2 + croppingStart:end - croppingEnd) - pvhololens.Timestamp(1 + croppingStart:end - croppingEnd -1);
timediff = timediff / 10^7;
cs = cumsum([0; timediff]);
cs  = round(cs * 100);


for B = Binit:BMax 
    i = cs + B; 
    vic = pcVicom.Location(i, :);
    Rvic = [vicom.Var8(i), vicom.Var9(i), vicom.Var10(i)];
    
    fun = @(par)closerTransformation([par(1) par(2) par(3)]', par(4), euler2mat([par(5) par(6) par(7)]), [par(8) par(9) par(10)]', vic, Rvic, hol);
    initpar = [0 0 0 1 0 0 0 0 0 0];
    %options = optimset( 'MaxFunEvals', 1000 * 16);
    [bestpar, bestval] = fminsearch(fun, initpar, options);
    
    %t, rho, S, d, C, Rv, D
    initvals = [initvals closerTransformation([initpar(1) initpar(2) initpar(3)]', initpar(4), euler2mat([initpar(5) initpar(6) initpar(7)]), [initpar(8) initpar(9) initpar(10)]', vic, Rvic, hol)];
    
    params = [params bestpar];
    vals = [vals bestval];
    
    if B == Binit
      minpar = bestpar;
      minval = bestval;
      minB = B;
    end
    
    if bestval < minval
      minpar = bestpar;
      minval = bestval; 
      minB = B;
    end
    fprintf(['For B = ', num2str(B), ' the optimized value is ',  num2str(bestval),' parameters are:', '\n' ]);
    bestpar
    
    %t, rho, S, d, C, R, D
end

fprintf(['Best B is ', num2str(minB), ' the optimized value is ',  num2str(minval),' parameters are:', '\n' ]);
minpar

%% -------------------------------------------------------------------------------------------
%pcVicom = pointCloud(vic);
holtrans = zeros(hololensReg.Count, 3);

for i = 1:hololensReg.Count
    holtrans(i,:) = (euler2mat([minpar(5) minpar(6) minpar(7)])' * ((1/minpar(4)) * hol(i,:)') - [minpar(8) minpar(9) minpar(10)]')';
end

pcHol = pointCloud(holtrans);
%% ---------------------------------------------------------------------------




figure();
%%

pcshowpair(pcHol, pcVicom, 'MarkerSize', 50);
axis equal;
xlabel("x");
ylabel("y");
zlabel("z");
title('Registered Hololens tracking and Vicom tracking after tuning');

%%
hold on;
%kresleni car
j = uint64(cs + minB); 
vic = pcVicom.Location(j, :);
for i = 1:hololensReg.Count
    plot3([vic(i, 1), holtrans(i,1)], [vic(i, 2), holtrans(i,2)], [vic(i, 3), holtrans(i,3)], 'r')
end

%%
figure();
plot(Binit:BMax , vals, 'b', Binit:BMax , initvals, 'r');


%%
% figure();
% pcshowpair(hololensReg, pcVicom, 'MarkerSize', 50);
% axis equal;
% xlabel("x");
% ylabel("y");
% zlabel("z");
% title(['Registered Hololens tracking and Vicom tracking, ax = ', num2str(ax), ', ay = ', num2str(ay), ', az = ', num2str(az)]);
% 
% 
% ivic = uint64(cs + 200); 
% hold on;
% Pvic = pcVicom.Location(ivic, :);
% Phol = hololensReg.Location(k, :);
% 
% 
% for i = 1:hololensReg.Count
%     plot3([Pvic(i, 1), Phol(i, 1)], [Pvic(i, 2), Phol(i, 2)], [Pvic(i, 3), Phol(i, 3)], 'r')
% end
% 



%% -------------------------------------------------------------------------------------------
%ax = 269, ay = 69, az = 248
% for i = 1:100
%     ax = randi(360);
%     ay = randi(360);
%     az = randi(360);
%     Rx = [1 0 0 0; 0 cos(ax) -sin(ax) 0; 0 sin(ax) cos(ax) 0; 0 0 0 1];
%     Ry = [cos(ay) 0 sin(ay) 0; 0 1 0 0; -sin(ay) 0 cos(ay) 0; 0 0 0 1];
%     Rz = [cos(az) -sin(az) 0 0; sin(az) cos(az) 0 0; 0 0 1 0; 0 0 0 1];
%     
%     R = Rx * Ry * Rz;
%     
%     tform_rotate = affine3d(R);
%     ptrotHolol = pctransform(pcHoloLens,tform_rotate);
% 
%     [tform,movingReg] = pcregrigid(ptrotHolol, pcVicom, 'MaxIterations', 1000, 'InlierRatio', 1, 'Tolerance', [0.0001, 0.00009]);
% 
% %     figure();
% %     pcshowpair(movingReg, pcHoloLens, 'MarkerSize', 50);
% %     axis equal;
% %     xlabel("x");
% %     ylabel("y");
% %     zlabel("z");
% %     title('Registered Hololens a  nd unregistered Hololens tracking');
% 
%     figure();
%     pcshowpair(movingReg, pcVicom, 'MarkerSize', 50);
%     axis equal;
%     xlabel("x");
%     ylabel("y");
%     zlabel("z");
%     title(['Registered Hololens tracking and Vicom tracking, ax = ', num2str(ax), ', ay = ', num2str(ay), ', az = ', num2str(az)]);
% 
% end
%%  -------------------------------------------------------------------------------------------
holCheck = pcHoloLens.Location(k, :);

rho = minpar(4);
St = euler2mat([minpar(5) minpar(6) minpar(7)])';
Rii = R(1:3, 1:3) * tform.Rotation;
T = St * tform.Translation' - [minpar(8) minpar(9) minpar(10)]';

for i = 1:hololensReg.Count
    holCheck(i,:) = 1/rho * St *  (holCheck(i,:) * Rii)' + T;
end

pcHolCheck = pointCloud(holCheck);

figure();
pcshowpair(pcHolCheck, pcVicom, 'MarkerSize', 50);
axis equal;
xlabel("x");
ylabel("y");
zlabel("z");
title('Registered Hololens tracking and Vicom tracking after tuning');


%%
hold on;

plot3(pcHol.Location(:, 1), pcHol.Location(:, 2), pcHol.Location(:, 3), 'ro');

%% -------------------------------------------------------------------------------------------
function res = closerTransformation(t, rho, S, d, C, Rv, D)
%     C-known
%     R(e)-known
%     t-unknown
%     rho-unknown
%     S(e) - unknown
%     D - known
%     d - unknown
    
    num = size(Rv,1);
    res = 0;
    
    for i = 1:num
        R = euler2mat(Rv(i,:));
        f = C(i,:)' + R * t - (1/rho) * S' * D(i,:)' - d;
        res = res + norm(f)^2;
    end
    
    res = res + 10 * norm(t) + 10 * norm(d);
    %sum(norm(C + R*t - 1/ro * S' * D - d))
end

function R = euler2mat(e)
    x = e(1);
    y = e(2);
    z = e(3);
    R = [(cos(y) * cos(z)) (-1 * cos(y) * sin(z)) sin(y);
         (cos(x) * sin(z) + sin(x) * sin(y) * cos(z)) (cos(x) * cos(z) - sin(x) * sin(y) * sin(z)) (-1 * sin(x) * cos(y));
         (sin(x) * sin(z) - cos(x) * sin(y) * cos(z)) (sin(x) * cos(z) + cos(x) * sin(y) * sin(z)) (cos(x) * cos(y))];

end


