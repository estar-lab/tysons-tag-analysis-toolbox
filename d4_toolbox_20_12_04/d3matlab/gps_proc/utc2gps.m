function    tgps = utc2gps(tvec,noleap)
%
%    tgps = utc2gps(tvec,noleap)
%    tgps is a two-element vector containing [week,sow]
%

% UTC to GPS offset in seconds. correct from 2006-1-1

%UTC2GPS = 14 ; 
%VALID = [2006 1 1 0 0 0] ;
if nargin==2,
	UTC2GPS = 0 ;
else
	UTC2GPS = 18 ;
end	
VALID = [2017 1 1 0 0 0] ;

% GPS epoch started on Jan. 6th 1980 at 0000.
gpsepoch = datenum([1980 1 6 0 0 0]) ;
secsinday = 24*3600 ;

tgps = [] ;
if size(tvec,2)==1,
   tvec = tvec' ;
end
ttime = datenum(tvec) ;
validnum = datenum(VALID) ;
if ttime<validnum,
   fprintf(' input time must be after %s UTC\n', datestr(VALID,0)) ;
   return
end

gpsday = ttime-gpsepoch+UTC2GPS/secsinday ;
week = round(gpsday/7) ;
sow = secsinday*(gpsday-week*7) ;
if sow<0,
   week = week-1 ;
   sow = secsinday*(gpsday-week*7) ;
end

tgps = [week,sow] ;
