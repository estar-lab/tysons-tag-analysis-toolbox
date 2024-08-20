function mkdir(h,dirname)
%MKDIR Creates a new directory on an FTP site.
%    MKDIR(FTP,DIRECTORY) creates a directory on the FTP site.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)

dirname = convertStringsToChars(dirname);
h.helper.InternalJObject.makeDirectory(dirname);
end
