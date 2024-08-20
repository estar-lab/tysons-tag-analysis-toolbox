function rmdir(h,dirname)
%rmdir Remove a directory on an FTP site.
%    RMDIR(FTP,DIRECTORY) removes a directory on an FTP site.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)
dirname = convertStringsToChars(dirname);
status = h.helper.InternalJObject.removeDirectory(dirname);
if (status == 0)
    code = h.helper.InternalJObject.getReplyCode;
    switch code
        case 550
            error(message("MATLAB:io:ftp:ftp:DeleteFailed",dirname));
        otherwise
            error(message("MATLAB:io:ftp:ftp:FTPError",code))
    end
end
end
