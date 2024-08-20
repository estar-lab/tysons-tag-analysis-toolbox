%==========================================================================
%  Computer Loop Number for RANSAC/MSAC Algorithm
%==========================================================================
% ====================
% Updated: 04/25/2022
% Ding Zhang
% zhding@umich.edu
% NOTE:
% 'sampleSize' is the minimum number of points required to do model
% estimation. And this function returns the estimated number of iterations
% (i.e., N) for the RANSAC algorithm to find a set of sample points that
% are all inliers. However, this does not mean this set of inlier samples
% are good for model estimation (i.e., they are inliers, yes, but do not
% necessarily give good result if the model is estimated using them. So,
% the RANSAC algorithm need to run more than N iterations to find a set of
% GOOD inliers, that will be used for model estimation.
% Let's introduce the notion of 'effectiveSampleSize', if we have this many
% inliers at once, then the model estimated will more likely to be GOOD.
% ====================

%% Previous code.
% function N = computeLoopNumber_local(sampleSize, confidence, pointNum, inlierNum)
% %#codegen
% pointNum = cast(pointNum, 'like', inlierNum);
% 
% inlierProbability = (inlierNum/pointNum)^sampleSize;
% 
% if inlierProbability < eps(class(inlierNum))
%     N = intmax('int32');
% else
%     conf = cast(0.01, 'like', inlierNum) * confidence;
%     one  = ones(1,    'like', inlierNum);
%     num  = log10(one - conf);
%     den  = log10(one - inlierProbability);
%     N    = int32(ceil(num/den));
% end 

function N = computeLoopNumber_local(sampleSize, confidence, pointNum, inlierNum)

pointNum = cast(pointNum, 'like', inlierNum);

effectiveSampleSize = 8 * sampleSize;

inlierProbability = (inlierNum/pointNum)^effectiveSampleSize;

if inlierProbability < eps(class(inlierNum))
    N = intmax('int32');
else
    conf = cast(0.01, 'like', inlierNum) * confidence;
    one  = ones(1,    'like', inlierNum);
    num  = log10(one - conf);
    den  = log10(one - inlierProbability);
    N    = int32(ceil(num/den));
end 
