function [eph,iono,leaps] = read_rnx(navfile)
%
%       [eph,iono,leaps] = read_rnx(navfile)
%       Reads a RINEX V2 Navigation Message file and
%	     reformats the data into a matrix with 21
%	     rows and a column for each satellite and time.
%       eph rows are:
%        1  svprn    Satellite PRN number
%        2  toe      time of ephemeris (sec of GPS week)
%        3  tom      time of ephemeris (sec of GPS week)
%        4  af0      clock bias  (sec)
%        5  af1      clock drift (sec/sec)
%        6  af2      clock drift rate (sec/sec^2)
%        7  M0       M0 (rads)
%        8  roota    sqrt(A) (m^0.5)
%        9  deltan   Delta n (rads/sec)
%       10  ecc      Eccentricity (-)
%       11  omega    omega (rads)
%       12  cuc      Cuc (rads)
%       13  cus      Cus (rads)
%       14  crc      Crc (m)
%       15  crs      Crs (m)
%       16  i0       i0 (rads)
%       17  idot     I DOT (rads/sec)
%       18  cic      Cic (rads)
%       19  cis      Cis (rads)
%       20  Omega0   OMEGA (rads)
%       21  Omegadot OMEGA DOT (rads/sec)
%
% Units are either seconds, meters, or radians
%
% markjohnson@bio.au.dk
% April 2020
% modified from rinexe.m by
% Kai Borre 04-18-96
% Copyright (c) by Kai Borre
% last modified by mj 14/4/2022 - added check for long trailing data at end
% of file

iono = [] ;
eph = [] ;
leaps = [] ;

fide = fopen(navfile);
if fide<1,
	fprintf('Unable to find RINEX file %s\n',navfile) ;
	return
end

while 1
   line = fgetl(fide);
   if ~isempty(findstr(line,'ION ALPHA')),
		   iono(1) = str2num(line(4:14));
		   iono(2) = str2num(line(16:26));
		   iono(3) = str2num(line(28:38));
		   iono(4) = str2num(line(40:50));
   elseif ~isempty(findstr(line,'ION BETA')),
		   iono(5) = str2num(line(4:14));
		   iono(6) = str2num(line(16:26));
		   iono(7) = str2num(line(28:38));
		   iono(9) = str2num(line(40:50));
   elseif ~isempty(findstr(line,'LEAP SECONDS')),
		   leaps = str2num(line(4:6));
	elseif ~isempty(findstr(line,'END OF HEADER')),
         break
	end
end;

eph = NaN(21,1000) ;		% preallocate some space
k = 0 ;

while 1
	line = {} ;
	for l=1:8,	% read in the 8 lines of an ephemeris
		s = fgetl(fide);
		if isempty(s) || ~ischar(s(1)), line={}; break, end
		line{l} = s ;
	end
	if isempty(line), break, end
	sv = str2num(line{1}(1:2)) ;
   if isempty(sv) || sv<1 || sv>32 || abs(line{1}(3))~=32,
		continue  % skip sections that don't match format
	end
	k = k+1 ;
	if k>size(eph,2),
		eph(:,end+(1:1000)) = NaN ;	% allocate some more space if we have run out
	end

   eph(1,k) = sv;	% SV PRN number
   eph(2,k) = str2num(line{4}(4:22));	% time of ephemeris
   eph(3,k) = str2num(line{8}(4:22));	% time of message
   eph(4,k) = str2num(line{1}(23:41));	% af0
   eph(5,k) = str2num(line{1}(42:60));	% af1
   eph(6,k) = str2num(line{1}(61:79));	% af2
	eph(7,k) = str2num(line{2}(61:79)); % M0;
	eph(8,k) = str2num(line{3}(61:79)); % roota;
	eph(9,k) = str2num(line{2}(42:60)); % deltan;
	eph(10,k) = str2num(line{3}(23:41)); % ecc;
	eph(11,k) = str2num(line{5}(42:60)); % omega;
	eph(12,k) = str2num(line{3}(4:22)); % cuc;
	eph(13,k) = str2num(line{3}(42:60)); % cus;
	eph(14,k) = str2num(line{5}(23:41)); % crc;
	eph(15,k) = str2num(line{2}(23:41)); % crs;
	eph(16,k) = str2num(line{5}(4:22)); % i0;
	eph(17,k) = str2num(line{6}(4:22)); % idot;
	eph(18,k) = str2num(line{4}(23:41)); % cic;
	eph(19,k) = str2num(line{4}(61:79)); % cis;
	eph(20,k) = str2num(line{4}(42:60)); % Omega0;
	eph(21,k) = str2num(line{5}(61:79)); % Omegadot;
end

fclose(fide) ;
eph = eph(:,1:k) ;
