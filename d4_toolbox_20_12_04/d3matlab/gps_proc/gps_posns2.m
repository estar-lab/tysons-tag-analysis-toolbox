function    [POS,N,gps] = gps_posns2(OBS,pos,tc,excl,thr,kproc)

%     [POS,N,gps] = gps_posns2(Obs,pos,tc,[excl,THR,kproc])
%     Search for the positions corresponding to pre-processed GPS grabs.
%		Compared to gps_posns.m, this function uses a faster and more accurate
%		searching algorithm but assumes that the positions are recorded at a
%		fixed height.
%
%		Inputs:
%     OBS is an observation structure or structure array returned 
%     by d3preprocgps.m or proc_gpsbinfile.m
%     pos = [latitude,longitude] is an estimate of the starting position 
%       of the animal (decimal degrees, -ve for south and west). If the observations
%		  are made at a height other than sea-level, this can be specified in a third
%		  element in pos. Height is given in metres above mean sea-level.
%     tc specifies the approximate time offset in seconds between the 
%			actual GPS time and the tag-reported time. tc=gps_time-tag_time.
%			Use gps_timesearch.m to estimate tc.
%     excl is an optional list of satellite numbers to exclude. Use [] if there are
%		   no exclusions and other optional parameters are needed.
%     thr is an optional power threshold allowing SVs with low SNR to be
%       excluded from the analysis. The default value is 200.
%     kproc allows specification of a subset of the observations to
%       process. Default is to process all of the observations.
%
%     Returns:
%     POS is a structure containing the decoded time and position of all grabs for
%			which a reliable position was resolved. The structure has fields:
%			T corrected gps time of each grab in Matlab datenum
%			lat is the latitude for each grab in decimal degrees.
%        lon is the longitude for each grab in decimal degrees.
%			tc is the time offset between gps time and time time, i.e., tc=gps_time-tag_time
%        TT is the tag-reported time of each grab in Matlab datenum.
%			h is the height in metres above mean sea-level. This is just the value passed
%			  in in POS (or 0 if no height is given) as height is assumed to be constant 
%			  for all grabs.
%     N is a matrix of SV and timing quality information for each processable grab in POS.
%           Columns are: number of SVs above threshold
%                        mean snr
%                        estimated time offset in seconds
%                        RMS residual pseudorange in m
%		gps is a structure containing the decoded time and position for all grabs. It
%			has the same fields as POS plus:
%        n is the matrix defined above for all grabs.
%			k is a vector with the grab numbers corresponding to the reliable
%			  positions in POS.
%
%		To convert POS.T into seconds since tag on and create a sensor structure, 
%		do the following:
%			[POSs,info] = make_pos(POS,info);
%		where info is the general metadata structure for the deployment (see make_info.m).
%
%		Notes: 
%		1. This new function is experimental. Please report any errors to me. If
%		this function does not work for you, use gps_posns.m
%		2. Because of the height constraint, this function can produce positions that
%		have a low residual pseudorange but which are manifestly incorrect. This seems to happen
%		especially when the battery voltage is low. Check the track and remove any positions at
%		the end of the recording that are dubious. If in doubt, re-run the last observations
%		with gps_posns.
%
%     markjohnson@bio.au.dk
%     www.soundtags.org
%     modified: 14 April 2022
%			- corrected format of results to match gps_posns
%			- added check of rinex files to catch incomplete ephemeri
%					 25 April 2023
%			- checked for bad SVs and added exclusion list to calling arguments.
%			  Note: change of order in optional arguments.

POS = [] ; N = [] ; gps = [] ;
drawpts = 0 ;
USEREF = 1 ;   % If 1, use refined pseudo-ranges if they are available

if nargin<3,
	help gps_posns_new
	return
end
	
if nargin<4,
	excl = [] ;
end

if nargin<5 || isempty(thr),
	thr = 200 ; 
end

if nargin<6 || isempty(kproc),
	kproc = 1:length(OBS) ;
end
	
if ~isfield(OBS,'R'),
	USEREF = 0 ;
end

if length(pos)==2,	% if no height is given...
	pos(3) = 0 ;		% assume observation is at sea-level
end
	
S = struct('minel',0*pi/180,'h',pos(3)) ;
X = NaN(length(kproc),3) ;
RR = NaN(length(kproc),5) ;
[fnames,fnums] = get_rinex(vertcat(OBS(kproc).T)+repmat([0,0,0,0,0,tc],length(kproc),1));
if isempty(fnames), return, end

fprintf('Checking ephemeris files...\n')
if check_rinex(fnames)>0	% make sure the rinex files are complete
	fprintf('Warning: one of more ephemeris file is incomplete - positions may be inaccurate\n') ;
end
	
neph = 0 ;
dn = datenum(vertcat(OBS(kproc).T)) ;
if drawpts,
	hh = [] ;
	figure(1),clf
end

fprintf('Computing positions...\n')
for k=1:length(kproc),			% search across grabs
	if fnums(k)~=neph,
		[S.reph,S.iono] = read_rnx(fnames{fnums(k)}) ;	% get Rinex ephemerides
		neph = fnums(k) ;
	end
	if rem(k,100)==0,
		fprintf('%d\n',k) ;
	end
	Obs=OBS(kproc(k));
	T = datevec(dn(k)+tc/(24*3600)) ;
	tgps = utc2gps(T) ;
	S.sgps = tgps(2) ;        % GPS second of week accounting for leap seconds
	
	if USEREF==1 & ~isempty(Obs.R),
      p = Obs.R(:,[1 2 4]) ;		% use refined SV observations
   else
      p = [Obs.sv,10.^(Obs.snr/10),Obs.del] ;	% otherwise use basic observations
   end

	p(excl,2) = 0 ;		% exclude bad SVs
	
	if ~isempty(thr),
		S.P = p(p(:,2)>=thr,:) ;	% pick out just the observations with high SNR
	else
		S.P = p ;
	end
	if size(S.P,1)<4, continue, end
	
	try
		[X1,rr] = gps_ls1(pos,S) ;
	catch
		fprintf('gps_ls1 failed on obs %d\n',k) ;
		break
	end
	X(k,:) = [X1(1:2) tc+X1(3)] ;
	RR(k,:) = [rr mean(S.P(:,2))] ;
	if rr(1)<30 && size(S.P,1)>4,
		pos = X1(1:2) ;
		tc = tc+X1(3) ;
		if drawpts,
			if ~isempty(hh),
				set(hh,'Color','b','MarkerSize',8) ;
			end
			hh = plot(pos(2),pos(1),'r.'); hold on
			set(hh,'MarkerSize',12) ;
			drawnow
		end
	end
end

% fix longitude angle convention
kn = find(X(:,2)>180) ;
X(kn,2) = X(kn,2)-360 ;
% collect reporting parameters
N = [RR(:,4:5) X(:,3) RR(:,1)] ;

gps.lat = X(:,1) ;
gps.lon = X(:,2) ;
gps.TT = dn ;
gps.tc = X(:,3) ;
gps.T = gps.TT+gps.tc/(3600*24) ;
gps.h = repmat(S.h,length(kproc),1) ;
gps.n = N ;
k=find(RR(:,1)<30);
gps.k = k ;
N = N(k,:) ;
POS.lat = X(k,1) ;
POS.lon = X(k,2) ;
POS.TT = dn(k) ;
POS.tc = X(k,3) ;
POS.T = POS.TT+POS.tc/(3600*24) ;
POS.h = repmat(S.h,length(k),1) ;

snr = horzcat(OBS.snr);
snr(excl,:) = 0 ;
snr = (snr>=10*log10(thr)) ;
R = nan(32,2) ;
for k=1:32,
	R(k,:) = [nanmean(gps.n(snr(k,:)==1,4)) nanmean(gps.n(snr(k,:)==0,4))] ;
end
[m,k] = max(R(:,1)./R(:,2)) ;
if m>1.5,
	fprintf(' Possible bad data from SV %d. Try excluding this SV\n',k) ;
end
return


function	n = check_rinex(fnames)
%
n = 0 ;
for k=1:length(fnames),
	try
		eph = read_rnx(fnames{k}) ;
	catch
		fprintf('Error reading rinex file %s\n',fnames{k}) ;
		n = n+1 ;
		continue
	end
	if size(eph,2)<12*32,	% there should be a 2-hourly ephemeris for each sv
		n = n+1 ;
	end
end
		