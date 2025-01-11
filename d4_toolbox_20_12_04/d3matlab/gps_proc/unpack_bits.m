function    b = unpack_bits(x,n)
%
%   b = unpack_bits(x,n)
%

V = abs(dec2bin(x,n))'>48 ;
b = V(:) ;
