function    T = recordlength(recdir,prefix,suffix)

%     T = recordlength(recdir,depid,suffix)		% dtag version 3 or 4
%	   or
%     T = recordlength(tag)							% dtag version 1 or 2
%		or
%     T = recordlength([],tag,suffix)				% dtag version 1 or 2
%
%     Returns the number of seconds in a tag audio recording.
%
%     markjohnson@bio.au.dk
%     23 March 2023 - updated from the DTAG2 version to include D3/4

T = [] ;
if nargin<1,
   help recordlength
   return
end

if nargin==1,
	prefix = recdir ;
	recdir = [] ;
end

if nargin<3,
	suffix = 'wav' ;
end

if ~isdtag2(prefix),
   [ct,ref_time,fs] = d3getcues(recdir,prefix,suffix) ;	% read the cue table
	if ~isempty(ct),
		T = ct(end,2)+(ct(end,3)-1)/fs ;
	end
	return
end
   
loadcal(prefix,'CUETAB') ;

if ~exist('CUETAB','var')
   fprintf('No CAL file or CUETAB for this deployment\n') ;
   return
end

if size(CUETAB,1)>1,
   T = sum(CUETAB(:,[3 8])./CUETAB(:,[5 10])) ;
else
   T = CUETAB([3 8])./CUETAB([5 10]) ;
end

if strcmp(suffix,'wav'),
	T = T(1) ;
else
	T = T(2) ;
end
