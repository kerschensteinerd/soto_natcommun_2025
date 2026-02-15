function zResp = computeZScores(roi, stimSize)
% COMPUTEZSCORES Compute z-scored responses from raw ROI data
%
% USAGE:
%   zResp = computeZScores(roi, stimSize)
%
% INPUTS:
%   roi      - Structure containing ROI data with field:
%              .resp: [time x repeats x stimSize x nRois] response array
%   stimSize - Index of stimulus size to analyze (default: 1)
%
% OUTPUT:
%   zResp - [nRois x nTime] matrix of z-scored responses
%           Each ROI is normalized by its own mean and standard deviation
%
% DESCRIPTION:
%   Computes z-scored responses by:
%   1. Calculating the standard deviation across time and repeats for each ROI
%   2. Computing the mean across time and repeats for each ROI
%   3. Averaging responses across repeats to get mean time course
%   4. Z-scoring: zResp(i,:) = (avResp(i,:) - mean(i)) / std(i)
%
% EXAMPLE:
%   load('iGluSnFR_IPL.mat');
%   zResp = computeZScores(roi, 1);
%   plot(zResp(1,:));  % Plot first ROI's z-scored response
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

% Handle default arguments
if nargin < 2
    stimSize = 1;
end

% Validate inputs
if ~isstruct(roi) || ~isfield(roi, 'resp')
    error('roi must be a structure with field "resp"');
end

if stimSize < 1 || stimSize > size(roi.resp, 3)
    error('stimSize must be between 1 and %d', size(roi.resp, 3));
end

% Calculate standard deviation across time and repeats for each ROI
sdResp = squeeze(std(roi.resp(:, :, stimSize, :), 0, [1 2]));

% Calculate mean across time and repeats for each ROI
avSub = squeeze(mean(roi.resp(:, :, stimSize, :), [1 2]));

% Compute average response across repeats (for time course)
avResp = squeeze(mean(roi.resp(:, :, stimSize, :), 1))';  % [nRois x nTime]

% Pre-allocate z-scored response matrix
nRois = size(avResp, 1);
zResp = zeros(size(avResp));

% Compute z-score for each ROI
% Vectorized version (more efficient):
zResp = (avResp - avSub) ./ sdResp;

% Note: The above replaces this loop:
% for i = 1:nRois
%     zResp(i, :) = (avResp(i, :) - avSub(i)) / sdResp(i);
% end

% Handle any division by zero (ROIs with no variance)
zResp(isinf(zResp)) = 0;
zResp(isnan(zResp)) = 0;

end
