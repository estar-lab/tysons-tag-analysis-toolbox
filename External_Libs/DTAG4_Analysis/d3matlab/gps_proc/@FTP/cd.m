function newDir = cd(h,str)
%CD Change current working directory.
%   CD(FTP,'DIRECTORY') sets the current directory to the one specified.
%   CD(FTP,'..') moves to the directory above the current one.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)

if (nargin > 1)
    str = convertStringsToChars(str);
    isSuccess = h.helper.InternalJObject.changeWorkingDirectory(str);
    if ~isSuccess
        error(message("MATLAB:io:ftp:ftp:NoSuchDirectory", str))
    end
end
newDir = char(h.helper.InternalJObject.printWorkingDirectory);
% There isn't an easier way to set the value of a StringBuffer.
h.helper.RemotePwd.setLength(0);
h.helper.RemotePwd.append(newDir);
end
