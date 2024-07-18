function rename(h,oldname,newname)
%RENAME Rename a file on an FTP site.
%    RENAME(FTP,OLDNAME,NEWNAME) renames a file on an FTP site.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)
oldname = convertStringsToChars(oldname);
newname = convertStringsToChars(newname);
details1 = dir(h, oldname);
details2 = dir(h, newname);
if isempty(details1)
    error(message("MATLAB:io:ftp:ftp:FileUnavailable", oldname));
elseif ~isempty(details2)
    error(message("MATLAB:io:ftp:ftp:RenameExistingFile", newname));
else
    h.helper.InternalJObject.rename(oldname, newname);
    replyCode = h.helper.InternalJObject.getReplyCode;
    if replyCode >= 500 && replyCode <= 553
        % The command was not accepted and the requested action did not take place.
        error(message("MATLAB:io:ftp:ftp:FTPError", replyCode));
    end
end
end
