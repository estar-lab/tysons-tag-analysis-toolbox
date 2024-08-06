function new_data = ellipsoid_correction(data, sol)
    % ELLIPSOID_CORRECTION Reorient and rescale ellipsoid to fit on the unit
    % sphere
    % This function takes as its input the raw magnetometer data and maps it
    % onto the unit sphere.

    center = sol.center;
    eigen_vectors = sol.eigen_vectors;
    
    if length(sol.r) == 1
        radii = ones(3, 1).*sol.r;
    elseif length(sol.r) == 3
        radii = sol.r;
    end
    
    new_data = eigen_vectors*diag(1./radii)*(eigen_vectors')*(data - center);

end

