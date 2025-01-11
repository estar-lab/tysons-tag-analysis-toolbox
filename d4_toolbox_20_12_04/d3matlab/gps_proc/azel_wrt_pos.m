function		azel = azel_wrt_pos(V,pos)

%		azel = azel_wrt_pos(V,pos)
%		pos is in ecef
%		V is one or more ecef positions, with each position on a row.
%     azel are in radians

Fsq = (6356752.3/6378137)^2 ;   % squared ratio of the minor to major axes of the earth

% make a local transverse plane around pos
az = atan2(pos(2),pos(1)) ;                     % azimuth of position in ECEF
elgc = atan(pos(3)/sqrt(pos(1:2).^2*[1;1])) ;   % geocentric latitude
el = atan(1/Fsq*tan(elgc)) ;                      % geodetic latitude
reast = [-sin(az);cos(az);0] ;
rnorth = [-sin(el)*[cos(az);sin(az)];cos(el)] ;
rup = pos'/norm(pos) ;

V = V-repmat(pos,size(V,1),1) ;	% make direction vectors between V and pos
V = V.*repmat(norm2(V).^-1,1,3) ;
el = pi/2-acos(V*rup) ;         % elevation of SV wrt to LTP
az = atan2(V*reast,V*rnorth) ;  % azimuth of SV wrt to LTP
azel = [az el] ;
