function    X = d3builtincal(X,cfg)

%    X = d3builtincal(X,cfg)
%     Apply built-in calibrations to corresponding sensor channels.
%     This is called by d3parseswv and d3getswv to apply calibration info
%     to sensor channels with I2C sensors (pressure, temperature and light).
%
%		Modified 26/07/22 to accommodate multiple sensor channels with built-in cal
%              31/07/22 fixed support of POFFS/TOFFS

if nargin<2,
   help d3builtincal
   return
end

if ~isfield(cfg,'TYPE') || ~isfield(cfg,'CAL')
	fprintf(' No sensor types identified for builtin calibration\n') ;
   return
end

[chnames,descr,chnums] = d3channames(X) ;
if length(chnums)==1,
   chnames = {chnames} ;
   descr = {descr} ;
end
 
if ~iscell(cfg.TYPE),
	cfg.TYPE = {cfg.TYPE} ;
end

if ~iscell(cfg.CAL),
	cfg.CAL = {cfg.CAL} ;
end

% find the sensor types with built-in calibration
psel = struct ;
for k=1:length(cfg.TYPE),
	psel(k).type = deblank(cfg.TYPE{k}.TYPE) ;
	if ~exist(psel(k).type,'file')
		fprintf(' Warning: No calibration method found for sensor type "%s"\n',psel(k).type) ;
		continue
	end
	ch = strfind(descr,psel(k).type) ;
	chs = [] ;
	for kk=1:length(ch),
		if ~isempty(ch{kk}), chs(end+1) = kk ; end
	end
	psel(k).ch = chs ;
	psel(k).sens = deblank(cfg.TYPE{k}.SENS) ;
end

% associate calibration data with sensors
for k=1:length(cfg.CAL),
	% find matching sensor type
	km = strmatch(deblank(cfg.CAL{k}.SENS),{psel.sens}) ;
	if isempty(km), psel(km(1)).cal = [] ; continue, end
	cc = cfg.CAL{k}.CAL ;
	cc(cc=='_') = '-' ;
	psel(km(1)).cal = cc ;
end

% apply calibration
for k=1:length(psel),
	if(strcmp('PRES',psel(k).sens)) ;	% handle pressure data separately
		% get additional pressure sensor data scaling constants
		psel(k).poffs = [] ;
		psel(k).toffs = [] ;
		offsch = isfield(cfg,{'POFFS','TOFFS'}) ;
      if any(offsch),   % convert old offset format to OFFSET field
         offs = cell(1,2) ;
         if offsch(1),
            offs{1} = struct('SENS','PRES','OFFSET',cfg.POFFS) ;
         end
         if offsch(2),
            offs{2} = struct('SENS','TEMP','OFFSET',cfg.POFFS) ;
         end
         cfg.OFFSET = offs ;
		end

      if isfield(cfg,'OFFSET')
         if ~iscell(cfg.OFFSET),
            cfg.OFFSET = {cfg.OFFSET} ;
         end
         for ko=1:length(cfg.OFFSET),
            offs = cfg.OFFSET{ko} ;
		      if strcmp(offs.SENS,'PRES'),
      			psel(k).poffs = str2num(offs.OFFSET) ;      % find the sensor sampling rate
		      end
		      if strcmp(offs.SENS,'TEMP'),
      			psel(k).toffs = str2num(offs.OFFSET) ;      % find the sensor sampling rate
            end
         end
      end

		% identify related channels
		t = [] ; p = [] ; ext = [] ;
		cht = find(startsWith(chnames,'TEMP')) ;
		t = X.x{cht(1)} ;
		chp = find(startsWith(chnames,'PRES')) ;
		p = X.x{chp(1)} ;
		che = find(startsWith(chnames,'PRESEXT')) ;
		if ~isempty(che), ext = X.x{che(1)} ; end
		try
			[d,t] = feval(lower(psel(k).type),psel(k),p,t,ext) ;
		catch
			fprintf(' Calibration failed for sensor type "%s"\n',psel(k).type) ;
		end

		X.x{cht(1)} = t ;
		X.x{chp(1)} = d ;

	else
		try
			X.x{psel(k).ch(1)} = feval(lower(psel(k).type),psel(k),X.x{psel(k).ch(1)}) ;
		catch
			fprintf(' Calibration failed for sensor type "%s"\n',psel(k).type) ;
		end
	end
end

return
