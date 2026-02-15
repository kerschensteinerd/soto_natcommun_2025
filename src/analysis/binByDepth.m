function [binCenters, binnedData] = binByDepth(data, depths, depthBins)
% BINBYDEPTH Bin data by IPL depth
%
% USAGE:
%   [binCenters, binnedData] = binByDepth(data, depths, depthBins)
%
% INPUTS:
%   data      - [nRois x ...] data to bin (first dimension must be nRois)
%   depths    - [nRois x 1] IPL depth for each ROI (0 to 1)
%   depthBins - [1 x nBins] or [nBins x 1] bin edges (e.g., 0.2:0.1:0.8)
%
% OUTPUTS:
%   binCenters - [1 x nDepthBins] center points of each depth bin (in % depth)
%   binnedData - Cell array {1 x nDepthBins} where each cell contains
%                data for ROIs in that depth bin
%
% DESCRIPTION:
%   Bins ROI data according to IPL depth. The bins are defined by edges
%   in depthBins, creating nBins+1 total bins:
%   - Bin 1: depth < depthBins(1)
%   - Bin i: depthBins(i-1) <= depth < depthBins(i) for i=2..nBins
%   - Bin nBins+1: depth >= depthBins(end)
%
% EXAMPLE:
%   load('iGluSnFR_IPL.mat');
%   depthBins = 0.2:0.1:0.8;
%   [binCenters, binnedPolarity] = binByDepth(roi.polIdx(:,1), roi.id(:,1), depthBins);
%   
%   % Plot mean polarity by depth
%   meanPolarity = cellfun(@mean, binnedPolarity);
%   plot(binCenters, meanPolarity, 'o-');
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

% Validate inputs
if nargin < 3
    error('Three inputs required: data, depths, and depthBins');
end

if size(data, 1) ~= length(depths)
    error('First dimension of data (%d) must match length of depths (%d)', ...
          size(data, 1), length(depths));
end

% Ensure depthBins is a row vector
depthBins = depthBins(:)';

% Number of bin edges and resulting bins
nBinEdges = length(depthBins);
nDepthBins = nBinEdges + 1;  % One more bin than edges

% Calculate bin centers (in percentage)
binCenters = zeros(1, nDepthBins);
for i = 1:nDepthBins
    if i == 1
        % First bin: below first edge
        binCenters(i) = (depthBins(1) - 0.05) * 100;
    elseif i == nDepthBins
        % Last bin: above last edge
        binCenters(i) = (depthBins(end) + 0.05) * 100;
    else
        % Middle bins: midpoint between edges
        binCenters(i) = mean([depthBins(i-1), depthBins(i)]) * 100;
    end
end

% Initialize cell array for binned data
binnedData = cell(1, nDepthBins);

% Bin the data
for i = 1:nDepthBins
    if i == 1
        % First bin: depth < depthBins(1)
        mask = depths < depthBins(1);
    elseif i <= nBinEdges
        % Middle bins: depthBins(i-1) <= depth < depthBins(i)
        mask = (depths >= depthBins(i-1)) & (depths < depthBins(i));
    else
        % Last bin: depth >= depthBins(end)
        mask = depths >= depthBins(end);
    end
    
    % Extract data for this bin
    binnedData{i} = data(mask, :);
end

end
