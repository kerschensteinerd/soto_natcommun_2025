function groups = defineExperimentalGroups(roi)
% DEFINEEXPERIMENTALGROUPS Create logical indices for all experimental groups
%
% USAGE:
%   groups = defineExperimentalGroups(roi)
%
% INPUT:
%   roi - Structure containing ROI data with field:
%         .id: [nRois x 3] matrix with [depth, genotype, condition]
%              genotype: 0=WT, 1=KO
%              condition: 0=Ctrl, 1=APB
%
% OUTPUT:
%   groups - Structure with logical index arrays for each experimental group:
%            .wtCtrl  - Wild-type Control
%            .wtApb   - Wild-type APB
%            .koCtrl  - Knockout Control
%            .koApb   - Knockout APB
%            .wtOn    - Wild-type ON sublayer (depth > 0.5)
%            .wtOff   - Wild-type OFF sublayer (depth < 0.5)
%            .koOn    - Knockout ON sublayer
%            .koOff   - Knockout OFF sublayer
%            .wtOnCtrl, .wtOnApb, .wtOffCtrl, .wtOffApb
%            .koOnCtrl, .koOnApb, .koOffCtrl, .koOffApb
%
% DESCRIPTION:
%   Creates a comprehensive set of logical indices for all common
%   experimental group combinations. Each field is a logical array
%   of size [nRois x 1] where true indicates the ROI belongs to that group.
%
% EXAMPLE:
%   load('iGluSnFR_IPL.mat');
%   groups = defineExperimentalGroups(roi);
%   
%   % Get all wild-type control ROIs
%   wtCtrlData = roi.resp(:, :, :, groups.wtCtrl);
%   
%   % Count ROIs in each major group
%   fprintf('WT Ctrl: %d ROIs\n', sum(groups.wtCtrl));
%   fprintf('KO Ctrl: %d ROIs\n', sum(groups.koCtrl));
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

% Validate input
if ~isstruct(roi) || ~isfield(roi, 'id')
    error('roi must be a structure with field "id"');
end

if size(roi.id, 2) ~= 3
    error('roi.id must have 3 columns [depth, genotype, condition]');
end

% Initialize output structure
groups = struct();

% OFF/ON boundary (IPL depth)
depthDivider = 0.5;

% === BASIC GENOTYPE × CONDITION GROUPS ===
groups.wtCtrl = roi.id(:, 2) == 0 & roi.id(:, 3) == 0;  % Wild-type Control
groups.wtApb  = roi.id(:, 2) == 0 & roi.id(:, 3) == 1;  % Wild-type APB
groups.koCtrl = roi.id(:, 2) == 1 & roi.id(:, 3) == 0;  % Knockout Control
groups.koApb  = roi.id(:, 2) == 1 & roi.id(:, 3) == 1;  % Knockout APB

% === GENOTYPE × LAYER GROUPS ===
groups.wtOn  = roi.id(:, 2) == 0 & roi.id(:, 1) > depthDivider;   % WT ON
groups.wtOff = roi.id(:, 2) == 0 & roi.id(:, 1) < depthDivider;   % WT OFF
groups.koOn  = roi.id(:, 2) == 1 & roi.id(:, 1) > depthDivider;   % KO ON
groups.koOff = roi.id(:, 2) == 1 & roi.id(:, 1) < depthDivider;   % KO OFF

% === FULL COMBINATION GROUPS (GENOTYPE × CONDITION × LAYER) ===
% Wild-type
groups.wtOnCtrl  = groups.wtCtrl & roi.id(:, 1) > depthDivider;
groups.wtOnApb   = groups.wtApb  & roi.id(:, 1) > depthDivider;
groups.wtOffCtrl = groups.wtCtrl & roi.id(:, 1) < depthDivider;
groups.wtOffApb  = groups.wtApb  & roi.id(:, 1) < depthDivider;

% Knockout
groups.koOnCtrl  = groups.koCtrl & roi.id(:, 1) > depthDivider;
groups.koOnApb   = groups.koApb  & roi.id(:, 1) > depthDivider;
groups.koOffCtrl = groups.koCtrl & roi.id(:, 1) < depthDivider;
groups.koOffApb  = groups.koApb  & roi.id(:, 1) < depthDivider;

% === SUMMARY ===
% Optional: Add summary information
groups.summary.nRois = size(roi.id, 1);
groups.summary.depthDivider = depthDivider;

end
