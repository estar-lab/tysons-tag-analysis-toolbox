function    [ltime,fname,cue_in_file] = d3wavcues(cues,recdir,prefix,dirn,suffix)
%
%     [ltime,fname,cue_in_file] = d3wavcues(cues,recdir,prefix,dirn,suffix)
%     Report the UTC time corresponding to tag cues (i.e., 
%     second since start of recording) or vice versa.
%     If dirn=0 (default), cues is taken as containing tag cues, i.e.,
%		   seconds since the start of recording of this sensor data stream.
%     If dirn=1, cues is taken as containing UTC times as date numbers.
%			The date numbers are in Unix seconds (this is not the same as 
%			Matlab's datenumber). Use d3datenum to compute Unix seconds
%			corresponding to a date.
%
%     Returns:
%     ltime is in Unix seconds. Use unix2datevec to convert to a date vector.
%		fname is the dtg file name in which the cue falls.
%		cue_in_file is the number of seconds into the wav file corresponding to
%		 the cue. If the cue falls in a gap between blocks in a file or between
%		 files, cue_in_file is empty.
%     Usage:
%     ltime = d3wavcues(cues,recdir,prefix)  % convert tag time to UTC time
%     cues = d3wavcues(ltime,recdir,prefix,1) % convert UTC time to tag time
%		% find the dtg file that contains data for a cue:
%		[ltime,fname,cue_in_file] = d3wavcues(cue,recdir,depid,0,'swv');
%
%     markjohnson@bios.au.dk
%		feb 2015 - changed argument order in call
%		june 2021 - added 2nd output argument and improved help
%		december 2023 - added 3rd output argument
%     Licensed as GPL, 2013

ltime = [] ; dv = [] ;
if nargin<3,
   help d3wavcues
   return
end

if nargin<4 || isempty(dirn),
   dirn = 0 ;
end

if nargin<5 || isempty(suffix),
   suffix = 'wav' ;
end

[ct,ref_time,fs,fn,recdir] = d3getcues(recdir,prefix,suffix) ;

if isempty(cues),
	cues = ct(end,2)+ct(end,3)/fs ;
	if dirn==1,
		cues = cues+ref_time ;
	end
end
	
if dirn==1
   ltime = cues-ref_time ;        % convert UTC times to cues
	cues = ltime ;
else
   ltime = ref_time+cues ;        % convert cues to UTC times
end

if nargout>=2,
	k = find(ct(:,2)<cues,1,'last') ;
	if isempty(k), k=1 ; end
	fname = fn{ct(k,1)} ;
end

if nargout==3,
	if ct(k,4)<0,
		cue_in_file = [] ;
	else
		cue_in_file = cues-ct(k,2);
		% get all the preceding wav blocks in this file
		kf = find(ct(1:k-1,1)==ct(k,1) & ct(1:k-1,4)>=0) ;
		if ~isempty(kf),
			cue_in_file = cue_in_file + ct(kf,3)/fs ;
		end
	end
end
return
