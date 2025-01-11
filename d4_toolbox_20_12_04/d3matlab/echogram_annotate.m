function    [epts,bzs] = echogram_annotate(x,fs,cl,extent,bzs)

%    [anno,bzs] = echogram_annotate(x,fs,cl,extent,bzs)
%
%

if nargin<4 || isempty(extent)
   extent = 10/750 ;		% echogram extent in seconds
end

if nargin<5
   bzs = [] ;
end

if nargin==5 & ~isstruct(bzs) & bzs==0
   DOBZ = 0 ;
   bzs = [] ;
else
   DOBZ = 1 ;
end

mstrs = {'Unknown','No prey','Prey','','Unknown','No resp.','Response','','Unknown','No capt.','Capture'} ;
mgrps = [1 1 1 0 2 2 2 0 3 3 3] ;
mdefs = {'Unknown','Unknown','Unknown'} ;
bzs = init_bzs(bzs,mdefs) ;

caxdef = [3 60] ;	% default colour axis scale
rst = -0.0005 ;	% start range of the echogram
hssp = 750 ;		% half sound speed in water
nl = 20*log10(prctile(x,10)) ; 		% get approx noise floor
CMAP = jet ;

epts = [] ;
cax = caxdef ;
while 1
   [X,cc]=extract_cues(x,fs,cl(:,1)+rst,extent);
   clf
   set(gcf,'Renderer','painters')   % important! otherwise markers don't show up on plot
   axes('Position',[0.13 0.11 0.78 0.8]) ;
   %axes('Position',[0.18 0.11 0.73 0.8]) ;   % use this for printing
   %size(X)
   imageirreg(cc,(1:size(X(:,2)))'*hssp/fs+rst*hssp,20*log10(X)'-nl,1),axis xy
   colormap(CMAP) ;
   eh = gca ;
   set(gca,'FontSize',12,'LineWidth',1)
	xlabel('Time (s)')
	ylabel('Range (m)')
   caxis(cax) ;
   ecax = axis(eh) ;
   if DOBZ
      ha = plot_anno(epts,bzs) ;
      [hm,mlims] = side_menu(mstrs,mgrps,bzs.m) ;
   else
      ha = [] ;
   end
	[hc,clims] = icolbar(caxdef,cax,'Echo-to-noise ratio (dB)') ;
   dd = 0 ;
   while 1
      [gx,gy,button]=ginput1(eh) ;    % wait for user input
      xl = get(eh,'XLim') ;
		if button<=3
			if gx>xl(2)    % if clicked in colourbar area
            gy = interp1(get(eh,'YLim')',clims,gy) ;
			   caxis(eh,icolbar(hc,gy,button>1)) ;
            continue
         elseif gx<xl(1) && DOBZ==1     % if clicked in menu area
            gy = interp1(get(eh,'YLim')',mlims,gy) ;
				bzs.m = side_menu(hm,gy,bzs.m) ;
			   continue
			end
      end
      %axes(eh) ;
      ff = gcf ;
      ff.CurrentAxes = eh ;

      switch button
			case {'1','2','3','4','5','6'}
				bzs.s(abs(button-'0'),:) = [gx gy] ;
				update_anno(ha,bzs) ;
			case 'T'
				if ~any(isnan(bzs.t(end,:)))
					bzs.t(end+1,:) = NaN(1,5) ;
				end
				bzs.t(end,1:2) = [gx gy] ;
				ha = update_anno(ha,bzs) ;
			case 's'
            if size(bzs.t,1)>1
   				bzs.t = bzs.t([2:end,1],:) ;
      			update_anno(ha,bzs) ;
            end
			case 't'
				bzs.t(end,1:2) = [gx gy] ;
				update_anno(ha,bzs) ;
			case 'n'
				bzs.t(end,3:5) = [gx gy 0] ;
				ss = inputdlg('Enter number of beats','echogram',1,{''}) ;
            if ~isempty(ss) && ~isempty(ss{1})
					bzs.t(end,5) = max([str2double(ss{1}),0]) ;
               update_anno(ha,bzs) ;
				end
			case 'r'
				bzs.r(1:2) = [gx gy] ;
				update_anno(ha,bzs) ;
         case '+'
            curax = axis(eh) ;
            axis(eh,[curax(1:2) mean(curax([3 4]))+diff(curax(3:4))*[-1 1]]) ;
            if curax(4)+diff(curax(3:4))/2>ecax(4)
               extent = min(200/hssp,extent*2) ;
               dd = 1 ;
            end
         case '-'
            curax = axis(eh) ;
            axis(eh,[curax(1:2) mean(curax([3 4]))+diff(curax(3:4))/4*[-1 1]]) ;
         case 'a'
            axis(eh,ecax) ;
         case 'z'
            curax = axis(eh) ;
            axis(eh,[gx+0.25*diff(curax(1:2))*[-1 1] gy+0.25*diff(curax(3:4))*[-1 1]]);
			case 'c'
            curax = axis(eh) ;
            axis(eh,[gx+0.5*diff(curax(1:2))*[-1 1] gy+0.5*diff(curax(3:4))*[-1 1]]);
			case 'x'
            curax = axis(eh) ;
            axis(eh,[gx+diff(curax(1:2))*[-1 1] gy+diff(curax(3:4))*[-1 1]]);
         case 'l'
            ss = inputdlg('Enter type','echogram',1,{''}) ;
            if ~isempty(ss)
               ss = ['&' ss{1}] ;
               epts = add_audit(epts,[gx gy],ss) ;
					add_anno(gx,gy,ss) ;
            end
			case 'R'
            bzs.s = NaN(6,2) ;	% 6x single points for speed estimation
            bzs.r = NaN(1,2) ;	% first response point
            bzs.m = mdefs ;		% three strings (prey trace visibility, response, capture)
            bzs.t = NaN(1,5) ;	% 1 or more pair of points plus number of tailbeats
				update_anno(ha,bzs) ;
         case 'd'
            % find closest annotation and delete it
            pos = [bzs.s;bzs.r;bzs.t(:,1:2)] ; % positions of all annotations
            if ~isempty(epts)
               pos = [pos;epts.cue] ;
            end
            [m,km] = min((pos(:,1)-gx).^2+(pos(:,2)-gy).^2) ;
            if km<=6
               bzs.s(km,:) = NaN(1,2) ;
            elseif km<=7
               bzs.r = NaN(1,2) ;
            elseif km<=7+size(bzs.t,1)
               if size(bzs.t,1)==1
                  bzs.t = NaN(1,5) ;
               else
                  bzs.t = bzs.t((1:size(bzs.t,1))~=km-7,:) ;
               end
            else
               km = find((1:size(epts.cue,1))'~=km-7-size(bzs.t,1)) ;
               if isempty(km)
                  epts = [] ;
               else
                  epts.cue = epts.cue(km,:) ;
                  epts.stype = {epts.stype{km}} ;
               end
               dd = 1 ;
            end
				update_anno(ha,bzs) ; 
         case 1
				fprintf(' %2.2f s -> %2.2f m\n',gx,gy) ;
				epts = add_audit(epts,[gx gy],'&d') ;
				add_anno(gx,gy,'&d') ;
         case 'q'
            return ;
      end
      if dd>0, break, end
   end
end
return


function 	h = plot_anno(anno,bzs)
%
h = [] ;
hold on
if ~isempty(anno)
	hp = plot(anno.cue(:,1),anno.cue(:,2),'w.') ;
	set(hp,'MarkerSize',10)
	st = cell(1,length(anno.stype)) ;
	for k=1:length(anno.stype)
		st{k} = [' ',anno.stype(2:end)] ;
	end
	ht = text(anno.cue(:,1),anno.cue(:,2),st) ;
	set(ht,'Color','w')
end

% speed points 1 & 2. Each point has x,y coordinates
h.s(1,1) = plot(NaN(2,1),NaN(2,1),'w.--') ;
h.s(1,2:3) = text(NaN(2,1),NaN(2,1),{' 1',' 2'}) ;
% speed points 3 & 4
h.s(2,1) = plot(NaN(2,1),NaN(2,1),'w.--') ;
h.s(2,2:3) = text(NaN(2,1),NaN(2,1),{' 3',' 4'}) ;
% speed points 5 & 6
h.s(3,1) = plot(NaN(2,1),NaN(2,1),'w.--') ;
h.s(3,2:3) = text(NaN(2,1),NaN(2,1),{' 5',' 6'}) ;
set(h.s(:,1),'MarkerSize',12,'LineWidth',1.5)
set(h.s(:,2:3),'Color','w')
% response point
h.r = plot(NaN,NaN,'wd') ;
set(h.r,'MarkerSize',12)
% tailbeat points
h.t = NaN(size(bzs.t,1),3) ;
for k=1:size(bzs.t,1)
	h.t(k,1) = plot(NaN(1,2),NaN(1,2),'w.') ;
	h.t(k,2) = plot(NaN(5,1),NaN(5,1),'w') ;
	h.t(k,3) = text(NaN,NaN,' ') ;
end
set(h.t(:,3),'Color','w','VerticalAlignment','middle','FontSize',12) ;
set(h.t(end,2),'Color','c')
update_anno(h,bzs) ;
return


function    h = update_anno(h,bzs)
%
if isempty(h), return, end
set(h.s(1,1),'XData',bzs.s(1:2,1),'YData',bzs.s(1:2,2))
set(h.s(2,1),'XData',bzs.s(3:4,1),'YData',bzs.s(3:4,2))
set(h.s(3,1),'XData',bzs.s(5:6,1),'YData',bzs.s(5:6,2))
set(h.s(1,2),'Position',bzs.s(1,:))
set(h.s(1,3),'Position',bzs.s(2,:))
set(h.s(2,2),'Position',bzs.s(3,:))
set(h.s(2,3),'Position',bzs.s(4,:))
set(h.s(3,2),'Position',bzs.s(5,:))
set(h.s(3,3),'Position',bzs.s(6,:))
set(h.r,'XData',bzs.r(1),'YData',bzs.r(2))
if size(h.t,1)<size(bzs.t,1)
	h.t(end+1,:) = NaN(1,3) ;
	h.t(end,1) = plot(NaN(1,2),NaN(1,2),'w.') ;
	h.t(end,2) = plot(NaN(5,1),NaN(5,1),'w') ;
	h.t(end,3) = text(NaN,NaN,' ') ;
	set(h.t(end,3),'Color','w','VerticalAlignment','middle') ;
elseif size(h.t,1)>size(bzs.t,1)
	set(h.t(end,1),'XData',NaN(1,2),'YData',NaN(1,2))
	set(h.t(end,2),'XData',NaN(5,1),'YData',NaN(5,1))
	set(h.t(end,3),'String','','Position',NaN(1,2))
end
for k=1:size(bzs.t,1)
	bx = sort(reshape(bzs.t(k,[1 3 2 4]),2,2)) ;
	set(h.t(k,1),'XData',bx(:,1),'YData',bx(:,2))
	set(h.t(k,2),'XData',bx(1,1)+diff(bx(:,1))*[0 1 1 0 0]','YData',bx(1,2)+diff(bx(:,2))*[0 0 1 1 0]')
	set(h.t(k,3),'String',[' ' num2str(bzs.t(k,5))],'Position',[bx(2,1),mean(bx(:,2))])
end
set(h.t(end,2),'Color','c')
return


function add_anno(gx,gy,str)
%
hold on
hp = plot([gx;gx],[gy;gy],'w.-') ;
set(hp,'MarkerSize',10)
ht = text(gx,gy,[' ',str(2:end)]) ;
set(ht,'Color','w')
return


function		bzs = init_bzs(bzs,s)
%
if ~isfield(bzs,'s')
   bzs.s = NaN(6,2) ;	% 6x single points for speed estimation
elseif size(bzs.s,1)==4
   bzs.s(5:6,1:2) = NaN ;
end
if ~isfield(bzs,'r')
   bzs.r = NaN(1,2) ;	% first response point
end
if ~isfield(bzs,'m')
   bzs.m = s ;				% three strings (prey trace visibility, response, capture)
end
if ~isfield(bzs,'t')
   bzs.t = NaN(1,5) ;	% 1 or more pair of points plus number of tailbeats
end
return
