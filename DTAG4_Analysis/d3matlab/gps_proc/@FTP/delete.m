function delete(h, filename)
%DELETE Delete a file on an FTP server.
%    DELETE(FTP,FILENAME) deletes a file on the server.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)

filename = convertStringsToChars(filename);
if any(filename=='*')
    listing = h.helper.InternalJObject.listNames(filename);
    names = cell(size(listing));
    for i = 1:length(listing)
        names{i} = listing(i);
    end
else
    names = {filename};
end

for i = 1:length(names)
    status = h.helper.InternalJObject.deleteFile(names{i});
    if (status == 0)
        error(message("MATLAB:io:ftp:ftp:DeleteFailed",char(names{i})));
    end
end

end
