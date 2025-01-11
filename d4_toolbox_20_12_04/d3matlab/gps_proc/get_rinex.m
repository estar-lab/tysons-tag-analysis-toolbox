function    [fnames,fnums] = get_rinex(T)
%
%     [fnames,fnums] = get_rinex(T)
%     Download orbitology for the UTS times in 6-element date vector T.
%		T can contain multiple times with each time on a row. If the 
%		required Rinex files are not already available in the data directory,
%		this function attempts to download them from a GPS data repository
%     and uncompress them.
%     Returns: fnames is empty if unsuccessful.
%
%     Note: this function needs -
%     1. a patch to the FTP functionality if using an old version of Matlab. See
%     the README file in the gps_proc directory.
%     2. uncompressor executable 7za.exe which should be
%     in the gps_proc directory.
%		3. This function relies on an archive of Rinex files held by the European Space Agency.

%		markjohnson@bio.au.dk
%		last modified: 13 April 2022
%			improved robustness of ftp connection and added support for multiple file suffixes

% FTP servers for daily broadcast ephemeris files:
% smuc.st-andrews.ac.uk (anonymous login) /pub/mirrors/rinex/ngs - only up to part of 2019; no longer attended
% gssc.esa.int (no login) gnss/data/daily - files are small and give poor positioning, why?
% nfs.kasi.re.kr (no login) gps/data/daily
% igs.gnsswhu.cn (no login) pub/gps/data/daily

% These FTP servers will probably eventually vanish. When they do, the broadcast ephemeris data is available here:
% https://cddis.nasa.gov at archive/gnss/data/daily but this requires making an account and logging in.

gpsdir = fileparts(which('get_almanac')) ;
datadir = [pwd '/temp'] ;
%ftpserv = 'smuc.st-andrews.ac.uk' ;
%ANON = 1 ;
%ftpdir = '/pub/mirrors/rinex/ngs' ;
%DAYDIR = 0 ;
%SUBDIR = 0 ;
ftpserv = 'nfs.kasi.re.kr' ;
ANON = 0 ;
ftpdir = '/gps/data/daily' ;
DAYDIR = 1 ;	% directory structure is YYYY/DDD
SUBDIR = 1 ;	% data is in a sub-directory named YYn
suffix = {'Z','gz'} ;		% possible suffixes

if size(T,2)==1,
   T = T(:)' ;    % make sure T is a row vector if only one time vector
end

Te = T + repmat([0 0 0 -1 0 0],size(T,1),1) ;
Tl = T + repmat([0 0 0 1 0 0],size(T,1),1) ;
T = datevec(datenum([T;Te;Tl])) ;
TT = [T(:,1) julian_day(T(:,1:3))] ;
[YD,I,J] = unique(TT,'rows') ;
fnames = cell(size(YD,1),1) ;
ftoget = {} ;
ydir = [] ;
fnums = J(1:size(T,1)) ;

% work out which files are needed
for k=1:size(YD,1),
	fn = sprintf('brdc%03d0.%02dn',YD(k,2),mod(YD(k,1),100));
	fnames{k} = [datadir '/' fn] ;
	if ~exist(fnames{k},'file'),
		ftoget{end+1} = fn ;
		ydir(end+1,:) = YD(k,:) ;
	end
end

if isempty(ftoget), return, end	% all Rinex files are already downloaded

% try to login to ftp file server
s = [] ;
if ANON==1,
	for k=1:3,     % try three times in case of internet timeouts
		try
			s=ftp(ftpserv,'anonymous','info@animaltags.org');
		catch
		end
		if ~isempty(s), break, end
	end
else
	for k=1:3,     % try three times in case of internet timeouts
		try
			s=ftp(ftpserv);
		catch
		end
		if ~isempty(s), break, end
	end
end

if isempty(s),
	fprintf('Unable to access ftp site - check internet connection and restart matlab\n') ;
	fnames = [] ;
	return
end	

for k=1:length(ftoget),
   try		% change directory on ftp server
		cd(s,sprintf('/%s/%04d',ftpdir,ydir(k,1))) ;
		if DAYDIR==1,
			cd(s,sprintf('%03d',ydir(k,2))) ;
			if SUBDIR==1,
				cd(s,sprintf('%02dn',mod(ydir(k,1),100))) ;
			end
		end
	catch
		fprintf('Unable to access directory on ftp site\n') ;
		fnames = [] ;
		close(s);
		return
	end
	
   fprintf('getting %s...\n',ftoget{k}) ;
	gotit = 0 ;
	% try downloading rinex file, trying each of the possible suffixes
	for ktry=1:2*length(suffix),	% try twice for each potential suffix in case of internet timeouts
		fnz = [ftoget{k} '.' suffix{1+rem(ktry,length(suffix))}] ;
		try
			L = mget(s,fnz,datadir) ;
		catch
			L = [] ;
		end
		if ~isempty(L),
			gotit = 1 ;
			[n,e] = system([gpsdir '/7zip/7za.exe e ' L{1} ' -y -o' datadir]) ;
			if n>0,
				disp(e) ;
				f = [] ;
			else
				delete(L{1}) ;
			end
			break
		end
	end
	if gotit==0,
		fprintf('Unable to download RINEX file - check connection and try again\n') ;
		fnames = [] ;
		close(s);
		return ;
	end
end
close(s);
