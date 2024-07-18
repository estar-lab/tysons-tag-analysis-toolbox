function disp(h)
% DISP Display method for the FTP object.

% Copyright 1984-2020 The MathWorks, Inc.

if length(h) ~= 1
    % FTP array; Should work for empty case as well.
    s = size(h);
    str = sprintf('%dx',s);
    str(end) = [];
    disp(getString(message("MATLAB:io:ftp:ftp:ArrayOfFtp",str)));
else
    fprintf( ...
        '  FTP Object\n     host: %s\n     user: %s\n      dir: %s\n     mode: %s', ...
        h.helper.Host,h.helper.Username,char(h.helper.RemotePwd.toString),char(h.helper.Type.toString));
end
end
