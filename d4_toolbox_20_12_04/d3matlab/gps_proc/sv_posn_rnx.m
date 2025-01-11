function 	p = sv_posn_rnx(sow,eph);
%   p = sv_posn_rnx(t,eph)
%   Calculation of X,Y,Z coordinates at time sow (seconds of GPS week)
%	 for the ephemerides eph of a set of satellites

% Based on:
% Kai Borre 04-09-96
% Copyright (c) by Kai Borre
% $Revision: 1.1 $  $Date: 1997/12/06  $

GM = 3.986005e14;     % earth's universal gravitational
                      % parameter m^3/s^2
Omegae_dot = 7.2921151467e-5; % earth rotation rate, rad/s
half_week = 302400;

%  Units are either seconds, meters, or radians
toe	  =  eph(2,:);
af0	  =  eph(4,:);
af1	  =  eph(5,:);
af2	  =  eph(6,:);
M0	     =  eph(7,:);
roota   =  eph(8,:);
deltan  =  eph(9,:);
ecc	  =  eph(10,:);
omega   =  eph(11,:);
cuc	  =  eph(12,:);
cus	  =  eph(13,:);
crc	  =  eph(14,:);
crs	  =  eph(15,:);
i0	     =  eph(16,:);
idot    =  eph(17,:);
cic	  =  eph(18,:);
cis	  =  eph(19,:);
Omega0  =  eph(20,:);
Omegadot=  eph(21,:);

sow = sow(:)' ;
tk = sow-toe;
k = tk>half_week ;
tk(k) = tk(k)-2*half_week ;
k = tk<-half_week ;
tk(k) = tk(k)+2*half_week ;
tcorr = af0+tk.*(af1+tk.*af2) ;
tk = tk-tcorr ;	% subtract correction to get estimate of tx time

% Procedure for coordinate calculation
A = roota.*roota;
n0 = sqrt(GM.*A.^-3);
n = n0+deltan;
M = M0+n.*tk;
M = rem(M+2*pi,2*pi);
E = M;
for i=1:10
   E_old = E;
   E = M+ecc.*sin(E);
   dE = rem(E-E_old,2*pi);
   if all(abs(dE) < 1.e-12)
      break;
   end
end
E = rem(E+2*pi,2*pi);
v = atan2(sqrt(1-ecc.^2).*sin(E), cos(E)-ecc);
phi = rem(v+omega,2*pi);
u = phi + cuc.*cos(2*phi)+cus.*sin(2*phi);
r = A.*(1-ecc.*cos(E)) + crc.*cos(2*phi)+crs.*sin(2*phi);
i = i0+idot.*tk + cic.*cos(2*phi)+cis.*sin(2*phi);
Omega = Omega0+(Omegadot-Omegae_dot).*tk-Omegae_dot.*toe;
Omega = rem(Omega+2*pi,2*pi);
x1 = cos(u).*r;
y1 = sin(u).*r;
p(1,:) = x1.*cos(Omega)-y1.*cos(i).*sin(Omega);
p(2,:) = x1.*sin(Omega)+y1.*cos(i).*cos(Omega);
p(3,:) = y1.*sin(i);
p(4,:) = tcorr ;
p = p' ;
