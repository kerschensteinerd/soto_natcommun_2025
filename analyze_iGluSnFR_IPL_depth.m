% ANALYZE_IGLUSNFR_IPL_DEPTH
%
% DESCRIPTION:
%   This script processes iGluSnFR data from the retina, specifically
%   focusing on the inner plexiform layer (IPL). It requires the user
%   to have loaded a MAT file called 'iGluSnFR_IPL.mat' prior to running.
%
%   The script:
%       1) Divides ROIs into depth bins within the IPL.
%       2) Calculates average and z-scored responses for each ROI.
%       3) Selects the top 50% most reliable ROIs per genotype+condition
%          and IPL depth bin.
%       4) Computes the mean ± SEM envelope of the selected ROIs in each bin.
%       5) Determines a "global" y-range so that all subplots can be plotted
%          with a uniform range.
%       6) Produces several figures:
%            - Figure 1: Mean ± SEM envelopes by depth bin and genotype.
%            - Figure 2: Histograms of ROI reliability (roi.repRel).
%            - Figure 3: Histograms of ROI fundamental power (roi.f1Pow).
%
% USAGE:
%   1) Load the file 'iGluSnFR_IPL.mat' in your MATLAB workspace. The file
%      should contain the structure "roi" with fields:
%         roi.resp    (4D response array)
%         roi.id      (ROI metadata)
%         roi.repRel  (reliability metric)
%         roi.f1Pow   (fundamental power metric)
%   2) Adjust the user-defined parameters in the script if desired.
%   3) Run this script. It will generate 3 figures as described above.
%
% USER-DEFINED PARAMETERS:
%   depthBins  - Array of bin boundaries for the IPL (default: [0.3, 0.4, 0.5, 0.6, 0.7])
%   nRoisIncl  - Max number of ROIs per bin for plotting the envelope (default: 500)
%   stimSize   - Index or size of stimulus to analyze in roi.resp (default: 1)
%
% DEPENDENCIES:
%   This script calls several local functions:
%       depthBinMask
%       initEnvelopeStruct
%       traceEnvelope
%       plotMeanSemEnvelope
%       setYlimUsingRange
%       sem
%
% Written by: Daniel Kerschensteiner
% Date: 01/08/2025
%}

%% (1) USER-DEFINED INPUTS
% Adjust these values as needed
depthBins  = [0.3, 0.4, 0.5, 0.6, 0.7];   % Divides the IPL into bins
nDepthBins = numel(depthBins);
nDepths    = nDepthBins + 1;             % One extra bin above/below the specified bin edges
nRoisIncl  = 500;                        % We'll only plot up to this many ROIs per bin
stimSize   = 1;                          % Index for the stimulus size/condition in roi.resp

% Create approximate labels for each bin (in % depth)
depthCent = zeros(1, nDepths);
for i = 1:nDepths
    if i == 1
        % Slightly less than the lower bound
        depthCent(i) = 100 * (depthBins(1) - 0.01);
    elseif i == nDepths
        % Slightly more than the upper bound
        depthCent(i) = 100 * (depthBins(end) + 0.01);
    else
        % Middle points of bin boundaries
        depthCent(i) = 100 * ((depthBins(i-1) + depthBins(i)) / 2);
    end
end

%% (2) BUILD Z-SCORED RESPONSE
% The script expects that 'roi.resp' is a 4D array with dimensions:
%   (ROI x time x stimulusSize x [possibly repeats or some other dimension])
%   We average across time or repeats as needed and then compute the z-score
%   relative to each ROI's own baseline and standard deviation.

% Calculate each ROI's standard deviation and mean across the time dimension
sdResp = squeeze(std(roi.resp(:,:,stimSize,:), 0, [1 2]));
avSub  = squeeze(mean(roi.resp(:,:,stimSize,:), [1 2]));

% Compute the average response across time for each ROI
avResp = squeeze(mean(roi.resp(:,:,stimSize,:), 1))';  % [nRois x nTime]
zResp  = zeros(size(avResp));

% For each ROI, compute the z-scored trace
nRois = numel(sdResp);
for r = 1:nRois
    zResp(r,:) = (avResp(r,:) - avSub(r)) ./ sdResp(r);
end

%% (3) BIN THE DATA & PICK TOP 50% RELIABLE ROIs
% We'll store the (up to) nRoisIncl responses for each bin, genotype.

% Pre-allocate structures for each genotype & condition combination:
wtCtrl(nDepths).resp = [];
wtApb(nDepths).resp  = [];
koCtrl(nDepths).resp = [];
koApb(nDepths).resp  = [];

% Also store the 'repRel' values for histograms (figure 2)
wtCtrlRep(nDepths).vals = [];
wtApbRep(nDepths).vals  = [];
koCtrlRep(nDepths).vals = [];
koApbRep(nDepths).vals  = [];

% Also store the 'f1Pow' values for histograms (figure 3)
wtCtrlPow(nDepths).vals = [];
wtApbPow(nDepths).vals  = [];
koCtrlPow(nDepths).vals = [];
koApbPow(nDepths).vals  = [];

% Loop over each depth bin
for i = 1:nDepths
    
    % WT CTRL
    wtCtrlIdx = (roi.id(:,2)==0) & (roi.id(:,3)==0) ...
                & depthBinMask(roi.id(:,1), i, depthBins);
    wtCtrlResp = zResp(wtCtrlIdx, :);
    % Sort by roi.repRel descending; pick top 50%
    [~, wtCtrlSort] = sort(roi.repRel(wtCtrlIdx, stimSize), 'descend');
    wtCtrlSort = wtCtrlSort(1 : round(numel(wtCtrlSort)/2));
    wtCtrl(i).resp = wtCtrlResp(wtCtrlSort, :);
    % Store all repRel, f1Pow values
    wtCtrlRep(i).vals = roi.repRel(wtCtrlIdx, stimSize);
    wtCtrlPow(i).vals = roi.f1Pow(wtCtrlIdx, stimSize);

    % WT APb
    wtApbIdx = (roi.id(:,2)==0) & (roi.id(:,3)==1) ...
               & depthBinMask(roi.id(:,1), i, depthBins);
    wtApbResp = zResp(wtApbIdx, :);
    [~, wtApbSort] = sort(roi.repRel(wtApbIdx, stimSize), 'descend');
    wtApbSort = wtApbSort(1 : round(numel(wtApbSort)/2));
    wtApb(i).resp = wtApbResp(wtApbSort, :);
    wtApbRep(i).vals = roi.repRel(wtApbIdx, stimSize);
    wtApbPow(i).vals = roi.f1Pow(wtApbIdx, stimSize);

    % KO CTRL
    koCtrlIdx = (roi.id(:,2)==1) & (roi.id(:,3)==0) ...
                & depthBinMask(roi.id(:,1), i, depthBins);
    koCtrlResp = zResp(koCtrlIdx, :);
    [~, koCtrlSort] = sort(roi.repRel(koCtrlIdx, stimSize), 'descend');
    koCtrlSort = koCtrlSort(1 : round(numel(koCtrlSort)/2));
    koCtrl(i).resp = koCtrlResp(koCtrlSort, :);
    koCtrlRep(i).vals = roi.repRel(koCtrlIdx, stimSize);
    koCtrlPow(i).vals = roi.f1Pow(koCtrlIdx, stimSize);

    % KO APb
    koApbIdx = (roi.id(:,2)==1) & (roi.id(:,3)==1) ...
               & depthBinMask(roi.id(:,1), i, depthBins);
    koApbResp = zResp(koApbIdx, :);
    [~, koApbSort] = sort(roi.repRel(koApbIdx, stimSize), 'descend');
    koApbSort = koApbSort(1 : round(numel(koApbSort)/2));
    koApb(i).resp = koApbResp(koApbSort, :);
    koApbRep(i).vals = roi.repRel(koApbIdx, stimSize);
    koApbPow(i).vals = roi.f1Pow(koApbIdx, stimSize);
end

%% (4) COMPUTE THE MEAN +/- SEM ENVELOPE FOR EACH BIN
% We'll create a struct with fields:
%   meanTrace, semTrace, envMin, envMax, envMed, range, center
% for each combination of genotype/condition and depth bin.

wtCtrlEnv = repmat(initEnvelopeStruct(), 1, nDepths);
wtApbEnv  = wtCtrlEnv;
koCtrlEnv = wtCtrlEnv;
koApbEnv  = wtCtrlEnv;

% Populate the structures using our local function 'traceEnvelope'
for i = 1:nDepths
    wtCtrlEnv(i) = traceEnvelope(wtCtrl(i).resp, nRoisIncl);
    wtApbEnv(i)  = traceEnvelope(wtApb(i).resp, nRoisIncl);
    koCtrlEnv(i) = traceEnvelope(koCtrl(i).resp, nRoisIncl);
    koApbEnv(i)  = traceEnvelope(koApb(i).resp, nRoisIncl);
end

%% (5) DETERMINE A "GLOBAL" Y-RANGE FROM LOCAL RANGES
% We'll use this single globalRange to set consistent y-limits in all subplots.
allRanges = [];
for i = 1:nDepths
    allRanges(end+1) = wtCtrlEnv(i).range; %#ok<AGROW>
    allRanges(end+1) = wtApbEnv(i).range;
    allRanges(end+1) = koCtrlEnv(i).range;
    allRanges(end+1) = koApbEnv(i).range;
end
globalRange = max(allRanges);

%% (6) PLOT EACH BIN WITH THE SAME TOTAL Y-RANGE (FIGURE 1)
% Layout: nDepths rows x 4 columns (WT Ctrl, WT APb, KO Ctrl, KO APb)

figure(1);  clf
nRows = nDepths;  
nCols = 4;

for i = 1:nDepths
    % === WT CTRL (column 1) ===
    subplot(nRows, nCols, (i-1)*nCols + 1)
    plotMeanSemEnvelope(wtCtrlEnv(i));
    axis tight
    setYlimUsingRange(wtCtrlEnv(i), globalRange)
    title(sprintf('WT Ctrl, depth %.2f%%', depthCent(i)))

    % === WT APb (column 2) ===
    subplot(nRows, nCols, (i-1)*nCols + 2)
    plotMeanSemEnvelope(wtApbEnv(i));
    axis tight
    setYlimUsingRange(wtApbEnv(i), globalRange)
    title(sprintf('WT Apb, depth %.2f%%', depthCent(i)))

    % === KO CTRL (column 3) ===
    subplot(nRows, nCols, (i-1)*nCols + 3)
    plotMeanSemEnvelope(koCtrlEnv(i));
    axis tight
    setYlimUsingRange(koCtrlEnv(i), globalRange)
    title(sprintf('KO Ctrl, depth %.2f%%', depthCent(i)))

    % === KO APb (column 4) ===
    subplot(nRows, nCols, (i-1)*nCols + 4)
    plotMeanSemEnvelope(koApbEnv(i));
    axis tight
    setYlimUsingRange(koApbEnv(i), globalRange)
    title(sprintf('KO Apb, depth %.2f%%', depthCent(i)))
end

%% (7) PLOT HISTOGRAMS OF roi.repRel (FIGURE 2)
%   - Bins from -1 to 1 in steps of 0.02
%   - Layout is the same: nDepths rows, 4 columns
%   - 'Normalization' = 'probability' so that areas sum to 1

figure(2); clf
binEdgesRepRel = -1:0.02:1;
nRows = nDepths;  
nCols = 4;

for i = 1:nDepths
    % --- WT CTRL (column 1) ---
    subplot(nRows, nCols, (i-1)*nCols + 1)
    histogram(wtCtrlRep(i).vals, 'BinEdges', binEdgesRepRel, 'Normalization', 'probability');
    title(sprintf('WT Ctrl, depth %.2f%%', depthCent(i)))
    box off
    xlim([-0.25 1])
    xticks([0 0.5 1])

    % --- WT APb (column 2) ---
    subplot(nRows, nCols, (i-1)*nCols + 2)
    histogram(wtApbRep(i).vals, 'BinEdges', binEdgesRepRel, 'Normalization', 'probability');
    title(sprintf('WT Apb, depth %.2f%%', depthCent(i)))
    box off
    xlim([-0.25 1])
    xticks([0 0.5 1])

    % --- KO CTRL (column 3) ---
    subplot(nRows, nCols, (i-1)*nCols + 3)
    histogram(koCtrlRep(i).vals, 'BinEdges', binEdgesRepRel, 'Normalization', 'probability');
    title(sprintf('KO Ctrl, depth %.2f%%', depthCent(i)))
    box off
    xlim([-0.25 1])
    xticks([0 0.5 1])

    % --- KO APb (column 4) ---
    subplot(nRows, nCols, (i-1)*nCols + 4)
    histogram(koApbRep(i).vals, 'BinEdges', binEdgesRepRel, 'Normalization', 'probability');
    title(sprintf('KO Apb, depth %.2f%%', depthCent(i)))
    box off
    xlim([-0.25 1])
    xticks([0 0.5 1])
end

%% (8) PLOT HISTOGRAMS OF roi.f1Pow (FIGURE 3)
%   - Bins from 0 to 0.6 in steps of 0.02
%   - Same layout as above: nDepths rows x 4 columns
%   - 'Normalization' = 'probability'

figure(3); clf
binEdgesF1Pow = 0:0.02:0.6;
nRows = nDepths;  
nCols = 4;

for i = 1:nDepths
    % --- WT CTRL (column 1) ---
    subplot(nRows, nCols, (i-1)*nCols + 1)
    histogram(wtCtrlPow(i).vals, 'BinEdges', binEdgesF1Pow, 'Normalization', 'probability');
    title(sprintf('WT Ctrl f1Pow, depth %.2f%%', depthCent(i)))
    box off
    xlim([0 0.6])

    % --- WT APb (column 2) ---
    subplot(nRows, nCols, (i-1)*nCols + 2)
    histogram(wtApbPow(i).vals, 'BinEdges', binEdgesF1Pow, 'Normalization', 'probability');
    title(sprintf('WT Apb f1Pow, depth %.2f%%', depthCent(i)))
    box off
    xlim([0 0.6])

    % --- KO CTRL (column 3) ---
    subplot(nRows, nCols, (i-1)*nCols + 3)
    histogram(koCtrlPow(i).vals, 'BinEdges', binEdgesF1Pow, 'Normalization', 'probability');
    title(sprintf('KO Ctrl f1Pow, depth %.2f%%', depthCent(i)))
    box off
    xlim([0 0.6])

    % --- KO APb (column 4) ---
    subplot(nRows, nCols, (i-1)*nCols + 4)
    histogram(koApbPow(i).vals, 'BinEdges', binEdgesF1Pow, 'Normalization', 'probability');
    title(sprintf('KO Apb f1Pow, depth %.2f%%', depthCent(i)))
    box off
    xlim([0 0.6])
end

%% -------------------------------------------------------------------------
%                           LOCAL FUNCTIONS
% -------------------------------------------------------------------------

function mask = depthBinMask(depth, i, depthBins)
% depthBinMask  Returns a logical mask for ROIs that fall into
% the i-th bin defined by depthBins.
%
% Inputs:
%   depth     - Single column vector of ROI depths
%   i         - Which bin index to evaluate
%   depthBins - Array of bin boundaries
%
% Output:
%   mask      - Logical array of same length as 'depth'

nDepthBins = numel(depthBins);
if i == 1
    mask = (depth < depthBins(1));
elseif i <= nDepthBins
    mask = (depth >= depthBins(i-1)) & (depth < depthBins(i));
else
    mask = (depth >= depthBins(end));
end
end

function envStruct = initEnvelopeStruct()
% initEnvelopeStruct  Returns an empty struct with the fields
% we plan to fill for the response envelope statistics.
%
% Output:
%   envStruct - Struct with fields:
%       meanTrace, semTrace, envMin, envMax, envMed, range, center

envStruct = struct('meanTrace',[], 'semTrace',[], ...
                   'envMin',[], 'envMax',[], 'envMed',[], ...
                   'range',[], 'center',[]);
end

function out = traceEnvelope(respMat, nRoisIncl)
% traceEnvelope  Computes the mean +/- SEM envelope for up to nRoisIncl rows.
%
% Inputs:
%   respMat   - A matrix of size (nROIs x nTime) containing the responses
%   nRoisIncl - Maximum number of ROIs to include in the envelope calculation
%
% Output:
%   out       - Struct with fields (from initEnvelopeStruct):
%       .meanTrace, .semTrace, .envMin, .envMax, .envMed, .range, .center

out = initEnvelopeStruct();

% If the matrix is empty, set all fields to zero or empty and return
if isempty(respMat)
    out.envMin  = 0;
    out.envMax  = 0;
    out.envMed  = 0;
    out.range   = 0;
    out.center  = 0;
    return
end

% If there are more than nRoisIncl rows, truncate to the top nRoisIncl
nResp = size(respMat,1);
if nResp > nRoisIncl
    respMat = respMat(1:nRoisIncl, :);
end

% Compute mean and SEM across the ROI dimension
out.meanTrace = mean(respMat, 1);
out.semTrace  = sem(respMat, 1);

% Compute lower and upper envelope
lower = out.meanTrace - out.semTrace;
upper = out.meanTrace + out.semTrace;
out.envMin = min(lower);
out.envMax = max(upper);

% Compute median of the mean trace, total range, and center
out.envMed = median(out.meanTrace);
out.range  = out.envMax - out.envMin;
out.center = 0.5 * (out.envMax + out.envMin);
end

function plotMeanSemEnvelope(env)
% plotMeanSemEnvelope  Plots a mean ± SEM trace as a shaded region.
%
% Input:
%   env - Struct containing .meanTrace and .semTrace
%         (fields from initEnvelopeStruct)

% Return silently if there's no data
if isempty(env.meanTrace), return; end

xVals = 1:length(env.meanTrace);
shadePlot(xVals, env.meanTrace, env.semTrace, [0 0 0]);
xlim('tight')
end

function setYlimUsingRange(env, globalRange)
% setYlimUsingRange  Sets the y-limits around the envelope center using a global range.
%
% Inputs:
%   env         - Envelope struct containing .center
%   globalRange - The maximum range across all envelopes

if isempty(env.meanTrace), return; end
halfG = globalRange / 2;
yCenter = env.center;
ylim([yCenter - halfG,  yCenter + halfG])
end

function val = sem(mat, dim)
% sem  Computes the standard error of the mean along dimension 'dim'.
%
% Inputs:
%   mat - Data matrix
%   dim - Dimension along which to compute SEM (default = 1)
%
% Output:
%   val - SEM of the data along the specified dimension

if nargin < 2, dim = 1; end
val = std(mat, 0, dim) ./ sqrt(size(mat, dim));
end
