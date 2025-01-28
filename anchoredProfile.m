%% SCRIPT DESCRIPTION
% This script analyzes the profile of cone synaptic proteins (SYN) relative 
% to the Full Width at Half Maximum (FWHM) of cone arrestin (CAR) labeling. 
%
% INPUT:
%   pro: an n x 2 matrix containing normalized intensity profiles
%        pro(:,1) = CAR profile
%        pro(:,2) = SYN profile
%
% WORKFLOW:
% 1. Resample the input profiles to a target pixel size if necessary.
% 2. Normalize each profile to its minimum and maximum values.
% 3. Anchor the profiles based on a desired reference point (by default, 
%    the index of the maximum CAR signal, though alternative methods such as 
%    threshold-based anchoring are provided as commented options).
% 4. Place the aligned profiles into an output array spanning user-defined 
%    boundaries (upperBound to lowerBound).
% 5. Plot the aligned, normalized profiles.

%% CLEAR AND INITIALIZE
clear; close all; clc;

%% USER-DEFINED PARAMETERS
% Pixel sizes for the input and the resampled profiles
inputPxSize  = 0.0353;   % User-identified pixel size of input profiles (e.g., in µm/pixel)
targetPxSize = 0.04;     % Desired pixel size for resampled profiles (e.g., in µm/pixel)

% Boundaries (in the same physical units as pixel size) for the final output
upperBound = -3;  % Distance to the upper boundary from the anchor point
lowerBound =  3;  % Distance to the lower boundary from the anchor point

% Fractional CAR threshold for optional threshold-based anchoring
fractThresh = 0.25; 

% Construct the final depth array (x-axis) for plotting
depthDist = upperBound : targetPxSize : lowerBound;
nPixelsOut = numel(depthDist);

% Identify the zero (anchor) index in the depth array
zeroIdx = find(abs(depthDist) == min(abs(depthDist)));

% Determine the number of pixels (rows) in the original input
[nPixelsIn, ~] = size(pro);

%% RESAMPLE PROFILES
% If the input pixel size differs from the target, resample the data 
% using interpolation. Otherwise, use the original data.

if inputPxSize ~= targetPxSize
    % Define x-coordinates for original data and for resampling
    xIn  = 0 : inputPxSize : (nPixelsIn * inputPxSize - inputPxSize);
    xRes = 0 : targetPxSize : (nPixelsIn * inputPxSize - inputPxSize);
    
    % Pre-allocate output for resampled profiles
    resPro = zeros(numel(xRes), 2);
    
    % Interpolate each column (CAR and SYN) to the new xRes coordinates
    for i = 1:2
        resPro(:,i) = interp1(xIn, pro(:,i), xRes);
    end
else
    % If pixel sizes match, no resampling needed
    resPro = pro;
end

% Record size of the resampled profiles
[nPixelsRes, ~] = size(resPro); 

%% NORMALIZE PROFILES
% Subtract the minimum value and divide by the maximum value so that each 
% profile ranges from 0 to 1.

normPro = zeros(nPixelsRes, 2);
for i = 1:2
    currentProfile = resPro(:, i);
    currentProfile = currentProfile - min(currentProfile);  % Shift to 0
    currentProfile = currentProfile / max(currentProfile);  % Scale to 1
    normPro(:, i)   = currentProfile;
end

%% ALIGN PROFILES BY ANCHOR
% We place the maximum (or a threshold-based index) of the CAR profile at the 
% anchor point (depthDist == 0). Here, by default, we anchor at the maximum 
% CAR value.
%
% Alternative approaches (commented):
%   anchorIdx = find(normPro(:,1) >= max(normPro(:,1)) * fractThresh, 1, 'last');  % threshold-based
%   anchorIdx = find(normPro(:,2) == max(normPro(:,2)));                          % anchor using SYN max

anchorIdx = find(normPro(:,1) == max(normPro(:,1)), 1, 'last');  % Use last occurrence if multiple max indices

% Determine the start and stop indices in the output array
startIdx = zeroIdx - anchorIdx + 1;
stopIdx  = zeroIdx + (nPixelsRes - anchorIdx);

% Pre-allocate the final output array with NaNs
outPro = NaN(nPixelsOut, 2);

% Place the normalized profile data into the output array, respecting boundaries
spaceAfterZero = nPixelsOut - zeroIdx;

if startIdx >= 1 && stopIdx <= nPixelsOut
    % Entire resampled profile fits within the output boundaries
    outPro(startIdx:stopIdx, :) = normPro;
elseif startIdx < 1 && stopIdx <= nPixelsOut
    % Start of the profile extends beyond the upperBound; trim the beginning
    outPro(1:stopIdx, :) = normPro(abs(startIdx)+2:end, :);
elseif startIdx >= 1 && stopIdx > nPixelsOut
    % End of the profile extends beyond lowerBound; trim the end
    outPro(startIdx:end, :) = normPro(1:(anchorIdx + spaceAfterZero), :);
else
    % Both the beginning and end exceed the boundaries
    outPro = normPro(abs(startIdx)+2:(anchorIdx + spaceAfterZero), :);
end

%% PLOT RESULTS
figure; 
plot(depthDist, outPro, 'LineWidth', 1.5);
hold on;

% Optional: Plot a horizontal line corresponding to fractThresh
yline(fractThresh, '--k', 'Threshold');

xlabel('Distance from Anchor (units of targetPxSize)');
ylabel('Normalized Intensity');
title('Aligned Profiles of CAR and SYN');
legend({'CAR','SYN','Threshold'}, 'Location','best');
axis tight;
grid on;