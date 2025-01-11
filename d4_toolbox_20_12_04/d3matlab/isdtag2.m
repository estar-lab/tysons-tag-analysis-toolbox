function 	d = isdtag2(tag)
%
%     d = isdtag2(tag)
%     Returns 1 if the string in tag is a version 2 dtag deployment,
%		0 otherwise. To detect dtag 2 deployments, the CAL directory
%		must be set using settagpath.m
%
%     markjohnson@bio.au.dk
%		25 March 2023
%		adapted from FHJ 8 April 2014

d = 0 ;

global TAG_PATHS
if isempty(TAG_PATHS) | ~isfield(TAG_PATHS,'CAL'),
   return
end

% If DTAG2, CAL file is stored as .MAT
d2suffix = strcat(tag,'cal.mat') ;
d2cal = sprintf('%s/%s',getfield(TAG_PATHS,'CAL'),d2suffix) ;
if exist(d2cal,'file')
   d = 1 ;
end
