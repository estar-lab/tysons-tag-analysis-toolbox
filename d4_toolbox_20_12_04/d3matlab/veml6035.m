function		L = veml6035(cal,x)

%		L = veml6035(x)
%     or
%     L = veml6035(cal,x)
%
%		Convert raw light readings into Lux. If a cal structure is given,
%     use the calibration values in that. Otherwise, use the approximate
%		values from the data sheet.

% conversion constant for the sensor
% this value is for DG-1, GAIN=1, SENS=0, IT=200 ms
scf = 0.0016*65536/2 ;
L = [] ;

if ~isstruct(cal),
   x = cal ;
else
   if nargin<2,
      help veml6035
      return
   end
   if isfield(cal,'CAL'),
      scf = cal.CAL(1) ;
   end
end

k = find(x<0) ;
x(k) = 2+x(k) ;
L = scf * x ;
