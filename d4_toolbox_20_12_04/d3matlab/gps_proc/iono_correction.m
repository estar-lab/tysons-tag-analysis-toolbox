function	delay = iono_correction(pos,azel,time_rx,ionoparams)

%   delay = iono_correction(pos,azel,time_rx,ionoparams);
%
% INPUT:
%   pos = receiver latitude and longitude (degrees)
%   azel  = satellite azimuth and elevation (radians)
%   time_rx    = receiver reception time (gps seconds)
%   ionoparams = ionospheric correction parameters [alpha0-3,beta0-3]
%
% OUTPUT:
%   delay = ionospheric error correction in metres
%
% DESCRIPTION:
%   Computation of the pseudorange correction due to ionospheric delay
%   using Klobuchar model.

% Abridged and adapted from:        goGPS v0.4.3
% Copyright (C) 2009-2014 Mirko Reguzzoni, Eugenio Realini
% Portions of code contributed by Laboratorio di Geomatica, Polo Regionale di Como,
%    Politecnico di Milano, Italy
% Portions of code contributed by Giuliano Sironi, 2011
% Portions of code contributed by Antonio Herrera Olmo, 2012
% KLOBUCHAR MODEL
% Algorithm taken from Leick, A. (2004) "GPS Satellite Surveying - 2nd Edition"
% John Wiley & Sons, Inc., New York, pp. 301-303)
	
v_light = 299792458 ;
delay = zeros(size(azel,1),1);
azel = azel*180/pi ;

%ionospheric parameters
a = ionoparams(1:4);	% alpha 0-3
b = ionoparams(5:8);	% beta 0-3
	
% conversion to semicircles
lat = pos(1)/180;
lon = pos(2)/180;
az = azel(:,1)/180;
el = abs(azel(:,2))/180;
	
f = 1 + 16*(0.53-el).^3;
psi = (0.0137 ./ (el+0.11)) - 0.022;
phi = lat + psi .* cos(az*pi);
phi(phi > 0.416)  =  0.416;
phi(phi < -0.416) = -0.416;
lambda = lon + ((psi.*sin(az*pi)) ./ cos(phi*pi));
ro = phi + 0.064*cos((lambda-1.617)*pi);
t = lambda*43200 + time_rx;
t = mod(t,86400);
	
A = a(1) + a(2)*ro + a(3)*ro.^2 + a(4)*ro.^3;
A(A < 0) = 0;
P = b(1) + b(2)*ro + b(3)*ro.^2 + b(4)*ro.^3;
P(P < 72000) = 72000;
x = (2*pi*(t-50400)) ./ P;
	
% ionospheric delay
index = find(abs(x) < 1.57);
delay(index,1) = v_light * f(index) .* (5e-9 + A(index) .* (1 - (x(index).^2)/2 + (x(index).^4)/24));
index = find(abs(x) >= 1.57);
delay(index,1) = v_light * f(index) .* 5e-9;
