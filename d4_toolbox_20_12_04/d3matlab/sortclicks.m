function    [cl,x,fs,anno,rstr] = sortclicks(x,varargin)
%
%     [cl,x,fs,anno,rstr] = sortclicks(fname)
%        Read in audio data from wav file and generate a click list 
%			and then allow interactive sorting
%     cl = sortclicks(fname,cl)
%        Sort an existing click list
%     cl = sortclicks(x,fs)
%        Work directly with audio data
%     cl = sortclicks(x,fs,cl)
%        Work directly with audio data
%     cl = sortclicks(...,opts)
%        Pass an options structure
%
%	  Valid commands in the figure window are:
%		z  zoom in at the cursor
%     x  zoom out at the cursor
%     a  zoom completely out
%		d	delete the nearest click
%     w  remove clicks in the current segment by placing a threshold in the
%        lower plot (requires a second click in the lower plot). Clicks
%        with level below the threshold will be removed.
%     t  add clicks in the current segment by placing a threshold in the
%        lower plot (requires a second click in the lower plot)
%     s  select the click at the cursor
%		left-button-drag-box		delete all clicks in the drawn box
%     right button click   add clicks between existing clicks
%     +  increase relative threshold by 0.1
%     -  decrease relative threshold by 0.1
%     u  undo last click delete
%     e  show echogram
%     F  move forward keeping same zoom level
%     B  move backward at same zoom level
%     f  go to next ICI step change
%     b  go to previous ICI step change
%		y	try to add clicks at all positive ICI step changes in window
%     L  switch between linear and log level display
%     l  add an annotation
%     R  remove all clicks in the current segment
%     1  move the start-of-buzz marker to the current position
%     2  move the end-of-buzz marker to the current position
%     3  reset the buzz markers to the automatic detection
%		q  quit
%
%		markjohnson@bio.au.dk
%		last modified: 6/4/23 added noise reduction option to reject sensor sampling interference

OPTS.sw.fd = [5e3 40e3] ;
OPTS.sw.blank = 5e-3 ;
OPTS.md.fd = [2.5e3 20e3] ;
OPTS.md.fe = 25e3 ;
OPTS.md.df = 4 ;
OPTS.md.blank = 2.5e-3 ;
OPTS.pw.fd = [10e3 65e3] ;
OPTS.pp.fd = [200e3 230e3] ;  % for harbour porpoise
OPTS.pp.fe = [100e3 230e3] ; 
OPTS.pp.blank = 0.3e-3 ;
OPTS.pp.bzthr = 0.013 ;
OPTS.pp.bzgap = 1 ;
OPTS.ch.fd = [180e3 230e3] ;  % for harbour porpoise
OPTS.ch.fe = [100e3 230e3] ; 
OPTS.ch.blank = 0.3e-3 ;
OPTS.ch.bzthr = 0.013 ;
OPTS.ch.bzgap = 1 ;
OPTS.hp.fd = [200e3 230e3] ;  % for harbour porpoise
OPTS.hp.fe = [100e3 230e3] ;
OPTS.hp.blank = 1e-3 ;
OPTS.hp.bzthr = 0.013 ;
OPTS.hp.bzgap = 1 ;
OPTS.hp.nr = 1 ;
OPTS.mb.fd = [2.5e3 30e3] ;  % for Sowerby's
OPTS.mb.fe = [50e3 120e3] ;  % for Sowerby's
OPTS.mb.blank = 2e-3 ;
OPTS.zc.fd = [30e3 90e3] ;  % for Cuvier's
OPTS.zc.blank = 2e-3 ;
OPTS.zc.df = 4 ;
OPTS.def.fd = [20e3 70e3] ;
OPTS.def.blank = 3e-3 ;
OPTS.def.df = 8 ;
OPTS.def.ch = 0 ;         % use all channels

RTHR = 0.7 ;            	% initial relative threshold for click detection
PICI_THR = [0.1 0.25] ;
PICI_SWITCH = 0.02 ;
ECHOGRAM_EXTENT = 0.005 ;  % default two-way-travel-time limit of echograms
FIGN = 2 ;						% which figure number to use
LOGDISP = 1 ;
MINDB = -90 ;

INOPTS = struct ;
cl = [] ;
NOPRE = 0 ;
pref = [] ;

if ischar(x),
	k = find(ismember(x,'\/'),1,'last') ;
	if isempty(k),
		pref = x(1:2) ;
	else
		pref = x(k+(1:2)) ;
   end
   if exist([x,'.mat'],'file'),
      load(x) ;
      NOPRE = 1 ;
   else
   	[x,fs]=audioread(x);
   end
	nxt = 1 ;
else
	if nargin<2,
		help sortclicks
		return
	end
	fs = varargin{1} ;
	nxt = 2 ;
end

if ~exist('cl','var'),
   if nargin>nxt,
      cl = varargin{nxt} ;
   else
      cl = [] ;
   end
end

if nargin>nxt+1,
	INOPTS = varargin{nxt+1} ;
end

if ischar(INOPTS),
	OPTS = resolveopts(INOPTS,OPTS) ;
else
	if ~isstruct(INOPTS) && ~isempty(INOPTS),
		INOPTS = setfield([],'fd',INOPTS) ;
   end
	OPTS = resolveopts(pref,OPTS,INOPTS) ;
end

if isfield(OPTS,'NOPRE'),
   NOPRE = OPTS.NOPRE ;
end

if NOPRE,
   xe = x(:,1) ;
   x = x(:,max(2,size(x,2))) ;
else
   if ~isempty(OPTS.ch) && OPTS.ch>0,
      x = x(:,max(min(OPTS.ch,size(x,2)),1)) ;
   end
   [x,xe,fs]=preproc(x,fs,OPTS) ;
end

if isempty(cl),
   cl = getclicksr(x,fs,OPTS) ;
end

if size(cl,2)<2,
   [X,cl] = extract_cues(x,fs,cl-0.2e-3,OPTS.blank+0.2e-3) ;
   cl(:,2) = max(X)' ;
end

if size(cl,2)<3,
   cl(:,3) = 0 ;
end

if ~exist('rstr','var'),
   rstr = [] ;
end

opts.blank = OPTS.blank ;
opts.fh=[] ; 
opts.env = 1 ;
L = 20*log10(cl(:,2)) ;
CAX = max(L)+[-60 0] ;
done = 0 ;
figure(FIGN),clf
h2 = subplot(212); grid on, hold off
if LOGDISP==1,
   d1 = plot((1:length(x))'/fs,20*log10(x),'k');
   set(d1,'Color',0.6*[1 1 1])
   hold on
   d2 = plot(cl(:,1),20*log10(cl(:,2)),'r.') ;
   ylabel('Magnitude (dB)')
else
   d1 = plot((1:length(x))'/fs,x,'k');
   set(d1,'Color',0.6*[1 1 1])
   hold on
   d2 = plot(cl(:,1),cl(:,2),'r.') ;
   ylabel('Magnitude (U)')
end
xlabel('Time into extract (s)')
set(gca,'UserData',2)
h1 = subplot(211) ;
xlim = [0 length(x)/fs] ;
picik = 0 ;
anno = [] ;
if isfield(rstr,'tbz'),
   tbz = rstr.tbz ;
else
   tbz = [] ;
end

while(done<2),
   xlim = [max(0,xlim(1)) min((length(x)-1)/fs,xlim(2))] ;
   if ~isempty(cl),
      k = find(cl(:,3)==0) ;
      if ~isempty(k),
         ici=diff(cl(k,1));
         ici(end+1) = ici(end) ;
         rici = abs(diff(ici))./ici(1:end-1) ;
         rthr = PICI_THR(1+(ici(1:end-1)>PICI_SWITCH))' ;
         pici_list = k(rici>rthr) ;
      end
      L = 20*log10(cl(k,2)) ;
   else
      k = [] ;
      ici = [] ;
   end
   subplot(211),hold off
   if ~isempty(k),
      scatter(cl(k,1),log10(ici),18,L,'filled'),grid
      caxis(CAX) ;
      hold on
      plot(cl(k,1),log10(ici),'ko')
      if isfield(OPTS,'bzthr'),
         if isempty(tbz) || tbz(3)==0,
            tbz = find_bz(cl(k,1),OPTS) ;
         end
         if ~isempty(tbz),
            plot(xlim,[1 1]*log10(OPTS.bzthr),'k-')
            hbz = plot([1;1]*tbz(1:2),repmat(get(gca,'YLim')',1,2),'m:') ;
            set(hbz,'LineWidth',1.5)
         end
      else
         tbz = [] ;
      end
   end
   ylabel('log_{10}(ICI)')
   set(gca,'UserData',1)
   if LOGDISP==1,
      title(sprintf('Relative threshold %1.1f dB\n',20*log10(RTHR))) ;
   else
      title(sprintf('Relative threshold %1.2f\n',RTHR)) ;
   end
   kx = round(xlim(1)*fs)+1:round(xlim(2)*fs) ;
   
   if LOGDISP,
      set(d2,'XData',cl(k,1),'YData',20*log10(cl(k,2))) ;
      set(h2,'YLim',[MINDB 20*log10(max(x(kx)))+2]) ;
   else
      set(d2,'XData',cl(k,1),'YData',cl(k,2)) ;
      set(h2,'YLim',[0 max(x(kx))*1.05]) ;
   end
   set(h1,'XLim',xlim) ;
   set(h2,'XLim',xlim) ;
   kc = find(cl(k,1)>xlim(1) & cl(k,1)<=xlim(2)) ;
   if ~isempty(kc),
      set(h1,'YLim',log10([min(ici(kc))*0.9 max(ici(kc))*1.1])) ;
   end
   done = 0 ;
   while ~done,
      [gx gy button]=ginput(1) ;
      gy = 10^gy ;
      
      switch button,
         case '+',
            RTHR = min(RTHR*1.12,1) ;
            done = 1 ;
         case '-',
            RTHR = max(RTHR*0.89,0.2) ;
            done = 1 ;
         case 'z',
            xlim = diff(xlim)/5*[-1 1]+gx ;
            done = 1 ;
         case 'F',
            xlim = xlim + diff(xlim)*0.95 ;
            if xlim(2)>length(x)/fs,
               xlim = length(x)/fs+[-diff(xlim) 0] ;
            end
            done = 1 ;
         case 'B',
            xlim = xlim - diff(xlim)*0.95 ;
            if xlim(1)<0,
               xlim = [0 diff(xlim)] ;
            end
            done = 1 ;
         case 'f',
            picik = min(picik+1,length(pici_list)) ;
            kcl = max(min(pici_list(picik),length(cl)-5),6) ;
            xlim = cl(kcl+5*[-1 1]) ;
            done = 1 ;
         case 'b',
            picik = max(picik-1,1) ;
            kcl = max(min(pici_list(picik),length(cl)-5),6) ;
            xlim = cl(kcl+5*[-1 1]) ;
            done = 1 ;
         case 'x',
            xlim = diff(xlim)*2.5*[-1 1]+gx ;
            done = 1 ;
         case 'a',
            xlim = [0 length(x)/fs] ;    
            done = 1 ;
         case 'E',
            figure(FIGN+1),clf
            [epts,rstr] = echogram_annotate(xe,fs,cl(cl(:,3)==0,1),ECHOGRAM_EXTENT,rstr) ;
            clf
            if ~isempty(epts),
               anno = add_audit(anno,epts) ;
            end
            if ~isempty(tbz),
               rstr.tbz = [tbz OPTS.bzthr OPTS.bzgap] ;
            end
            figure(FIGN)
         case 'e',
            figure(FIGN+1),clf
            echogram_annotate(xe,fs,cl(cl(:,3)==0,1),ECHOGRAM_EXTENT,0) ;
            figure(FIGN)
         case 's',
            ksx = round(gx*fs)+(-5:5) ;
            [lev kp] = max(x(ksx)) ;
            cl(end+1,1:2) = [ksx(kp)/fs lev] ;
            [cc I] = sort(cl(:,1)) ;
            cl = cl(I,:) ;
            done = 1 ;
         case 't',
            subplot(212)
            [gx gy button]=ginput(1) ;
            subplot(211)
            if button==1,
               if LOGDISP==1,
                  gy = 10^(gy/20) ;
               end
               cl(kc,3) = max(cl(:,3))+1 ;
               % find all clicks in segment that are above gy
 					opts.thr = gy ;
               cc = getclicksr(x(kx),fs,opts) ;
               cl(end+(1:length(cc)),1:2) = [cc(:,1)+kx(1)/fs cc(:,2)] ;
               [cc I] = sort(cl(:,1)) ;
               cl = cl(I,:) ;
					ktc = [1;1+find(diff(cl(:,1))>opts.blank)] ;
					cl = cl(ktc,:) ;
               done = 1 ;
            end
         case 'd'
            ax = axis ;
            SC = diff(ax(3:4))/diff(ax(1:2)) ;
            [mm ks] = min(abs(cl(k,1)*SC+j*log10(ici)-(gx*SC+j*log10(gy)))) ;
            cl(k(ks),3) = max(cl(:,3))+1 ;
            done = 1 ;
         case 'R',
            cl(k(kc),3) = max(cl(:,3))+1 ;
            done = 1 ;
         case 'l',
            ss = inputdlg('Enter type','sortclicks',1,{''}) ;
            if ~isempty(ss),
               anno = add_audit(anno,[gx 0],ss{1}) ;
            end
         case 'W' 
            whpl = get(gca,'UserData') ;
            cc = cl(k,1:2) ;
            if whpl==1,
               if LOGDISP==1,
                  gy = 10^(gy/20) ;
               end
               ks = find(cc(:,1)<gy) ;
               if ~isempty(ks),
                  cl(k(ks),3) = max(cl(:,3))+1 ;
                  done = 1 ;
               end
            end
         case 1      % left button
            p1 = get(gca,'CurrentPoint');
            whpl = get(gca,'UserData') ;
            rbbox ;
            p2 = get(gca,'CurrentPoint');
            px = sort([p1(1,1) p2(1,1)]);
            py = sort([p1(1,2) p2(1,2)]);
            cc = cl(k,1:2) ;
            if whpl==1,
               py = 10.^py ;
               ks = find(cc(:,1)>px(1) & ici>py(1) & cc(:,1)<px(2) & ici<py(2)) ;
            else
               if LOGDISP==1,
                  py = 10.^(py/20) ;
               end
               ks = find(cc(:,1)>px(1) & cc(:,2)>py(1) & cc(:,1)<px(2) & cc(:,2)<py(2)) ;
            end
            if ~isempty(ks),
               cl(k(ks),3) = max(cl(:,3))+1 ;
               done = 1 ;     
            end
         case 3      % right button
				cc = fill_gaps(x,fs,cl,gx,RTHR,opts) ;
            if ~isempty(cc),
               try
                  cl(end+(1:size(cc,1)),1:2) = cc ;
               catch
                  keyboard 
               end
               [cc I] = sort(cl(:,1)) ;
               cl = cl(I,:) ;
               done = 1 ;
            end
         case 'y'      % fill all positive ICI steps in the current window
				kk = find(cl(:,1)>xlim(1) & cl(:,1)<xlim(2) & cl(:,3)==0) ;
				ici = diff(cl(kk,1)) ;
				stp = 1+find(ici(2:end)>ici(1:end-1)*1.5) ;
				cc = [] ;
				for ks=1:length(stp),
					gx = mean(cl(kk(stp(ks)+[0 1]),1)) ;
					cc = [cc;fill_gaps(x,fs,cl,gx,RTHR,opts)] ;
            end
            if ~isempty(cc),
               try
                  cl(end+(1:size(cc,1)),1:2) = cc ;
               catch
                  keyboard 
               end
				end
				[cc I] = sort(cl(:,1)) ;
				cl = cl(I,:) ;
            done = 1 ;
         case 'L'
            LOGDISP = LOGDISP==0 ;
            if LOGDISP==1,
               set(d1,'YData',20*log10(x)) ;
            else
               set(d1,'YData',x) ;
            end
            done = 1 ;
         case 'u'
            l = max(1,max(cl(:,3))) ;
            cl(cl(:,3)>=l,3) = 0 ;
            done = 1 ;
         case '1'
            if ~isempty(tbz),
               tbz = [gx tbz(2) 1] ;
               set(hbz(1),'XData',[1;1]*tbz(1)) ;
               rstr.tbz = [tbz OPTS.bzthr OPTS.bzgap] ;
            end
         case '2'
            if ~isempty(tbz),
               tbz = [tbz(1) gx 1] ;
               set(hbz(2),'XData',[1;1]*tbz(2)) ;
               rstr.tbz = [tbz OPTS.bzthr OPTS.bzgap] ;
            end
         case '3'
            if ~isempty(tbz),
               tbz = find_bz(cl(k,1),OPTS) ;
               set(hbz(1),'XData',[1;1]*tbz(1)) ;
               set(hbz(2),'XData',[1;1]*tbz(2)) ;
               rstr.tbz = [tbz OPTS.bzthr OPTS.bzgap] ;
            end

         case 'Q'
            cl = [] ;
            return
            
         case 'q',
            done = 2 ;
      end      % switch
   end         % while ~done
   save _temp.mat cl anno rstr
end            % while done<2

cl = cl(cl(:,3)==0,1:2) ;
if isfield(OPTS,'fe'),
   x = [xe x] ;
end
return


function    [xd,xe,fs]=preproc(x,fs,opts)

LIM = 1e-4 ;
if length(opts.fd)==1,
   [b,a]=butter(4,opts.fd/(fs/2),'high');      % was 6
else
   [b,a]=butter(4,opts.fd/(fs/2));      % was 6
end
if size(x,2)>1,
   xd=sum(hilbenv(filter(b,a,x)).^2,2);
   xd=buffer(xd,opts.df,0,'nodelay');
   xd=sqrt(mean(xd))' ;
else
	xd = filter(b,a,x) ;
	if isfield(opts,'nr') && opts.nr==1,
		W = mean(buffer(max(min(xd,LIM),-LIM),fs/1000*20,0,'nodelay'),2) ;
		nrep = floor(length(xd)/length(W)) ;
		xd = xd - [repmat(W,nrep,1);W(1:length(xd)-nrep*length(W))] ;
	end
   xd=hilbenv(xd);
   xd=buffer(xd,opts.df,0,'nodelay');
   xd=sqrt(mean(xd.^2))' ;
end

if isfield(opts,'fe'),
   if length(opts.fe)==1,
      [b,a]=butter(4,opts.fe/(fs/2),'high');      % was 6
   else
      [b,a]=butter(4,opts.fe/(fs/2));      % was 6
   end
	if size(x,2)>1,
		xe=sum(hilbenv(filter(b,a,x)).^2,2);
		xe=buffer(xe,opts.df,0,'nodelay');
		xe=sqrt(mean(xe))' ;
	else
		xe = filter(b,a,x) ;
		if isfield(opts,'nr'),
			W = mean(buffer(max(min(xe,LIM),-LIM),fs/1000*20,0,'nodelay'),2) ;
			nrep = floor(length(xe)/length(W)) ;
			xe = xe - [repmat(W,nrep,1);W(1:length(xd)-nrep*length(W))] ;
		end
		xe=hilbenv(xe);
		xe=buffer(xe,opts.df,0,'nodelay');
		%xe=max(xe)';
		xe=sqrt(mean(xe.^2))' ;
	end
else
	xe = xd ;
end

fs = fs/opts.df ;
return
	

function		cc = fill_gaps(x,fs,cl,gx,RTHR,opts)
%
cc = [] ;
kl = find(cl(:,1)<gx & cl(:,3)==0,1,'last') ;
ku = find(cl(:,1)>gx & cl(:,3)==0,1) ;
thr = RTHR*mean(cl([kl ku],2)) ;
kxx = max(1,round(fs*(cl(kl,1)+opts.blank))):min(round(fs*(cl(ku,1)-opts.blank)),length(x)) ;
if isempty(kxx), return, end
xx = x(kxx) ; 
% find all clicks in segment that are above thr
opts.thr = thr ;
cc = getclicksr(xx,fs,opts) ;
cc = [cc(:,1)+kxx(1)/fs cc(:,2)] ;
return


function    tbz = find_bz(cl,opts)
%
tbz = [] ;
bzcl = diff(cl)<opts.bzthr ;
kbz = find(bzcl==1,1) ;
if ~isempty(kbz),
   tbz = cl(kbz) ;
   if isfield(opts,'bzgap'),
      ked = kbz-1+find(diff(bzcl(kbz:end))<0) ;
      kst = kbz-1+find(diff(bzcl(kbz:end))>0) ;
      if ~isempty(kst),
         ged = find(cl(kst,1)-cl(ked(1:length(kst)))>opts.bzgap,1) ;
         if ~isempty(ged),
            ked = ked(ged) ;
         else
            ked = ked(end) ;
         end
      end
   else
      ked = kbz-1+find(diff(bzcl(kbz:end))<0,1,'last') ;
   end
   if isempty(ked),
      ked = length(cl) ;
   end
   tbz(2:3) = [cl(ked) 0] ;
end
return


