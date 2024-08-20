function close(h)
%CLOSE Close the connection with the server.
%    CLOSE(FTP) closes the connection with the server.

% Copyright 1984-2020 The MathWorks, Inc.

try
    h.helper.InternalJObject.disconnect;
catch
    % Do nothing.  The error was probably that we were already disconnected.
end
end