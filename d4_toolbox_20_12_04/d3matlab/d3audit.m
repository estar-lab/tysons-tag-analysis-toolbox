function     RES = d3audit(varargin)
%
%     R = d3audit(tag,tcue,R)          % d2 tags
%     or
%     R = d3audit(recdir,tag,tcue,R)   % d3/4 tags
%     or
%     R = d3audit(recdir,prefix,tag,tcue,R)  % d3 tags
%     or
%     R = d3audit(...,STYPES)          % add STYPES to any of above

%     Audit tool for dtag 3.
%     NOTE: NEW CALLING FORMAT
%     recdir is the deployment directory e.g., 'e:/eg15/eg15_207a'.
%     prefix is the base part of the name of the files to analyse e.g., 
%        if the files have names like 'eg207a001.wav', put prefix='eg207a'.
%     tag is the tag deployment string e.g., 'eg15_207a'
%     tcue is the time in seconds-since-tag-on to start displaying from
%     R is an optional audit structure to edit or augment
%     STYPES is an optional cell array of sound types. Cues with these
%        sound types are displayed in red. The > and < functions allow you
%        to step forward and backward to cues with these types. If STYPES
%        is not given, the > and < functions work on all audit cues.
%
%     Output:
%        R is the audit structure made in the session. Use saveaudit
%        to save this to a file.
%     Examples:
%        1. explicit definition of where the audio files are:
%         d3audit('f:/hp14/hp14_226b','hp14_226b',2000,R);
%        2. use settagpath shortcut method as with dtag2 data:
%         settagpath('AUDIO','f:')
%         d3audit('hp14_226b',2000,R);
%
%     OPERATION
%     Type or click on the display for the following functions:
%     - click on the graph to get the time cue, depth, time-to-last
%       and frequency of an event. Time-to-last is the elapsed time 
%       between the current click point and the point last clicked. 
%       Results display in the matlab command window.
%     - 'f' to go to the next block
%     - 'b' to go to the previous block
%     - 'j' to jump forward by JUMP seconds (JUMP is defined at the top of
%       the function - edit it if a different value is needed).
%     - 'k' to jump forward to the next descent of a dive with max depth of
%       more than DEPTH meters (DEPTH is defined at the top of
%       the function - edit it if a different value is needed).
%     - '>' to go to the next audit markup
%     - '<' to go to the previous audit markup
%     - 'n' to go to the next cue in a cue list (if tcue argument is a vector)
%     - 'm' to go to the previous cue in a cue list (if tcue argument is a vector)
%     - 's' to select the current segment and add it to the audit.
%       You will be prompted to enter a sound type. Enter a single word 
%       and press OK to continue.
%     - 'c' to change the sound type at the mouse position. This will
%       only work if there is an audit markup within +/- 0.1 s of the mouse
%       position. You will be prompted to enter a sound type. Enter a single 
%       word and press OK to continue.
%     - 'l' to select the current mouse position and add it to the 
%       audit as a 0-length event. You will be prompted to enter a sound 
%       type. Enter a single word and press OK to continue.
%     - 'x' to delete the audit entry at the cursor position.
%       If there is no audit entry at the cursor, nothing happens.
%       If there is more than one audit entry overlapping the cursor, one
%       will be deleted (the first one encountered in the audit structure).
%     - 'p' to play the displayed sound segment 
%       through the computer speaker/headphone jack.
%     - 'q' or press the right hand mouse button to finish auditing.
%     - 'a' to report the angle of arrival of the selected segment if the
%           tag has two or more hydrophone channels.
%     - 'w' to save a wav file for the current segment
%     - 'e' to open an echogram worker for the current segment.
%	     The results are saved in a file named with the prefix and starting cue.
%     - 'r' to open an echogram worker to analyse prey responses.
%	     The results are saved in a file named with the prefix and starting cue.
%     - 'h' to change audio channel (1, 2 or both)
%
%     markjohnson@st-andrews.ac.uk
%     modified:
%     18/1/2019 added support for depth data in nc files
%     21/6/2021 added audit dialogs and '<'/'>' functions
%     5/8/2021 added 'r' function

JUMP = 600 ;       % number of seconds to move forward on the 'j' command
DEPTH = 5 ;        % depth in metres to look for in the 'k' command
MAXSURF = 2 ;      % maximum depth when the animal is at the surface. This is
                   % also used by the 'k' command.
NS = 15 ;          % number of seconds to display
TGRID = 3 ;        % xtick on time axis
BL = 512 ;         % specgram (fft) block size
CLIM = [-90 0] ;   % color axis limits in dB for specgram
CH = 0 ;           % which channel to display if multichannel audio (0==both)
THRESH = 0 ;       % click detector threshold, 0 to disable
volume = 20 ;      % amplification factor for audio output - often needed to
                   % hear weak signals (if volume>1, loud transients will
                   % be clipped when playing the sound cut
SOUND_FH = 0 ;     % high-pass filter for sound playback - 0 for no filter
SOUND_FL = 0 ;     % low-pass filter for sound playback - 0 for no filter
AOA_FH = 2e3 ;     % high-pass filter for angle-of-arrival measurement
AOA_SCF = 1500/0.025 ;     % sound speed divided by hydrophones spacing
MAXYONCLICKDISPLAY = 0.01 ;
CMAP = jet ;
tempdir = 'd3audit' ;

%     R = d3audit(tag,tcue,R)          % d2 tag
%     or
%     R = d3audit(recdir,tag,tcue,R)   % d3 tag
%     or
%     R = d3audit(recdir,prefix,tag,tcue,R)  % d3 tag

tcue = [] ; RES = [] ; recdir = [] ; prefix = [] ; STYPES = {} ;

if nargin<6,
   [varargin{nargin+1:6}] = deal([]) ;
end

if ischar(varargin{2}), % d3audit(recdir,prefix,...)
   recdir = varargin{1} ;
   prefix = varargin{2} ;
   nxtarg = 2 + ischar(varargin{3}) ;
else     % d3audit(tag,...)
   nxtarg = 1 ;   
end

tag = varargin{nxtarg} ;
tcue = varargin{nxtarg+1} ;
RES = varargin{nxtarg+2} ;
STYPES = varargin{nxtarg+3} ;

if ischar(STYPES),
   STYPES = {STYPES} ;
end

if isempty(recdir),
   [recdir,prefix] = tag2recdirprefix(tag) ;
end

if isempty(tcue),
   tcue = 0 ;
end

if isempty(RES),
   RES.cue = [] ;
   RES.comment = [] ;
   RES.stype = {} ;
else
   [r,I] = sort(RES.cue(:,1)) ;
   RES.cue = RES.cue(I,:) ;
   RES.stype = {RES.stype{I}} ;
end

tempdir = [tempdir '/' prefix] ;
if ~exist(tempdir,'dir')
   mkdir(tempdir) ;
end

% high-pass filter frequencies (Hz) for click detector 
switch prefix(1:2),
   case {'hp','pp'}      % for harbour porpoise use:
      FH = 70000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
      NS = 5 ;             % only read 5s at a time
      TGRID = 0.5 ;        % xtick on time axis
   case 'ch',      % for hector's dolphin use:
      FH = 70000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
      NS = 5 ;             % only read 5s at a time
      TGRID = 0.5 ;        % xtick on time axis
  case 'zc',      % for ziphius use:
      FH = 20000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
   case 'md',      % for mesoplodon use:
      FH = 20000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
   case 'pw',      % for pilot whale use:
      FH = 10000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
   case 'sw',      % for sperm whale use:
      FH = 3000 ;       
      TC = 2.5e-3 ;           % power averaging time constant in seconds
   otherwise,      % for others use:
      FH = 5000 ;       
      TC = 0.5e-3 ;           % power averaging time constant in seconds
end

k = loadprh(tag,0,'p','P','fs') ;           % read p and fs from the sensor file
if k==0,
   fprintf('Unable to find a PRH file - continuing without\n') ;
   p = [] ; fs = [] ;
end

if exist('P','var'),
   [p,fs] = sens2var(P) ;
end

% check sampling rate
[x,afs] = d3wavread(tcue(1)+[0 0.01],recdir,prefix) ;
if isempty(x), return, end

if SOUND_FH > 0,
   [bs as] = butter(6,SOUND_FH/(afs/2),'high') ;
elseif SOUND_FL > 0,
   [bs as] = butter(6,SOUND_FL/(afs/2)) ;
else
   bs = [] ;
end

if afs>192e3,
   SOUND_DF = round(afs/96e3) ;
else
   SOUND_DF = -1 ;
end

% high pass filter for envelope
[bh ah] = cheby1(6,0.5,FH/afs*2,'high') ;
% envelope smoothing filter
pp = 1/TC/afs ;

% angle-of-arrival filter
[baoa aaoa] = butter(4,AOA_FH/(afs/2),'high') ;

current = [0 0] ;
figure(1),clf,zoom off
if ~isempty(p),
   kb = 1:floor(NS*fs) ;
   AXm = axes('position',[0.11,0.76,0.78,0.15]) ;
   AXc = axes('position',[0.11,0.70,0.78,0.05]) ;
   AXs = axes('position',[0.11,0.34,0.78,0.35]) ;
   AXp = axes('position',[0.11,0.11,0.78,0.2]) ;
else
   AXm = axes('position',[0.11,0.60,0.78,0.31]) ;
   AXc = axes('position',[0.11,0.52,0.78,0.07]) ;
   AXs = axes('position',[0.11,0.11,0.78,0.38]) ;
end

bc = get(gcf,'Color') ;
set(AXc,'XLim',[0 1],'YLim',[0 1]) ;
set(AXc,'Box','off','XTick',[],'YTick',[],'XColor',bc,'YColor',bc,'Color',bc) ;
cleanh = [] ;
kcue = 1 ;
TCUE = tcue ;
tcue = tcue(1)-NS/2 ;

while 1,
   [x,afs] = d3wavread(tcue+[0 NS],recdir,prefix) ;
   if isempty(x), return, end    
   x = x-repmat(nanmean(x),size(x,1),1) ;
   x(isnan(x)) = 0 ;
   CH = max(min(CH,size(x,2)),0) ;
   [B F T] = specgram(x(:,max(CH,1)),BL,afs,hamming(BL),BL/2) ;
   if CH==0,
      xx = sum(filter(pp,[1 -(1-pp)],abs(filter(bh,ah,x))),2) ;
   else
      xx = filter(pp,[1 -(1-pp)],abs(filter(bh,ah,x(:,CH)))) ;
   end
   kk = 1:5:length(xx) ;
   axes(AXm), cla, plot(tcue+kk/afs,xx(kk),'k') ; grid
   set(AXm,'XAxisLocation','top') ;
   yl = get(gca,'YLim') ;
   yl(2) = min([yl(2) MAXYONCLICKDISPLAY]) ;
   axis([tcue tcue+NS yl]) ;
   xticks = floor(tcue):TGRID:ceil(tcue+NS) ;
   set(gca,'XTick',xticks) ;
   if CH==0,
      ctxt = 'CH=sum' ;
   else
      ctxt = sprintf('CH=%d',CH) ;
   end
   text(tcue+0.01*NS,yl(2)*0.9,ctxt) ;
   %if size(RES.cue,1)>0,
   %   kres = find(RES.cue(:,1)>tcue & RES.cue(:,1)<tcue+NS) ;
   %   if isempty(kres),
   %      title('No audit cues in interval')
   %   elseif length(kres)==1,
   %      title(sprintf('Cue %d of %d',kres,size(RES.cue,1))) ;
   %   else
   %      title(sprintf('Cue %d-%d of %d',kres(1),kres(end),size(RES.cue,1))) ;
   %   end
   %else
   %   title('No audit cues')
   %end
   plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;

   if ~isempty(p),
      ks = kb + round(tcue*fs) ;
      axes(AXp),cla,plot(ks/fs,p(ks)), grid
   	set(gca,'YDir','reverse','XLim',[tcue tcue+max(T)],'XTick',xticks) ;
      xlabel('Time, s')
      ylabel('Depth, m')
   end
   
   BB = adjust2Axis(20*log10(abs(B))) ;
   axes(AXs), imagesc(tcue+T,F/1000,BB,CLIM) ;
   colormap(CMAP) ;
   axis xy, grid ;
   if ~isempty(p),
      set(AXs,'XTickLabel',[]) ;
   else
      xlabel('Time, s')
   end
   ylabel('Frequency, kHz')
   set(gca,'XLim',[tcue tcue+max(T)],'XTick',xticks) ;
   hold on
   hhh = plot([0 0],0.8*afs/2000*[1 1],'k*-') ;    % plot cursor
   hold off

   done = 0 ;
   while done == 0,
      axes(AXs) ; 
      [gx,gy,button] = ginput1(gca) ;
      if isempty(gx), continue, end
      switch button,
         %case {3,'q'}
         case 'q'
         save([tempdir '/_RECOVER'],'RES') ;
			%clc
         return

         case 's'
         ss = inputdlg('Enter sound type','d3audit',1,{''}) ;
         if ~isempty(ss),
            cc = sort(current) ;
            RES.cue = [RES.cue;[cc(1) diff(cc)]] ;
            RES.stype{size(RES.cue,1)} = ss{1} ;
            plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
         end
         
         case 'r'    % analyse an extract for prey responses
         kres = [] ;
         if ~isempty(RES.cue) & ~isempty(STYPES),   % look for an analysable cue
            kres = find(gx>=RES.cue(:,1)-0.1 & gx<sum(RES.cue')'+0.1) ;
            if ~isempty(kres) % find first overlapping cue that is a member of STYPES
               rm = strcmp({RES.stype{kres}},STYPES{1}) ;
               kres = kres(find(rm,1)) ;
            end
         end
         if ~isempty(kres),
            dcues = [floor(RES.cue(kres,1)) ceil(sum(RES.cue(kres,:)))] ;
            doclickx(recdir,prefix,STYPES{1},dcues,CH,tempdir) ;
            RES = add_audit(RES,[mean(dcues),0],'&done') ;
            plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
         else
            fprintf(' No analysable audit cue found. Use s to label section first\n') ;
         end
         
         case 'e'    % do echogram analysis of an interval
         cc = sort(current) ;
         if any(isnan(cc)) | cc(2)-cc(1)==0,
            continue
         end
         if cc(2)-cc(1)>60,
            fprintf('Warning: truncating extract to 60s\n') ;
            cc(2) = cc(1)+60 ;
         end
         dcues = [floor(cc(1)) ceil(cc(2))] ;
         RES.cue(end+1,1:2) = [dcues(1) diff(dcues)] ;
         RES.stype{size(RES.cue,1)} = 'ec' ;
         epts = doclickx(recdir,prefix,'ec',dcues,CH,tempdir) ;
         if ~isempty(epts),
            RES = add_audit(RES,epts) ;
            plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
         end
         
         case 'w'    % save an interval to a wav file
         cc = sort(current) ;
         if cc(2)-cc(1)>100,
            fprintf('Warning: truncating extract to 100s - use d3wavcopy for longer extracts\n') ;
            cc(2) = cc(1)+100 ;
         end
         dcues = [floor(cc(1)) ceil(cc(2))] ;
         RES.cue(end+1,1:2) = [dcues(1) diff(dcues)] ;
         RES.stype{size(RES.cue,1)} = 'ex' ;
         fn = sprintf([tempdir '/%s_ex%d.wav'],tag,dcues(1)) ;
         d3wavcopy(recdir,prefix,dcues,fn) ;
         fprintf(' done\n');
         
         case 'h'
         CH = CH+1 ;
         if CH>size(x,2),
            CH = 0 ;
         end
         done = 1 ;
         
         case 'a',
         if size(x,2)>1,
            cc = sort(current)-tcue ;
            kcc = round(afs*cc(1)):round(afs*cc(2)) ;
            xf = filter(baoa,aaoa,x(kcc,:)) ;
            [aa,qq] = xc_tdoa(xf(:,1),xf(:,2)) ;
            fprintf(' Angle of arrival %3.1f, quality %1.2f\n',asin(aa*AOA_SCF/afs)*180/pi,qq) ;
         end

         case 'l',
         ss = inputdlg('Enter sound type','d3audit',1,{''}) ;
         if ~isempty(ss),
            cc = sort(current) ;
            RES.cue = [RES.cue;[gx 0]] ;
            RES.stype{size(RES.cue,1)} = ss{1} ;
            plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
         end

         case 'x',
         if ~isempty(RES.cue),
            kres = min(find(gx>=RES.cue(:,1)-0.1 & gx<sum(RES.cue')'+0.1)) ;
            if ~isempty(kres),
               kkeep = setxor(1:size(RES.cue,1),kres) ;
               RES.cue = RES.cue(kkeep,:) ;
               RES.stype = {RES.stype{kkeep}} ;
               plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
            else
               fprintf(' No saved cue at cursor\n') ;
            end
         end
         
         case 'c',
         if ~isempty(RES.cue),
            kres = min(find(gx>=RES.cue(:,1)-0.1 & gx<sum(RES.cue')'+0.1)) ;
            if ~isempty(kres),
               ss = inputdlg('Enter new sound type','d3audit',1,{RES.stype{kres}}) ;
               if ~isempty(ss),
                  RES.stype{kres} = ss{1} ;
                  plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
               end
            else
               fprintf(' No saved cue at cursor\n') ;
            end
         end
         
         case '1'
         if ~isempty(RES.cue),
            kres = find(RES.cue(:,1)<tcue+NS & sum(RES.cue,2)>tcue & strcmp(STYPES{1},RES.stype)') ;
            if ~isempty(kres),
               [mm,km] = min(abs(RES.cue(kres,1)-gx)) ;
               RES.cue(kres(km),1:2) = [gx RES.cue(kres(km),2)+RES.cue(kres(km),1)-gx] ;
               plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
            else
               fprintf(' No eligible cue at cursor\n') ;
            end
         end
         
         case '2'
         if ~isempty(RES.cue),
            kres = find(RES.cue(:,1)<tcue+NS & sum(RES.cue,2)>tcue & strcmp(STYPES{1},RES.stype)') ;
            if ~isempty(kres),
               [mm,km] = min(abs(sum(RES.cue(kres,:),2)-gx)) ;
               RES.cue(kres(km),2) = gx-RES.cue(kres(km),1) ;
               plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
            else
               fprintf(' No eligible cue at cursor\n') ;
            end
         end

         case 'f'
            tcue = tcue+floor(NS)-0.5 ;
            done = 1 ;
         
         case 'j'
            tcue = tcue+JUMP ;
            done = 1 ;
         
         case 'k'
            if ~isempty(p),
               ks = round(tcue*fs) ;
               if p(ks)>DEPTH,
                  ks = ks+find(p(ks:end)<MAXSURF,1) ;
               end
               kr = ks+find(p(ks:end)>DEPTH,1) ;
               if isempty(kr),
                  fprintf('No more dives >%3.1fm beyond this cue\n',DEPTH)
               else
                  tcue = kr/fs ;
                  done = 1 ;
               end
            end
            
         case 'b'
            tcue = max([0 tcue-NS+0.5]) ;
            done = 1 ;

         case '>'
           kres = [] ;
           if ~isempty(STYPES), % find next cue that is a member of STYPES
              for k=1:length(STYPES),
                 mtch = strcmp(STYPES{k},RES.stype) ;
                 kres = [kres;find(RES.cue(:,1)>tcue+NS & mtch(:),1)] ;
              end
              kres = min(kres) ;
           elseif ~isempty(RES.cue),   % otherwise find the next cue
              kres = find(RES.cue(:,1)>tcue+NS,1) ;
           end
           if ~isempty(kres),
              tcue = max(RES.cue(kres,1)-min(NS/2,2),0) ;
              done = 1 ;
           end
           
         case '<'
           kres = [] ;
           if ~isempty(STYPES), % find next cue that is a member of STYPES
              for k=1:length(STYPES),
                 mtch = strcmp(STYPES{k},RES.stype) ;
                 kres = [kres;find(RES.cue(:,1)+RES.cue(:,2)<tcue & mtch(:),1,'last')] ;
              end
              kres = min(kres) ;
           elseif ~isempty(RES.cue),   % otherwise find the next cue
              kres = find(RES.cue(:,1)+RES.cue(:,2)<tcue,1,'last') ;
           end
           if ~isempty(kres),
              tcue = max(RES.cue(kres,1)-min(NS/2,2),0) ;
              done = 1 ;
           end
           
         case 'n'
            if kcue>=length(TCUE),
               save d3audit_RECOVER RES
               return
            end
            kcue = kcue+1 ;
            tcue = TCUE(kcue)-NS/2 ;
            fprintf(' Moving to cue %d of %d\n',kcue,length(TCUE)) ;
            done = 1 ;

         case 'm'
            kcue = max(kcue-1,1) ;
            tcue = TCUE(kcue)-NS/2 ;
            fprintf(' Moving to cue %d of %d\n',kcue,length(TCUE)) ;
            done = 1 ;

         case 'p'
            chk = min(size(x,2),2) ;
            if ~isempty(bs),
               xf = filter(bs,as,x(:,1:chk)) ;        
               if SOUND_DF<0,
                  sound(volume*xf,-afs/SOUND_DF,16) ;
               else
                  sound(volume*decdc(xf,SOUND_DF),afs/SOUND_DF,16) ;
               end
            else
               if SOUND_DF<0,
                  sound(volume*x(:,1:chk),-afs/SOUND_DF,16) ;
               else
                  sound(volume*decdc(x(:,1:chk),SOUND_DF),afs/SOUND_DF,16) ;
               end
            end

         case 1
         if gy<0 | gx<tcue | gx>tcue+NS
            fprintf('Invalid click: commands are f b s l p x q\n')
         else
            current = [current(2) gx] ;
            set(hhh,'XData',current) ;
            if ~isempty(p),
               fprintf(' -> %6.1f\t\tdiff to last = %6.1f\t\tp = %6.1f\t\tfreq. = %4.2f kHz\n', ...
                 gx,diff(current),p(round(gx*fs)),gy) ;
			   else
               fprintf(' -> %6.1f\t\tdiff to last = %6.1f\t\tfreq. = %4.2f kHz\n', ...
                 gx,diff(current),gy) ;
	         end
         end
         
         case 3
            current = [current(2) gx] ;
            set(hhh,'XData',current) ;
            cc = sort(current) ;
            RES.cue = [RES.cue;[cc(1) diff(cc)]] ;
            RES.stype{size(RES.cue,1)} = 'bz' ;
            plotRES(AXc,RES,[tcue tcue+NS],STYPES,tempdir) ;
      end
   end
end


function plotRES(AXc,RES,XLIMS,STYPES,tempdir)
%
save([tempdir '/_RECOVER'],'RES') ;
axes(AXc)
cla
hold on
if ~isempty(RES.cue),
   kk = find(sum(RES.cue')'>XLIMS(1) & RES.cue(:,1)<=XLIMS(2)) ;
   for k=kk',
      if ~isempty(RES.stype{k}) && RES.stype{k}(1)=='&',
         plot(RES.cue(k,1),0.2*1,'g*') ;
      else
         hl = plot(RES.cue(k,1)+[0;RES.cue(k,2)],0.2*[1;1],'k*-') ;
         ht = text(min(XLIMS(2),max(XLIMS(1),RES.cue(k,1)+0.1)),0.6,RES.stype{k},'FontSize',10) ;
         if ~isempty(STYPES) & any(strcmp(RES.stype{k},STYPES)),
            set(hl,'Color','r','MarkerEdgeColor','r') ;
            set(ht,'Color','r') ;
         end
      end
   end
end

hold off
set(AXc,'XLim',XLIMS,'YLim',[0 1]) ;
bc = get(gcf,'Color') ;
set(AXc,'Box','off','XTick',[],'YTick',[],'XColor',bc,'YColor',bc,'Color',bc) ;
return


function	epts = doclickx(recdir,prefix,ss,cues,ch,tempdir)
%
if ~exist('sortclicks'),
   fprintf(' Echogram function is not supported in this version\n') ;
   return
end

fn = sprintf([tempdir '/%s_%s%d_%d'],prefix,ss,cues(1),cues(2)) ;
if exist([fn,'.mat'],'file'), % read in existing analysis file
   [cl,x,fs,epts,rstr] = sortclicks(fn) ;
else
   [x,fs] = d3wavread(cues,recdir,prefix) ;
   if size(x,2)>1 & ch>0,
      x = x(:,ch) ;
   end
   [cl,x,fs,epts,rstr] = sortclicks(x,fs,[],prefix(1:2)) ;
end

save(fn,'cl','x','fs','rstr') ;
if ~isempty(epts) & isstruct(epts),
   epts.cue(:,1) = epts.cue(:,1)+cues(1) ;
end
return
