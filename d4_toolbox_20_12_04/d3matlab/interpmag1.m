function    [M,fs] = interpmag1(M,fs,df)
%
%    [M,fs] = interpmag1(M,fs,df)
%     Process D3 magnetometer data to produce a 2xmfs/df matrix.
%     M is a 6-column raw magnetometer matrix sampled at fs Hz.
%		Use this more efficient function instead of interpmag if 
%		the data size is large.
%
%     Result:
%     M is a 3-column interpolated magnetometer matrix.
%     fs is the resulting sampling rate in Hz of M.
%
%     mark johnson
%     7 Jul 2021

if nargin<3,
   help interpmag1
   return
end

x = decdc(reshape([M(:,1) -M(:,4)]',[],1),df) ;
y = decdc(reshape([M(:,2) -M(:,5)]',[],1),df) ;
z = decdc(reshape([M(:,3) -M(:,6)]',[],1),df) ;
M = [x y z] ;
fs = 2*fs/df ;
return
