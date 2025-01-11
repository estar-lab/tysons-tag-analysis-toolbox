function		[X,RR] = gps_ls(X,S)

% 		[X,RR] = gps_ls(X,S)
%		Inputs:
%		X is a starting estimate of the position [latitude, longitude]
%		S is a structure of satellite observations
%			S.P contains the observed SVs and their code delays
%			S.sgps is the approximate gps second of the grab
%			S.reph contains the Rinex ephemeri
%			S.iono contains the ionosphere correction parameters (from the Rinex file)
%
%		Returns:
%		X = [latitude, longitude, time offset]
%		RR = [RMS range error,worst range error,SV with worst error,number of SVs]

C = 299792458 ;
ETOL = 0.1 ;
% retrieve parameters
pos = X(1:2) ;
tc = 0 ;
reph = S.reph ;	% ephemeris entry
P = S.P ;			% observed SVs and code delays
iono = S.iono ;	% ionospheric parameters

for k=1:20,
	ecef_pos = lla2ecef([pos(1:2)*pi/180 S.h]) ;
	Q = null(ecef_pos) ;
	sgps = S.sgps+tc ;	% approximate GPS second of grab

	% get the SV positions at the receive time
	reph1 = find_eph_rnx(reph,P(:,1),sgps) ;	% get closest entry in time
   TP = sv_posn_rnx(sgps,reph1) ;

	% distance from each SV to the proposed position
	r = norm2(TP(:,1:3)-repmat(ecef_pos,size(TP,1),1)) ;
	txr = sgps - r/C;		% transmit time = rx rime - travel time

	% get the SV positions at the transmit time
	TP = sv_posn_rnx(txr,reph1) ;
	TP2 = sv_posn_rnx(txr+0.05,reph1) ;
	TP1 = sv_posn_rnx(txr-0.05,reph1) ;
	TV = (TP2-TP1)*(10/1000) ;		% SV velocity in km/s (use km/s to balance covariates)

	% compute the azimuth and elevation of each SV and compute atmospheric corrections
	azel = azel_wrt_pos(TP(:,1:3),ecef_pos) ;
	kk = find(azel(:,2)>S.minel) ;	% only keep SVs that are above minel elevation
	corrs = iono_correction(pos,azel(kk,:),sgps,iono) ;
	corrs = corrs + 2.410787./(sin(azel(kk,2))+(0.00143./(tan(azel(kk,2))+0.0455))) ;
%DD = TP(kk,1:3)-repmat(ecef_pos,length(kk),1) ;
%dop = [P(kk,1) sum(TV(kk,1:3).*DD,2).*norm2(DD).^(-1)*1000/C*1.575e9]

	% compute the pseudo-range errors
	[r,DD] = rotrange(TP(kk,1:3),ecef_pos) ;	% effective range of each SV
	rc = r - TP(kk,4)*C + corrs - P(kk,3)*(C/1023e3) ; % pseudo-range errors
	L = mod(rc,C/1000) ; 		% constrain errors to +/-150km (code repetition length)
	m = L(1) ;
	for kl=2:length(L),
		dv = L(kl)+C/1000*[0 -1 1] ;
		[mm nn] = min(abs(dv-m)) ;
		L(kl) = dv(nn) ;
		m = mean(L(1:kl)) ;
	end
	RR = sqrt(mean((L-mean(L)).^2)) ; 	% RMS pseudo-range error
	%A = [DD*Q -sum(DD.*TV(kk,1:3),2) -ones(length(kk),1)] ; % why do this?
	A = [DD*Q -sum(DD.*TV(kk,1:3),2)] ; % why not do this?
	dR = pinv(A)*(L-mean(L)) ;
	ecef_pos = ecef_pos+dR(1:2)'*Q' ;
	tc = tc+dR(3)/1000 ;
	pos = ecef2lla(ecef_pos) ;
	pos(1:2) = pos(1:2)*180/pi ;
	if norm(dR(1:2))<ETOL, break, end
end
[m,n] = max(abs(L-mean(L))) ;
RR(2:4) = [m,kk(n),length(kk)];
X = [pos(1:2) tc] ;
