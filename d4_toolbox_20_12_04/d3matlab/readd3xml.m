function    d3 = readd3xml(xmlfile)
%    d3 = readd3xml(xmlfile)
%     Read a D3 format xml file. This is a front-end
%     for the xml2mat function in the XML4MATv2 toolbox
%     available on the Mathworks user contributed website.
%     Make sure that toolbox is on your matlab path before
%     using this function.
%
%     mark johnson
%     25 march 2012
% 		modified 26/07/22: added support for multiple fields with the same name

d3 = [] ;
warning off MATLAB:REGEXP:deprecated
y=strrep(file2str(xmlfile),'''','''''') ;
if isempty(y),
   return
end

% replace any '-' with '_' in tags because matlab doesn't handle them
kk = find(y=='-') ;
for k=1:length(kk),
   if(rem(sum(y(1:k(1)-1)=='"'),2)==0)
      y(kk(k)) = '_' ;
   end
end

% convert first to MbML compliant string and then onto an m-variable
try
   y=xml2mat(mbmling(y,0));
catch
   fprintf('\n Parsing error in XML file %s. Use an XML editor to repair the file\n', xmlfile) ;
   return
end
y=consolidateall(y);
warning on MATLAB:REGEXP:deprecated

% loop through the structure looking for unneeded arrays
fn = fieldnames(y) ;
d3 = struct ;
n = length(y) ;
if n==1, d3=y; return, end

for k=1:length(fn),
	v = {} ;
	kg = 0 ;
   for kk=1:n,
      s = getfield(y,{kk},fn{k}) ;
		if isstruct(s) && length(s)>1,	% check for multiple entries with same field name
			ss = struct ;
			fns = fieldnames(s(1)) ;
			for kkk=1:length(fns),
				kd = 1 ;
				for ks=1:length(s),
					if ~isempty(s(ks).(fns{kkk})),
						kd = ks ;
					end
				end
				if kd==1,
					ss.(fns{kkk}) = s(1).(fns{kkk}) ;
				else
					ss.(fns{kkk}) = {s(1:kd).(fns{kkk})} ;				
				end
			end
			v{kk} = ss ;
		else
			v{kk} = s ;
		end
      if ~isempty(v{kk}),
         kg = kk ;
      end
   end

	if kg==0, continue, end
   if kg==1,
      d3 = setfield(d3,fn{k},v{1}) ;
   else
      d3 = setfield(d3,fn{k},{v{1:kg}}) ;
   end
end
