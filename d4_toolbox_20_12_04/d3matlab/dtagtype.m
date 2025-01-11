function 	d = isdtag2(tag)
%
%     d = isdtag2(tag)
%     Returns 1 if the string in tag is a version 2 dtag deployment,
%		0 otherwise.
%
%     markjohnson@bio.au.dk
%		25 March 2023
%		adapted from FHJ 8 April 2014

DTAG=0;
if nargin<2,
   SILENT = 0 ;
end
global TAG_PATHS
if isempty(TAG_PATHS) | ~isfield(TAG_PATHS,'CAL'),
   if SILENT==0,
      fprintf(' No %s file path - use settagpath\n', 'CAL') ;
   end
   return
end

% If DTAG2, CAL file is stored as .MAT
d2suffix = strcat(tag,'cal.mat') ;
d2cal = sprintf('%s/%s',getfield(TAG_PATHS,'CAL'),d2suffix) ;
if exist(d2cal,'file')
   DTAG=2;
   return
end

% If DTAG3, CAL file is stored as .XML
d3suffix = strcat(tag,'cal.xml') ;
d3cal = sprintf('%s/%s',getfield(TAG_PATHS,'CAL'),d3suffix) ;
if exist(d3cal,'file')
    DTAG=3;
    return
end

if SILENT==0,
   disp('No CAL file found when evaluating function dtagtype')
end
return
    
