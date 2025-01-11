function		d3 = getd3xml(fname)

%		d3 = getd3xml(fname)
%		Wrapper function around readd3xml to allow variances to the xml
%		configurations.
%

k = find(ismember(fname,'/\'),1,'last') ;
if ~isempty(k),
   recdir = fname(1:k) ;
   fname = fname(k+1:end) ;
else
   recdir = [] ;
end

d3 = readd3xml([recdir fname '.xml']) ;
if isempty(d3),
   return
end

% check for an xml variance file in the recording directory
vfile = 'xmlvariance' ;
if exist([recdir vfile '.m'],'file'),
	thisdir = pwd ;
	cd(recdir)
	d3.CFG = feval(vfile,d3.CFG) ;
	cd(thisdir) ;
end
