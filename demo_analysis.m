%% DEMO_ANALYSIS - Quick demonstration of analysis workflow
%
% This script demonstrates a simplified analysis workflow using
% the iGluSnFR IPL data. It's useful for understanding the data
% structure and basic analysis steps.
%
% USAGE:
%   1. Ensure iGluSnFR_IPL.mat is in the current directory
%   2. Run this script: demo_analysis
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

%% Setup
clear; close all; clc;
fprintf('=== iGluSnFR IPL Analysis Demo ===\n\n');

% Add src directories to path
addpath(genpath('src'));

%% Step 1: Load and Validate Data
fprintf('Step 1: Loading data...\n');
if ~exist('iGluSnFR_IPL.mat', 'file')
    error('Data file iGluSnFR_IPL.mat not found. Please ensure it is in the current directory.');
end

load('iGluSnFR_IPL.mat');
fprintf('  Data loaded successfully\n');

% Validate structure
fprintf('\nStep 2: Validating data structure...\n');
validateRoiStructure(roi);

%% Step 3: Define Experimental Groups
fprintf('\nStep 3: Defining experimental groups...\n');
groups = defineExperimentalGroups(roi);
fprintf('  Groups defined\n');

%% Step 4: Compute Z-Scores
fprintf('\nStep 4: Computing z-scored responses...\n');
stimSize = 1;
zResp = computeZScores(roi, stimSize);
fprintf('  Z-scores computed: [%d ROIs × %d time points]\n', size(zResp, 1), size(zResp, 2));

%% Step 5: Example Analysis - Mean Response by Group
fprintf('\nStep 5: Computing mean responses by group...\n');

% Calculate mean responses for each major group
wtCtrlMean = mean(zResp(groups.wtCtrl, :), 1);
wtApbMean  = mean(zResp(groups.wtApb, :), 1);
koCtrlMean = mean(zResp(groups.koCtrl, :), 1);
koApbMean  = mean(zResp(groups.koApb, :), 1);

% Calculate SEM
wtCtrlSem = sem(zResp(groups.wtCtrl, :), 1);
wtApbSem  = sem(zResp(groups.wtApb, :), 1);
koCtrlSem = sem(zResp(groups.koCtrl, :), 1);
koApbSem  = sem(zResp(groups.koApb, :), 1);

% Time axis (assuming 16.667 Hz frame rate)
timeAxis = (0:size(zResp, 2)-1) / 16.667;

fprintf('  Mean responses computed\n');

%% Step 6: Visualization
fprintf('\nStep 6: Creating visualizations...\n');

% Figure 1: Mean responses comparison
hFig1 = createNamedFigure('Demo: Mean Responses by Group', 1);

subplot(2, 2, 1)
shadePlot(timeAxis, wtCtrlMean, wtCtrlSem, [0, 0, 0]);
title(sprintf('WT Ctrl (n=%d)', sum(groups.wtCtrl)));
xlabel('Time (s)'); ylabel('Z-score');
ylim([-1, 3]);

subplot(2, 2, 2)
shadePlot(timeAxis, wtApbMean, wtApbSem, [0.5, 0.5, 0.5]);
title(sprintf('WT APB (n=%d)', sum(groups.wtApb)));
xlabel('Time (s)'); ylabel('Z-score');
ylim([-1, 3]);

subplot(2, 2, 3)
shadePlot(timeAxis, koCtrlMean, koCtrlSem, [0, 180/255, 0]);
title(sprintf('KO Ctrl (n=%d)', sum(groups.koCtrl)));
xlabel('Time (s)'); ylabel('Z-score');
ylim([-1, 3]);

subplot(2, 2, 4)
shadePlot(timeAxis, koApbMean, koApbSem, [0, 0.5, 0]);
title(sprintf('KO APB (n=%d)', sum(groups.koApb)));
xlabel('Time (s)'); ylabel('Z-score');
ylim([-1, 3]);

% Figure 2: Polarity vs Depth
hFig2 = createNamedFigure('Demo: Polarity vs IPL Depth', 2);

scatter(roi.id(groups.wtCtrl, 1)*100, roi.polIdx(groups.wtCtrl, stimSize), ...
        10, [0, 0, 0], 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
scatter(roi.id(groups.koCtrl, 1)*100, roi.polIdx(groups.koCtrl, stimSize), ...
        10, [0, 180/255, 0], 'filled', 'MarkerFaceAlpha', 0.3);
xline(50, '--r', 'LineWidth', 1.5);
xlabel('IPL Depth (%)');
ylabel('Polarity Index');
title('Polarity vs IPL Depth');
legend({'WT Ctrl', 'KO Ctrl', 'OFF/ON Boundary'}, 'Location', 'best');
ylim([-1, 1]);
box off;

% Figure 3: Reliability distribution
hFig3 = createNamedFigure('Demo: Reliability Distribution', 3);

histogram(roi.repRel(groups.wtCtrl, stimSize), 30, ...
          'FaceColor', [0, 0, 0], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
hold on;
histogram(roi.repRel(groups.koCtrl, stimSize), 30, ...
          'FaceColor', [0, 180/255, 0], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
xlabel('Repeat Reliability');
ylabel('Count');
title('Distribution of Repeat Reliability');
legend({'WT Ctrl', 'KO Ctrl'}, 'Location', 'northwest');
box off;

fprintf('  Figures created\n');

%% Step 7: Depth Binning Example
fprintf('\nStep 7: Binning data by depth...\n');

depthBins = 0.2:0.2:0.8;
[binCenters, binnedPolarity] = binByDepth(roi.polIdx(:, stimSize), roi.id(:, 1), depthBins);

% Calculate mean and SEM for each bin
nBins = length(binCenters);
meanPolByBin = zeros(1, nBins);
semPolByBin = zeros(1, nBins);

for i = 1:nBins
    if ~isempty(binnedPolarity{i})
        meanPolByBin(i) = mean(binnedPolarity{i});
        semPolByBin(i) = sem(binnedPolarity{i});
    end
end

% Figure 4: Polarity by depth bin
hFig4 = createNamedFigure('Demo: Polarity by Depth Bin', 4);

errorbar(binCenters, meanPolByBin, semPolByBin, ...
         'o-', 'Color', [0, 0, 0], 'LineWidth', 2, 'MarkerSize', 8, ...
         'MarkerFaceColor', [0, 0, 0], 'CapSize', 10);
xline(50, '--r', 'LineWidth', 1.5);
xlabel('IPL Depth (%)');
ylabel('Mean Polarity Index');
title('Mean Polarity by Depth Bin');
ylim([-1, 1]);
grid on;
box off;

fprintf('  Depth binning completed\n');

%% Summary
fprintf('\n=================================\n');
fprintf('Demo completed successfully!\n');
fprintf('\nFigures created:\n');
fprintf('  1. Mean Responses by Group\n');
fprintf('  2. Polarity vs IPL Depth\n');
fprintf('  3. Reliability Distribution\n');
fprintf('  4. Polarity by Depth Bin\n');
fprintf('\nNext steps:\n');
fprintf('  - Run analyze_iGluSnFR_IPL.m for full analysis\n');
fprintf('  - Run analyze_iGluSnFR_IPL_depth.m for depth-binned analysis\n');
fprintf('  - Or run run_all_analyses.m to generate all figures\n');
fprintf('=================================\n');
