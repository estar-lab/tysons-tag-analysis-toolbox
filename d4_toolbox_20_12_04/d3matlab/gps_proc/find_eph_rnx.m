function eph = find_eph_rnx(Eph,sv,sow)

% eph = find_eph_rnx(Eph,sv,sow)
% Look for ephemerides in Eph corresponding to satellites in sv 
% closest to gps second-of-week sow.
%
% based on FIND_EPH.M by:
% Kai Borre and C.C. Goad 11-26-96
% Copyright (c) by Kai Borre

eph = [] ;
for k=1:length(sv),
	isat = find(Eph(1,:) == sv(k));
	if isempty(isat), continue, end
	ks = closest(Eph(2,isat)',sow) ;
	eph(:,end+1) = Eph(:,isat(ks)) ;
end