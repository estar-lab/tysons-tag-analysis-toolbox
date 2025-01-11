function    P = svposns(SVPOS,tow,pos,lla)
%
%     P = svposns(SVPOS,tow,pos,lla)
%     Computes the position of each space vehicle in the 
%     list SV at GPS times of week tow. The range, Doppler
%     azimuth and elevation of each SV with respect to a receiving
%     position pos=[lat long alt] are also given. Lat and lon are
%     in degrees. Alt is in m above the reference geoid.
%     P is a nx8xt matrix containing (n=number of SVs,
%     t is the number of times):
%     P(sv,:,t) = [x y z range doppler azimuth elevation clkerr]
%     All distances are in meters, doppler in Hz and angles
%     in radians. clkerr is in seconds.
%

DOPP_SCF = 1575.42e6/3e8 ;
v_light = 299792458; 			% [m/s]

if nargin==4,
   % convert lat and lon to radians
   lla(1:2) = lla(1:2)*pi/180 ;     

   % convert to ECEF
   pos = lla2ecef(lla(:)') ;
end

[GD,GC,Q]=ecef2azel(pos) ;
rnorth = Q(:,1); reast = Q(:,2) ; rup = Q(:,3) ;

P = NaN*zeros(length(SVPOS),8,length(tow)) ;
for kk=1:length(SVPOS),
   pp = SVPOS{kk} ;
   if isempty(pp), continue, end
	if all(tow<min(pp(:,1))-3e5),
		tow = tow+604800 ;
	end
		
   clkerr = 1e-6*interp1(pp(:,1),pp(:,5),tow) ;   % clkerr of satellite k at rxtime
 	txtime = tow + clkerr;
   pint = 1000*interp1(pp(:,1),pp(:,2:4),txtime) ;   % ECEF coords of satellite k at approx txtime
   if any(isnan(pint)), continue, end
   [r,V] = rotrange(pint,pos) ;
	txtime = txtime - r/v_light ;
   pint = 1000*interp1(pp(:,1),pp(:,2:4),txtime) ;   % ECEF coords of satellite k at approx txtime
   Vm = 1000*interp1(pp(:,1),pp(:,2:4),txtime-1) ;   % ECEF coords of SV(k) at TIME-1s
   Vp = 1000*interp1(pp(:,1),pp(:,2:4),txtime+1) ;   % ECEF coords of satellite k at TIME+1s
	VV = (Vp-Vm)/2 ;		% speed
   
	%relativistic correction term
	dtrel = -2*sum(pint.*VV,2)/(v_light^2);
   txtime = txtime - dtrel;
   clkerr = clkerr + dtrel;
   pint = 1000*interp1(pp(:,1),pp(:,2:4),txtime) ;   % ECEF coords of satellite k at tow

   rm = rotrange(Vm,pos) ;
   rp = rotrange(Vp,pos) ;
   dopp = DOPP_SCF*(rp-rm)/2 ;    % doppler shift in Hz 
   [r,V] = rotrange(pint,pos) ;
   el = pi/2-acos(V*rup) ;         % elevation of SV wrt to LTP
   az = atan2(V*reast,V*rnorth) ;  % azimuth of SV wrt to LTP
   P(kk,:,:) = [pint,r,dopp,az,el,clkerr]' ;
end

% remove third dimension of P if there is only one time
P = squeeze(P) ;
return
