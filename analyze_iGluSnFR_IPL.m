% ANALYZE_IGLUSNFR_IPL
%
% This script analyzes and visualizes iGluSnFR signals from the inner
% plexiform layer (IPL). It uses data in a structure called 'roi', which
% should be loaded from the file 'iGluSnFR_IPL.mat'. 
%
% Requirements:
%   - The variable 'roi' must be in the current workspace.
%   - 'roi' has the following fields:
%       roi.id     -> [nRois x 3] matrix with ROI metadata:
%                     Column 1: IPL depth (0=OFF layer, 1=ON layer)
%                     Column 2: genotype (0=WT, 1=KO)
%                     Column 3: condition (0=Ctrl, 1=APB)
%       roi.resp   -> 4D array: (time x repeats x stimSize x nRois)
%       roi.repRel -> [nRois x nStimSizes], repeat reliability measure
%       roi.polIdx -> [nRois x nStimSizes], polarity index
%       roi.f1Pow  -> [nRois x nStimSizes], first-harmonic power
%   - Custom functions required (in src/ directory):
%       sem(...)       -> standard error of the mean
%       shadePlot(...) -> for plotting mean ± SEM shading
%       computeZScores(...) -> compute z-scored responses
%       defineExperimentalGroups(...) -> create group indices
%
% Figures:
%   1) Polarity vs. IPL Depth
%   2) Heatmaps of z-scored responses
%   3) Mean ± SEM shade plots (same ordering as Figure 2)
%   4) Reliability and power vs. IPL depth
%
% Author: Daniel Kerschensteiner
% Date:  01/08/2025
% Updated: 02/15/2025 - Refactored with constants and shared functions

%% ========== CONFIGURATION AND CONSTANTS ==========

% Add src directories to path
addpath(genpath('src'));

% Analysis parameters
FRAME_RATE_HZ = 16.667;          % Frame rate for time conversion
STIM_SIZE = 1;                   % Stimulus size index to analyze
WT_RELIABILITY_THRESH = 0.4;     % Reliability threshold for WT ROIs
KO_RELIABILITY_THRESH = 0.4;     % Reliability threshold for KO ROIs
IPL_DEPTH_DIVIDER = 0.5;         % OFF/ON boundary (0=OFF, 1=ON)

% Depth binning parameters
DEPTH_BINS = 0.2:0.1:0.8;        % Bin edges for depth analysis

% Color definitions
COLOR_WT = [0, 0, 0];            % Black for wild-type
COLOR_KO = [0, 180/255, 0];      % Green for knockout
COLOR_APB = [0.5, 0.5, 0.5];     % Gray for APB condition

% Heatmap display parameters
HEATMAP_ZLIM = [-2, 4];          % Z-score color limits

%% Check if 'roi' exists and validate
if ~exist('roi','var') || isempty(roi)
    error('The variable "roi" is not found in the workspace. Load iGluSnFR_IPL.mat first.');
end

% Validate data structure
validateRoiStructure(roi);

%% ========== 1. DEFINING GROUP INDICES ==========

% Define all experimental groups using shared function
groups = defineExperimentalGroups(roi);

%% ========== 2. POLARITY INDEX AS A FUNCTION OF IPL DEPTH (FIGURE 1) ==========

% Calculate depth bin centers
depthCent = DEPTH_BINS + 0.5 * mean(diff(DEPTH_BINS));
depthCent(end) = [];
nDepths = numel(depthCent);

% Pre-allocate arrays
wtPolIdx  = zeros(nDepths,1);
wtPolIdxE = zeros(nDepths,1);
koPolIdx  = zeros(nDepths,1);
koPolIdxE = zeros(nDepths,1);

% Define reliable ROIs for each genotype
relWtCtrl = groups.wtCtrl & roi.repRel(:,STIM_SIZE) > WT_RELIABILITY_THRESH;
relKoCtrl = groups.koCtrl & roi.repRel(:,STIM_SIZE) > KO_RELIABILITY_THRESH;

% Calculate polarity index by depth bin
for i=1:nDepths
    currWt = relWtCtrl & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    wtPolIdx(i)  = mean(roi.polIdx(currWt,STIM_SIZE));
    wtPolIdxE(i) = sem(roi.polIdx(currWt,STIM_SIZE));

    currKo = relKoCtrl & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    koPolIdx(i)  = mean(roi.polIdx(currKo,STIM_SIZE));
    koPolIdxE(i) = sem(roi.polIdx(currKo,STIM_SIZE));
end

% -- Figure 1: Polarity vs. IPL Depth --
hFigPol = createNamedFigure('Polarity vs. IPL Depth', 1);

errorbar(depthCent*100, wtPolIdx, wtPolIdxE,...
    'Color', COLOR_WT, 'LineStyle', 'none', 'Marker', 'o', 'CapSize', 0)
hold on
errorbar(depthCent*100, koPolIdx, koPolIdxE,...
    'Color', COLOR_KO, 'LineStyle', 'none', 'Marker', 'o', 'CapSize', 0)
xline(IPL_DEPTH_DIVIDER*100, '--k')
box off
xlabel('IPL depth (%)')
ylabel('Polarity')
title('Polarity vs. IPL Depth')
legend({'WT Ctrl', 'KO Ctrl'}, 'Location', 'best')

%% ========== 3. RESPONSE HEATMAPS SORTED BY REPEAT RELIABILITY (FIGURE 2) ==========

% Compute z-scored responses using shared function
zResp = computeZScores(roi, STIM_SIZE);

% Select ROIs for each group (top 50% most reliable) 
% Select ROIs for each group (top 50% most reliable)

% WT ON CTRL
wtOnCtrlResp = zResp(groups.wtOnCtrl,:);
[~, wtOnCtrlSort] = sort(roi.repRel(groups.wtOnCtrl,STIM_SIZE), 'descend'); 
wtOnCtrlSort = wtOnCtrlSort(1 : round(numel(wtOnCtrlSort)/2));

% WT ON APB
wtOnApbResp = zResp(groups.wtOnApb,:);
[~, wtOnApbSort] = sort(roi.repRel(groups.wtOnApb,STIM_SIZE), 'descend'); 
wtOnApbSort = wtOnApbSort(1 : round(numel(wtOnApbSort)/2));

% WT OFF CTRL
wtOffCtrlResp = zResp(groups.wtOffCtrl,:);
[~, wtOffCtrlSort] = sort(roi.repRel(groups.wtOffCtrl,STIM_SIZE), 'descend');
wtOffCtrlSort = wtOffCtrlSort(1 : round(numel(wtOffCtrlSort)/2));

% WT OFF APB
wtOffApbResp = zResp(groups.wtOffApb,:);
[~, wtOffApbSort] = sort(roi.repRel(groups.wtOffApb,STIM_SIZE), 'descend'); 
wtOffApbSort = wtOffApbSort(1 : round(numel(wtOffApbSort)/2));

% KO ON CTRL
koOnCtrlResp = zResp(groups.koOnCtrl,:);
[~, koOnCtrlSort] = sort(roi.repRel(groups.koOnCtrl,STIM_SIZE), 'descend'); 
koOnCtrlSort = koOnCtrlSort(1 : round(numel(koOnCtrlSort)/2));

% KO ON APB
koOnApbResp = zResp(groups.koOnApb,:);
[~, koOnApbSort] = sort(roi.repRel(groups.koOnApb,STIM_SIZE), 'descend'); 
koOnApbSort = koOnApbSort(1 : round(numel(koOnApbSort)/2));

% KO OFF CTRL
koOffCtrlResp = zResp(groups.koOffCtrl,:);
[~, koOffCtrlSort] = sort(roi.repRel(groups.koOffCtrl,STIM_SIZE), 'descend'); 
koOffCtrlSort = koOffCtrlSort(1 : round(numel(koOffCtrlSort)/2));

% KO OFF APB
koOffApbResp = zResp(groups.koOffApb,:);
[~, koOffApbSort] = sort(roi.repRel(groups.koOffApb,STIM_SIZE), 'descend'); 
koOffApbSort = koOffApbSort(1 : round(numel(koOffApbSort)/2));

% Create colormaps (white->black for WT, white->green for KO)
start_green = [1, 1, 1]; 
end_green   = [0, 180/255, 0]; 
start_black = [1, 1, 1];
end_black   = [0, 0, 0];
steps = 256;
darkGreenMap = zeros(steps, 3);
blackMap     = zeros(steps, 3);
for c = 1:3
    darkGreenMap(:, c) = linspace(start_green(c), end_green(c), steps);
    blackMap(:, c)     = linspace(start_black(c), end_black(c), steps);
end

% -- Figure 2: Heatmaps --
hFigHeat = createNamedFigure('Response Heatmaps', 2);

% Top row:   WT OFF CTRL, WT OFF APB, WT ON CTRL, WT ON APB
% Bottom row:KO OFF CTRL, KO OFF APB, KO ON CTRL, KO ON APB

subplot(2,4,1)
imagesc(wtOffCtrlResp(wtOffCtrlSort,:), HEATMAP_ZLIM)
colormap(gca, blackMap)
ylabel('ROIs (#)')
title('WT OFF CTRL')

subplot(2,4,2)
imagesc(wtOffApbResp(wtOffApbSort,:), HEATMAP_ZLIM)
colormap(gca, blackMap)
title('WT OFF APB')

subplot(2,4,3)
imagesc(wtOnCtrlResp(wtOnCtrlSort,:), HEATMAP_ZLIM)
colormap(gca, blackMap)
title('WT ON CTRL')

subplot(2,4,4)
imagesc(wtOnApbResp(wtOnApbSort,:), HEATMAP_ZLIM)
colormap(gca, blackMap)
title('WT ON APB')

subplot(2,4,5)
imagesc(koOffCtrlResp(koOffCtrlSort,:), HEATMAP_ZLIM)
colormap(gca, darkGreenMap)
ylabel('ROIs (#)')
title('KO OFF CTRL')

subplot(2,4,6)
imagesc(koOffApbResp(koOffApbSort,:), HEATMAP_ZLIM)
colormap(gca, darkGreenMap)
title('KO OFF APB')

subplot(2,4,7)
imagesc(koOnCtrlResp(koOnCtrlSort,:), HEATMAP_ZLIM)
colormap(gca, darkGreenMap)
title('KO ON CTRL')

subplot(2,4,8)
imagesc(koOnApbResp(koOnApbSort,:), HEATMAP_ZLIM)
colormap(gca, darkGreenMap)
title('KO ON APB')

% Convert heatmap x-axis from datapoints to time (s)
nTimePoints = size(zResp,2);
xVals = (0:nTimePoints-1) / FRAME_RATE_HZ;
for sp = 1:8
    subplot(2,4,sp)
    xticks(linspace(1,nTimePoints,5))
    xLabVals = linspace(0,xVals(end),5);
    xticklabels(arrayfun(@(v) sprintf('%.1f',v), xLabVals, 'UniformOutput',false))
    xlabel('Time (s)')
end

%% ========== 4. SHADEPLOTS (FIGURE 3) WITH THE SAME ORDER AS FIGURE 2 ==========

timeBins = (0:(size(zResp,2)-1)) / FRAME_RATE_HZ;

% -- Figure 3: Shade Plots --
hFigShade = createNamedFigure('Mean ± SEM Shade Plots', 3);

% REORDER to match Figure 2 EXACTLY:
% 1) WT OFF CTRL, 2) WT OFF APB, 3) WT ON CTRL, 4) WT ON APB,
% 5) KO OFF CTRL, 6) KO OFF APB, 7) KO ON CTRL, 8) KO ON APB

subplot(2,4,1)
shadePlot(timeBins, mean(wtOffCtrlResp), sem(wtOffCtrlResp), COLOR_WT)
ylabel('Fz')
title('WT OFF CTRL')

subplot(2,4,2)
shadePlot(timeBins, mean(wtOffApbResp), sem(wtOffApbResp), COLOR_WT)
title('WT OFF APB')

subplot(2,4,3)
shadePlot(timeBins, mean(wtOnCtrlResp), sem(wtOnCtrlResp), COLOR_WT)
title('WT ON CTRL')

subplot(2,4,4)
shadePlot(timeBins, mean(wtOnApbResp), sem(wtOnApbResp), COLOR_WT)
title('WT ON APB')

subplot(2,4,5)
shadePlot(timeBins, mean(koOffCtrlResp), sem(koOffCtrlResp), COLOR_KO)
ylabel('Fz')
title('KO OFF CTRL')

subplot(2,4,6)
shadePlot(timeBins, mean(koOffApbResp), sem(koOffApbResp), COLOR_KO)
title('KO OFF APB')

subplot(2,4,7)
shadePlot(timeBins, mean(koOnCtrlResp), sem(koOnCtrlResp), COLOR_KO)
title('KO ON CTRL')

subplot(2,4,8)
shadePlot(timeBins, mean(koOnApbResp), sem(koOnApbResp), COLOR_KO)
title('KO ON APB')

% Label x-axis for all subplots
for sp = 1:8
    subplot(2,4,sp)
    xlabel('Time (s)')
end

%% ========== 5. POWER AND RELIABILITY BY DEPTH (FIGURE 4) ==========

% Calculate depth bin centers
depthCent = DEPTH_BINS + 0.5*mean(diff(DEPTH_BINS));
depthCent(end) = [];
nDepths = numel(depthCent);

% Pre-allocate arrays for each group
wtCtrlRel  = zeros(nDepths,1);
wtCtrlRelE = zeros(nDepths,1);
wtCtrlPow  = zeros(nDepths,1);
wtCtrlPowE = zeros(nDepths,1);

wtApbRel  = zeros(nDepths,1);
wtApbRelE = zeros(nDepths,1);
wtApbPow  = zeros(nDepths,1);
wtApbPowE = zeros(nDepths,1);

koCtrlRel  = zeros(nDepths,1);
koCtrlRelE = zeros(nDepths,1);
koCtrlPow  = zeros(nDepths,1);
koCtrlPowE = zeros(nDepths,1);

koApbRel  = zeros(nDepths,1);
koApbRelE = zeros(nDepths,1);
koApbPow  = zeros(nDepths,1);
koApbPowE = zeros(nDepths,1);

% Calculate metrics for each depth bin
for i=1:nDepths
    currWtCtrl = groups.wtCtrl & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    wtCtrlRel(i)  = mean(roi.repRel(currWtCtrl,STIM_SIZE));
    wtCtrlRelE(i) = sem(roi.repRel(currWtCtrl,STIM_SIZE));
    wtCtrlPow(i)  = mean(roi.f1Pow(currWtCtrl,STIM_SIZE));
    wtCtrlPowE(i) = sem(roi.f1Pow(currWtCtrl,STIM_SIZE));

    currWtApb = groups.wtApb & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    wtApbRel(i)  = mean(roi.repRel(currWtApb,STIM_SIZE));
    wtApbRelE(i) = sem(roi.repRel(currWtApb,STIM_SIZE));
    wtApbPow(i)  = mean(roi.f1Pow(currWtApb,STIM_SIZE));
    wtApbPowE(i) = sem(roi.f1Pow(currWtApb,STIM_SIZE));

    currKoCtrl = groups.koCtrl & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    koCtrlRel(i)  = mean(roi.repRel(currKoCtrl,STIM_SIZE));
    koCtrlRelE(i) = sem(roi.repRel(currKoCtrl,STIM_SIZE));
    koCtrlPow(i)  = mean(roi.f1Pow(currKoCtrl,STIM_SIZE));
    koCtrlPowE(i) = sem(roi.f1Pow(currKoCtrl,STIM_SIZE));

    currKoApb = groups.koApb & (roi.id(:,1) > DEPTH_BINS(i)) & (roi.id(:,1) <= DEPTH_BINS(i+1));
    koApbRel(i)  = mean(roi.repRel(currKoApb,STIM_SIZE));
    koApbRelE(i) = sem(roi.repRel(currKoApb,STIM_SIZE));
    koApbPow(i)  = mean(roi.f1Pow(currKoApb,STIM_SIZE));
    koApbPowE(i) = sem(roi.f1Pow(currKoApb,STIM_SIZE));
end

% -- Figure 4: Power & Reliability --
hPowRel = createNamedFigure('Power & Reliability vs Depth', 4);

% Subplot 1: Reliability (WT)
subplot(1,4,1)
errorbar(depthCent*100, wtCtrlRel, wtCtrlRelE,...
    'Color', COLOR_WT, 'LineStyle', '-', 'CapSize', 0)
hold on
errorbar(depthCent*100, wtApbRel, wtApbRelE,...
    'Color', COLOR_APB, 'LineStyle', '-', 'CapSize', 0)
xline(IPL_DEPTH_DIVIDER*100, '--k')
box off
axis([20, 80, ...
    min([wtCtrlRel-wtCtrlRelE; wtApbRel-wtApbRelE]), ...
    max([wtCtrlRel+wtCtrlRelE; wtApbRel+wtApbRelE])])
xlabel('IPL depth (%)')
ylabel('Reliability (R)')
title('WT Reliability')
legend({'Ctrl', 'APB'}, 'Location', 'best')

% Subplot 2: Power (WT)
subplot(1,4,2)
errorbar(depthCent*100, wtCtrlPow, wtCtrlPowE,...
    'Color', COLOR_WT, 'LineStyle', '-', 'CapSize', 0)
hold on
errorbar(depthCent*100, wtApbPow, wtApbPowE,...
    'Color', COLOR_APB, 'LineStyle', '-', 'CapSize', 0)
xline(IPL_DEPTH_DIVIDER*100, '--k')
box off
axis([20, 80, ...
    min([wtCtrlPow-wtCtrlPowE; wtApbPow-wtApbPowE]), ...
    max([wtCtrlPow+wtCtrlPowE; wtApbPow+wtApbPowE])])
xlabel('IPL depth (%)')
ylabel('Power (rel.)')
title('WT Power')

% Subplot 3: Reliability (KO)
subplot(1,4,3)
errorbar(depthCent*100, koCtrlRel, koCtrlRelE,...
    'Color', COLOR_KO, 'LineStyle', '-', 'CapSize', 0)
hold on
errorbar(depthCent*100, koApbRel, koApbRelE,...
    'Color', [0, 0.5, 0], 'LineStyle', '-', 'CapSize', 0)
xline(IPL_DEPTH_DIVIDER*100, '--k')
box off
axis([20, 80, ...
    min([koCtrlRel-koCtrlRelE; koApbRel-koApbRelE]), ...
    max([koCtrlRel+koCtrlRelE; koApbRel+koApbRelE])])
xlabel('IPL depth (%)')
ylabel('Reliability (R)')
title('KO Reliability')

% Subplot 4: Power (KO)
subplot(1,4,4)
errorbar(depthCent*100, koCtrlPow, koCtrlPowE,...
    'Color', COLOR_KO, 'LineStyle', '-', 'CapSize', 0)
hold on
errorbar(depthCent*100, koApbPow, koApbPowE,...
    'Color', [0, 0.5, 0], 'LineStyle', '-', 'CapSize', 0)
xline(IPL_DEPTH_DIVIDER*100, '--k')
box off
axis([20, 80, ...
    min([koCtrlPow-koCtrlPowE; koApbPow-koApbPowE]), ...
    max([koCtrlPow+koCtrlPowE; koApbPow+koApbPowE])])
xlabel('IPL depth (%)')
ylabel('Power (rel.)')
title('KO Power')