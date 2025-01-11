function    [p,t,rr,L] = refineposn(svp,p,del,t,corrs)
%
%    [p,t,rr] = refineposn(svp,clkerr,p,del)
%     svp is sv information from svposns
%     clkerr is sv clock errors in seconds
%     p is starting estimate of receiver position in ECEF
%     del is code delays in chips
%     t is the time offset estimate
%		corrs is an optional vector of range corrections for each SV
%
%     p is the refined position in ECEF
%     t is the refined time offset estimate
%     rr is the RMS pseudo-range residual in meters
%     L is the pseudo-range errors for each sv

C = 299792458 ; %speed of light
if nargin<4,
   t = 0 ;
end

if nargin<5,
	corrs = 0 ;
end
	
THR = C*512/1023e3 ;
FSCALE = C*0.001 ;

% Simple tropospheric delay correction
% Compared to Saastamoinen algorithm, this gives an error of <1m at 
% elevations >10 and an error of 4.5m at 5 degrees.
corrs = corrs + 2.4./sin(svp(:,7)) ;

pr = C*del(:)/1023e3 ;		% pseudo ranges in metres

[r,DD] = rotrange(svp(:,1:3),p) ;
rc = r + t*C - svp(:,8)*C + corrs ;
L = moddiff(rc,FSCALE,THR,pr) ;
A = [DD -ones(size(svp,1),1)] ;
dR = pinv(A)*L ;
p = p+dR(1:3)' ;
t = t+dR(4)/C ;

r = rotrange(svp(:,1:3),p) ;
rc = r + t*C - svp(:,8)*C + corrs ;
L = moddiff(rc,FSCALE,THR,pr) ;
rr = sqrt(sum(L.^2)) ;
%fprintf('Prange residual %f m RMS\n',rr) ;
return


function    L = moddiff(r,lim,thr,pr)
%
%	thr = C*512/1023e3 = 150042.7551
%	lim = C*0.001 = 299792.458

L = mod(r,lim)-pr ;
m = L(1) ;
for k=2:length(L),
   dv = L(k)+[0 -lim lim] ;
   [mm nn] = min(abs(dv-m)) ;
   L(k) = dv(nn) ;
   m = mean(L(1:k)) ;
end
return

% old way of doing it - fails if the time offset is close
% to +/- thr.

function    L = moddiff1(r,lim,thr,pr)
%
L = mod(r,lim)-pr ;
kf = L>thr ;
L(kf) = L(kf)-lim ;
kf = L<-thr ;
L(kf) = L(kf)+lim ;
return
