function     RES = wavaudit(fname,tcue,RES)

%     R = wavaudit(fname,tcue)
%		or
%     R = wavaudit(fname,tcue,R)
%
%     Simple audit tool for sound recordings that are stored in a single wav file.
%		Inputs:
%     fname is the full file name including directory e.g., 'e:/eg15/eg15_207a001.wav'.
%     tcue is the time in seconds-since-tag-on to start working from.
%     R is an optional audit structure to edit or augment
%
%     Output:
%        R is the audit structure made in the session. Use saveaudit
%        to save this to a comma-separated text file.
%
%     OPERATION
%     Type or click on the display for the following functions:
%     - type 'f' to go to the next block
%     - type 'b' to go to the previous block
%     - click on the graph to get the time cue, depth, time-to-last
%       and frequency of an event. Time-to-last is the elapsed time 
%       between the current click point and the point last clicked. 
%       Results display in the matlab command window.
%     - type 's' to select the current segment for markup.
%       You will be prompted to enter a sound type on the matlab command
%       window. Enter a single word and type return when complete.
%     - type 'l' to select the current cursor position and add it to the 
%       audit as a 0-length event. You will be prompted to enter a sound 
%       type on the matlab command window. Enter a single word and type 
%       return when complete.
%     - type 'x' to delete the audit entry at the cursor position.
%       If there is no audit entry at the cursor, nothing happens.
%       If there is more than one audit entry overlapping the cursor, one
%       will be deleted (the first one encountered in the audit structure).
%     - type 'p' to play the displayed sound segment 
%       through the computer speaker/headphone jack.
%     - type 'q' or press the right hand mouse button to finish auditing.
%     - type 'w' to save a wav file for the current selected segment
%
%		NOTE: there are a number of parameters in the function that can be
%		edited to improve performance for particular sound types.
%
%     markjohnson@st-andrews.ac.uk
%     last modified June 2019

NS = 15 ;          % number of seconds to display
BL = 512 ;         % specgram (fft) block size
CLIM = [-90 0] ;   % color axis limits in dB for specgram
CH = 1 ;           % which channel to display if multichannel audio
volume = 20 ;      % amplification factor for audio output - often needed to
                   % hear weak signals (if volume>1, loud transients will
                   % be clipped when playing the sound cut
SOUND_FH = 0 ;     % high-pass filter for sound playback - 0 for no filter
SOUND_FL = 0 ;     % low-pass filter for sound playback - 0 for no filter
MAXYONTRANSDISPLAY = 0.01 ;
FH = 5000 ;        % high-pass filter for transient display
TC = 0.5e-3 ;      % power averaging time constant in seconds

if nargin<2,
	help wavaudit
	return
end

if nargin<3,
	RES = [] ;
end

if isempty(RES),
   RES.cue = [] ;
   RES.comment = [] ;
   RES.stype = {} ;
end

k = find(fname=='.',1,'last') ;
if isempty(k),
	fbase = fname ;
	fname = [fname,'.wav'] ;
else
	fbase = fname(1:k-1) ;
end
	
% check sampling rate
info = audioinfo(fname) ;
afs = info.SampleRate ;
nmax = info.TotalSamples ;

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

current = [0 0] ;
figure(1),clf
AXm = axes('position',[0.11,0.60,0.78,0.34]) ;
AXc = axes('position',[0.11,0.52,0.78,0.07]) ;
AXs = axes('position',[0.11,0.11,0.78,0.38]) ;

bc = get(gcf,'Color') ;
set(AXc,'XLim',[0 1],'YLim',[0 1]) ;
set(AXc,'Box','off','XTick',[],'YTick',[],'XColor',bc,'YColor',bc,'Color',bc) ;
cleanh = [] ;
kcue = 1 ;
TCUE = tcue ;
tcue = tcue(1) ;

while 1,
	[x,afs] = audioread(fname,min(max(afs*(tcue+[0 NS]),1),nmax)) ;
   if isempty(x), return, end    
   x = x-repmat(nanmean(x),size(x,1),1) ;
   x(isnan(x)) = 0 ;
   [B,F,T] = spectrogram(x(:,CH),BL,BL/2,BL,afs) ;
   xx = filter(pp,[1 -(1-pp)],abs(filter(bh,ah,x(:,CH)))) ;

   kk = 1:5:length(xx) ;
   axes(AXm), plot(tcue+kk/afs,xx(kk),'k') ; grid
   set(AXm,'XAxisLocation','top') ;
   yl = get(gca,'YLim') ;
   yl(2) = min([yl(2) MAXYONTRANSDISPLAY]) ;
   axis([tcue tcue+NS yl]) ;
   
   plotRES(AXc,RES,[tcue tcue+NS]) ;
   
   BB = adjust2Axis(20*log10(abs(B))) ;
   axes(AXs), imagesc(tcue+T,F/1000,BB,CLIM) ;
   axis xy, grid ;
   xlabel('Time, s')
   ylabel('Frequency, kHz')
   hold on
   hhh = plot([0 0],0.8*afs/2000*[1 1],'k*-') ;    % plot cursor
   hold off

   done = 0 ;
   while done == 0,
      axes(AXs) ; pause(0) ;
      [gx gy button] = ginput(1) ;
		if isempty(gx), continue, end
      if button>='A',
         button = lower(setstr(button)) ;
      end
      switch button,
         case {3,'q'}
         save wavaudit_RECOVER RES
         return

         case 's'
         ss = input(' Enter comment... ','s') ;
         cc = sort(current) ;
         RES.cue = [RES.cue;[cc(1) diff(cc)]] ;
         RES.stype{size(RES.cue,1)} = ss ;
         save wavaudit_RECOVER RES
         plotRES(AXc,RES,[tcue tcue+NS]) ;

         case 'w'
         cc = sort(current) ;
         RES.cue = [RES.cue;[floor(cc(1)) ceil(cc(2))-floor(cc(1))]] ;
         RES.stype{size(RES.cue,1)} = 'ex' ;
         fn = sprintf('%s_ex%d.wav',fbase,floor(cc(1))) ;
         wavcopy(fname,[floor(cc(1)) ceil(cc(2))],fn) ;
         fprintf(' done\n');

         case 'l',
         ss = input(' Enter comment... ','s') ;
         RES.cue = [RES.cue;[gx 0]] ;
         RES.stype{size(RES.cue,1)} = ss ;
         save wavaudit_RECOVER RES
         plotRES(AXc,RES,[tcue tcue+NS]) ;

         case 'x',
         kres = min(find(gx>=RES.cue(:,1)-0.1 & gx<sum(RES.cue')'+0.1)) ;
         if ~isempty(kres),
            kkeep = setxor(1:size(RES.cue,1),kres) ;
            RES.cue = RES.cue(kkeep,:) ;
            RES.stype = {RES.stype{kkeep}} ;
            plotRES(AXc,RES,[tcue tcue+NS]) ;
         else
            fprintf(' No saved cue at cursor\n') ;
         end

         case 'f'
            tcue = tcue+floor(NS)-0.5 ;
            done = 1 ;

         case 'b'
            tcue = max([0 tcue-NS+0.5]) ;
            done = 1 ;

         case 'n'
            kcue = min(kcue+1,length(TCUE)) 
            tcue = TCUE(kcue) ;
            done = 1 ;

         case 'm'
            kcue = max(kcue-1,1) ;
            tcue = TCUE(kcue) ;
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
            fprintf(' -> %6.1f\t\tdiff to last = %6.1f\t\tfreq. = %4.2f kHz\n', ...
                 gx,diff(current),gy) ;
         end
      end
   end
end
return


function plotRES(AXc,RES,XLIMS) ;
      
axes(AXc)
if ~isempty(RES.cue),
   kk = find(sum(RES.cue')'>XLIMS(1) & RES.cue(:,1)<=XLIMS(2)) ;
   if ~isempty(kk),
      plot([RES.cue(kk,1) sum(RES.cue(kk,:)')']',0.2*ones(2,length(kk)),'k*-') ;
      for k=kk',
         text(max([XLIMS(1) RES.cue(k,1)+0.1]),0.6,RES.stype{k},'FontSize',10) ;
      end
   else
      plot(0,0,'k*-') ;
   end
else
   plot(0,0,'k*-') ;
end

set(AXc,'XLim',XLIMS,'YLim',[0 1]) ;
bc = get(gcf,'Color') ;
set(AXc,'Box','off','XTick',[],'YTick',[],'XColor',bc,'YColor',bc,'Color',bc) ;
return
