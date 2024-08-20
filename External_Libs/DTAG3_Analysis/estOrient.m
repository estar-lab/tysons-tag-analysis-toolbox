function TagData = estOrient(recdir, TagData, pars)

%% If want to continue to save all the data with p,r,h estimation

% Unpack parameters structure
orientTag = pars.orientTag;
TH = pars.TH;
METHOD = pars.METHOD;
dive_dir = pars.dive_dir;
trc = pars.trc;

% accelTag = TagData(nTagData).accelTag;
% recdir = 'M:\DQ_All_Day_Data';
prefix = TagData.deployName;
df = TagData.desampFreq;
% % sampleFreq = TagData(nTagData).sampleFreq;
isDeg = find(orientTag(:, 3:5) > pi/2);
if isDeg
    TagData.orientTagDeg = orientTag;    
    orientTag = deg2rad(orientTag);
else
    TagData.orientTagRad = orientTag;
end
% [accelAnim, magAnim] = tag2whale(accelTag,magTag,OrientTag,sampleFreq);
% All_Plot(p, Aw, Mw, fs)
[PRH, dmvar01] = prhpredictor(TagData.depth, TagData.accelTag, TagData.sampleFreq, ...
    TH, METHOD, dive_dir);
if ~isempty(PRH); PRH(PRH(:,6) > trc,:) = []; end
if ~isempty(PRH)
    orientTag = [PRH(:,1), PRH(:,1), PRH(:,2), PRH(:,3), PRH(:,4)];
    orientTag(1, 2) = 0; % Sets initial orientation of tag
    TagData.orientTagRadPRH = orientTag;
end
d3savecal(prefix,'OTAB',orientTag);
d3makeprhfile(recdir,prefix,prefix,df)
% TagData = d3makeprhfile_simple(prefix,df, TagData);
% TagData = d3makeprhfile_mod(recdir,prefix,prefix,df, TagData, nTagData);

end