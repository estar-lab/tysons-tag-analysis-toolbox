%Dtag3X #319 HF Tag

DEV = struct ;
DEV.ID='9a231b34';
DEV.NAME='DX319';
DEV.BUILT=[2018 7 17];
DEV.BUILDER='TH';
DEV.HAS={'stereo audio'};
BBFILE = ['badblocks_' DEV.ID(1:4) '_' DEV.ID(5:8) '.txt'] ;
try,
   DEV.BADBLOCKS = readbadblocks(['c:/mystuff/d3/host/d3usb/' BBFILE]) ;
catch,
   fprintf(' No bad block file\n') ;
end

TEMPR = struct ;
TEMPR.TYPE='ntc thermistor';
TEMPR.USE='conv_ntc';
TEMPR.UNIT='degrees Celcius';
TEMPR.METHOD='none';

BATT = struct ;
BATT.POLY=[6 0] ;
BATT.UNIT='Volt';

PRESS=struct;
PRESS.POLY=[-28.87 2592.85 -111.98];
PRESS.METHOD='rough';
PRESS.LASTCAL=[2018 7 17];
PRESS.TREF = 20 ;
PRESS.UNIT='meters H20 salt';
PRESS.TC.POLY=[0];
PRESS.TC.SRC='BRIDGE';
PRESS.BRIDGE.NEG.POLY=[3 0];
PRESS.BRIDGE.NEG.UNIT='Volt';
PRESS.BRIDGE.POS.POLY=[6 0];
PRESS.BRIDGE.POS.UNIT='Volt';
PRESS.BRIDGE.RSENSE=200;
PRESS.BRIDGE.TEMPR.POLY=[314.0 -634.7] ;
PRESS.BRIDGE.TEMPR.UNIT='degrees Celcius';

ACC=struct;
ACC.TYPE='MEMS accelerometer';
ACC.POLY=[10.0919 -5.0181; 10.0815 -5.0154; 9.9584 -4.9539];
ACC.UNIT='g';
ACC.TREF = 20 ;
ACC.TC.POLY=[0; 0; 0];
ACC.PC.POLY=[0; 0; 0];
ACC.XC=zeros(3);
ACC.MAP=[-1 0 0;0 1 0;0 0 1];
ACC.MAPRULE='front-right-down';
ACC.METHOD='flips';
ACC.LASTCAL=[2018 7 17];

MAG=struct;
MAG.TYPE='magnetoresistive bridge';
MAG.POLY=[711.7059 -253.2902; 699.6801 -233.8166; 680.8546 -256.5467];
MAG.UNIT='Tesla';
MAG.TREF = 20 ;
MAG.TC.POLY=[0;0;0];
MAG.TC.SRC='BRIDGE';
MAG.PC.POLY=[0;0;0];
MAG.XC=zeros(3);
MAG.MAP=[0 -1 0;1 0 0;0 0 -1];
MAG.MAPRULE='front-right-down';
MAG.METHOD='';
MAG.LASTCAL=[2018 7 17];
MAG.BRIDGE.NEG.POLY=[3 0];
MAG.BRIDGE.NEG.UNIT='Volt';
MAG.BRIDGE.POS.POLY=[6 0];
MAG.BRIDGE.POS.UNIT='Volt';
MAG.BRIDGE.RSENSE=20;
MAG.BRIDGE.TEMPR.POLY=[541.91 -459.24] ;
MAG.BRIDGE.TEMPR.UNIT='degrees Celcius';

CAL=struct ;
CAL.TEMPR=TEMPR;
CAL.BATT=BATT;
CAL.PRESS=PRESS;
CAL.ACC=ACC;
CAL.MAG=MAG;

DEV.CAL = CAL ;
writematxml(DEV,'DEV','dx319.xml')

