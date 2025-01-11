function		cfg = deployment_variance(cfg)

%	cfg = deployment_variance(cfg)
%	WARNING!! This is for expert use only.
%	Edits configuration information from a deployment's xml files
%	to correct errors in the configuration.
%	
%	To use, edit this function for the configuration IDs, fields 
%  and values to be changed and then copy the function to the
%	recording directory renaming it as xmlvariance.m

ID = [6,7] ;		% configuration IDs to change
field = 'FS' ;		% field within each configuration to change
fixval = 50 ;		% value to change the field to

for k=1:length(cfg),
	id = cfg{k}.ID ;
	if iscell(id),
		id = id{1} ;
	end
	if ~ismember(str2num(id),ID), continue, end
	fld = cfg{k}.(field) ;
	if isstruct(fld),
		cfg{k}.(field).(field) = fixval ;
	else
		cfg{k}.(field) = fixval ;
	end
	cfg{k}.variance = 1 ;
end
		