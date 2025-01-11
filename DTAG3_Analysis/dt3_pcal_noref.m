%Dtag3 pressure calibration
%t. hurst, 7/29/19
%No pressure reference available. (eyeball the pressure stand scale)

clear all;close all;clc;
figtitle = 'Dtag3 - 302 Pressure Cal Sept23';

%select path

fprintf('Select desired data directory...');
path = uigetdir;cd(path);
%select files: tag file will be a .swv; ref file will be a .txt
clc;fprintf('Select cTag (.swv) Pressure file...');
tagfile = uigetfile('*.swv');

%number of ginput points
numpts = 7; 
refpsi = [1000; 750; 500; 250; 0]; %these are reference pressures in psi
refmtr = refpsi.*0.6859; %convert psi to meters

%select tag values
% [path,name] = fileparts(tagfile);[x,fs,uchans] = d3parseswv_old(name);
[path,name] = fileparts(tagfile);[Sam] = d3parseswv(name);
x = decdc(Sam.x{10,1},10);
fs = Sam.fs;
plot(x);
clc;fprintf(['Select ' num2str(numpts) ' points on graph, starting with 0...']);
zoom;pause;b = ginput(numpts);clc;tagraw = b(:,2);

%generate cal constants
%Pp converts tag data to psi, Pm converts to meters
order = 2;
[Pp,S] = polyfit(tagraw,refpsi,order);[tagpsi,dtpsi] = polyval(Pp,tagraw,S);
[Pm,S] = polyfit(tagraw,refmtr,order);[tagmtr,dtmtr] = polyval(Pm,tagraw,S);
%plot results
subplot(221);plot([refpsi tagpsi],'-*');grid;title('Pressure Calibration pts, PSI');
subplot(223);plot([refpsi-tagpsi],'-*');grid;title('Error (ref-corrected), PSI');
subplot(222);plot([refmtr tagmtr],'-*');grid;title('Pressure Calibration pts, meters');
subplot(224);plot([refmtr-tagmtr],'-*');grid;title('Error (ref-corrected), meters');

%check plot
figure
data2 = polyval(Pm,x);t2 = (1:length(data2))./(fs(10)/10);
plot(t2,data2);
ylabel('Press (m)','FontSize',12,'FontWeight','bold');legend('ref data','tag data');grid
text(0,0,['Pm = [' num2str(Pm) ']'],'FontSize',12,'FontWeight','bold')
title(figtitle,'FontSize',14,'FontWeight','bold')

clc;fprintf('copy these constants into spreadsheet (meters)');
format bank,[Pm]

