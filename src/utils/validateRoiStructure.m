function validateRoiStructure(roi)
% VALIDATEROISTRUCTURE Validates the ROI data structure integrity
%
% USAGE:
%   validateRoiStructure(roi)
%
% INPUT:
%   roi - Structure containing ROI data with required fields:
%         .id     - [nRois x 3] ROI metadata matrix
%         .resp   - [time x repeats x stimSize x nRois] response array
%         .repRel - [nRois x nStimSizes] repeat reliability
%         .polIdx - [nRois x nStimSizes] polarity index
%         .f1Pow  - [nRois x nStimSizes] first-harmonic power
%
% THROWS:
%   Error if structure is invalid or missing required fields
%
% EXAMPLE:
%   load('iGluSnFR_IPL.mat');
%   validateRoiStructure(roi);
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

% Check if roi exists and is a structure
if ~isstruct(roi)
    error('Input must be a structure');
end

% Define required fields
requiredFields = {'id', 'resp', 'repRel', 'polIdx', 'f1Pow'};

% Check for required fields
for i = 1:length(requiredFields)
    if ~isfield(roi, requiredFields{i})
        error('Missing required field: %s', requiredFields{i});
    end
end

% Validate roi.id
if ~ismatrix(roi.id) || size(roi.id, 2) ~= 3
    error('roi.id must be a matrix with 3 columns [depth, genotype, condition]');
end

nRois = size(roi.id, 1);

% Validate roi.id ranges
depths = roi.id(:, 1);
genotypes = roi.id(:, 2);
conditions = roi.id(:, 3);

if any(depths < 0) || any(depths > 1)
    warning('Some IPL depths are outside the expected range [0, 1]');
end

if any(genotypes ~= 0 & genotypes ~= 1)
    error('Genotype values must be 0 (WT) or 1 (KO)');
end

if any(conditions ~= 0 & conditions ~= 1)
    error('Condition values must be 0 (Ctrl) or 1 (APB)');
end

% Validate roi.resp dimensions
if ndims(roi.resp) ~= 4
    error('roi.resp must be a 4D array [time x repeats x stimSize x nRois]');
end

if size(roi.resp, 4) ~= nRois
    error('roi.resp 4th dimension (%d) must match number of ROIs in roi.id (%d)', ...
          size(roi.resp, 4), nRois);
end

% Get number of stimulus sizes from resp
nStimSizes = size(roi.resp, 3);

% Validate roi.repRel dimensions
if size(roi.repRel, 1) ~= nRois
    error('roi.repRel rows (%d) must match number of ROIs (%d)', ...
          size(roi.repRel, 1), nRois);
end

if size(roi.repRel, 2) ~= nStimSizes
    error('roi.repRel columns (%d) must match number of stimulus sizes (%d)', ...
          size(roi.repRel, 2), nStimSizes);
end

% Validate roi.polIdx dimensions
if size(roi.polIdx, 1) ~= nRois
    error('roi.polIdx rows (%d) must match number of ROIs (%d)', ...
          size(roi.polIdx, 1), nRois);
end

if size(roi.polIdx, 2) ~= nStimSizes
    error('roi.polIdx columns (%d) must match number of stimulus sizes (%d)', ...
          size(roi.polIdx, 2), nStimSizes);
end

% Validate roi.f1Pow dimensions
if size(roi.f1Pow, 1) ~= nRois
    error('roi.f1Pow rows (%d) must match number of ROIs (%d)', ...
          size(roi.f1Pow, 1), nRois);
end

if size(roi.f1Pow, 2) ~= nStimSizes
    error('roi.f1Pow columns (%d) must match number of stimulus sizes (%d)', ...
          size(roi.f1Pow, 2), nStimSizes);
end

% Check for NaN values
if any(isnan(roi.id(:)))
    warning('roi.id contains NaN values');
end

% Success message
fprintf('ROI structure validation passed:\n');
fprintf('  - %d ROIs\n', nRois);
fprintf('  - %d time points\n', size(roi.resp, 1));
fprintf('  - %d repeats\n', size(roi.resp, 2));
fprintf('  - %d stimulus sizes\n', nStimSizes);
fprintf('  - WT ROIs: %d, KO ROIs: %d\n', sum(genotypes==0), sum(genotypes==1));
fprintf('  - Ctrl ROIs: %d, APB ROIs: %d\n', sum(conditions==0), sum(conditions==1));

end
