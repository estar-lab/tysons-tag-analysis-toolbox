function    [T,pe] = ptrack(A,M,s,fs,fc)

%    [T,pe]=ptrack(A,M,s,fs)			% A and M are matrices
%	  or
%    [T,pe]=ptrack(A,M,s,fs,fc)		% A and M are matrices
%	  or
%    [T,pe]=ptrack(A,M,s)				% A and M are sensor structures
%	  or
%    [T,pe]=ptrack(A,M,s,fc)			% A and M are sensor structures
%    Simple dead-reckoned track (pseudo-track) estimation based on speed and body 
%	  pointing angle.
%
%	  Inputs:
%    A is a nx3 acceleration matrix with columns [ax ay az]. Acceleration can 
%		be in any consistent unit, e.g., g or m/s^2. 
%    M is the magnetometer signal matrix, M=[mx,my,mz] in any consistent unit
%		(e.g., in uT or Gauss). A and M must have the same size (and so are both 
%		measured at the same sampling rate).
%    s is the forward speed of the animal in m/s. s can be a single number meaning 
%		that the animal is assumed to travel at a constant speed. s can also be a vector
%		with the same number of rows as A and M, e.g., generated by ocdr.
%    fs is the sampling rate of the sensor data in Hz (samples per second).
%	  fc (optional) specifies the cut-off frequency of a low-pass filter to
%		apply to A and M before computing pointing angle. The filter cut-off frequency is in Hz. 
%		The filter length is 4*fs/fc. Filtering adds no group delay. If fc is empty or 
%		not given, the default value of 0.2 Hz (i.e., a 5 second time constant) is used.
%
%    Returns:
%	  T is the estimated track in a local level frame. The track is defined as meters
%		of northward and eastward movement (termed 'northing' and 'easting', i.e, 
%		T=[northing,easting]) relative to the animal's position at the start of the measurements 
%		(which is defined as [0,0]). The track sampling rate is the same as for the input data and
%		so each row of T defines the track coordinates at times 0,1/fs,2/fs,... relative to the
%		start time of the measurements.
%	  pe is the estimated depth or altitude predicted from the speed and pitch angle. This can be
%		compared against the measured depth/altitude to assess errors in the dead-reckoned track.
%		Note that even if pe matches the observed depth, this does not guarantee that the track is accurate.
%
%	  Frame: This function assumes a [north,east,up] navigation frame and a
%	  [forward,right,up] local frame. Both A and M must be rotated if needed to match the
%	  animal's cardinal axes otherwise the track will not be meaningful. Use rotframe() to
%	  achieve this. Unless the local declination angle is also corrected with rotframe, the dead-
%	  reckoned track will use magnetic north rather than true north.
%
%    CAUTION: dead-reckoned tracks are usually very inaccurate. They are useful to get an
%	  idea of HOW animals move rather than WHERE they go. Few animals probably travel in exactly
%	  the direction of their longitudinal axis and anyway measuring the precise orientation of the
%	  longitudinal axis of a non-rigid animal is fraught with error. Moreover, if there is net flow
%	  in the medium, the animal will be advected by the flow in addition to its autonomous movement.
%	  For swimming animals this can lead to substantial errors. The forward speed is assumed to be 
%	  with respect to the medium so the track derived here is NOT the 'track-made-good', i.e., the
%	  geographic movement of the animal. It estimates the movement of the animal with respect to the
%	  medium. There are numerous other sources of error so use at your own risk!
%
%	  Example:
%		T = ptrack()
% 	   returns: .
%
%    Valid: Matlab, Octave
%    markjohnson@st-andrews.ac.uk
%    Last modified: 16 Feb 2018: bug fixed for speed vectors

T = [] ; pe = [] ;
if nargin<3,
   help ptrack
   return
end

if isstruct(A),
	if nargin>3,
		fc = fs ;
	else
		fc = [] ;
   end
	[A,M,fs] = sens2var(A,M,'regular') ;
	if isempty(A),	return, end

else
	if nargin<4,
		help ptrack
		return
	end
	if nargin<5,
		fc = [] ;
	end
end

if isempty(fc),
   fc = 0.2 ;
end

if length(s)>1,
   if length(s)~=size(A,1),
      fprintf('ptrack: length of speed vector must equal column length of A and M\n');
      return
   end
   s = repmat(s(:)/fs,1,3) ;
else
   s = s/fs ;
end

W = body_axes(A,M,fs,fc) ;
T = cumsum(s.*(W.x)) ;

if nargout>=2,
	p = a2pr(A,fs,fc);
   pe = -cumsum((s/fs).*sin(p)) ;
end

