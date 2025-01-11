clf
subplot(211)
imagesc((0:size(L.eq,1)-1)*10/3600*2,(1:length(fc)),adjust2Axis(L.eq)'),axis xy
ylabel('Frequency (Hz)')
set(gca,'YTick',[3 8 13 18 23 28],'YTickLabel',{'100','320','1k','3.2k','10k','32k'})
set(gca,'XTick',0:3:24)
caxis([-100 -60])
title('Average Decidecade Levels')
colorbar_small('dB RMS')

subplot(212)
imagesc((0:size(L.eq,1)-1)*10/3600*2,(1:length(fc)),adjust2Axis(L.max-L.min)'),axis xy
ylabel('Frequency (Hz)')
xlabel('Time (hours)')
title('Max-Min Decidecade Levels')
set(gca,'YTick',[3 8 13 18 23 28],'YTickLabel',{'100','320','1k','3.2k','10k','32k'})
set(gca,'XTick',0:3:24)
caxis([3 30])
colorbar_small('dB SNR')
