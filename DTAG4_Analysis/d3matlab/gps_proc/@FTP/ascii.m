function ascii(h)
%ASCII  Sets ASCII transfer type.
%   ASCII(F) sets ASCII transfer type for the FTP object F.

% Copyright 1984-2020 The MathWorks, Inc.

% Make sure we're still connected.
connect(h.helper)

% There isn't an easier way to set the value of a StringBuffer.
h.helper.Type.setLength(0);
h.helper.Type.append('ascii');
end