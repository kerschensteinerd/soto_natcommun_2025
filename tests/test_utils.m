%% TEST_UTILS - Unit tests for utility functions
%
% This script tests the utility functions in src/ directory to ensure
% they work correctly with example data.
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

%% Setup
clear; close all; clc;
fprintf('=== Testing Utility Functions ===\n\n');

% Add src directories to path
addpath(genpath('src'));

% Create test data
nRois = 100;
nTime = 50;
nRepeats = 3;
nStimSizes = 2;

% Create synthetic roi structure
testRoi = struct();
testRoi.id = [rand(nRois, 1), ... % depths 0-1
              randi([0, 1], nRois, 1), ... % genotype 0 or 1
              randi([0, 1], nRois, 1)];    % condition 0 or 1
testRoi.resp = randn(nTime, nRepeats, nStimSizes, nRois) + 5;  % positive responses
testRoi.repRel = rand(nRois, nStimSizes);
testRoi.polIdx = rand(nRois, nStimSizes) * 2 - 1;  % -1 to 1
testRoi.f1Pow = rand(nRois, nStimSizes);

%% Test 1: validateRoiStructure
fprintf('Test 1: validateRoiStructure\n');
fprintf('---------------------------------\n');
try
    validateRoiStructure(testRoi);
    fprintf('✓ PASSED: Structure validation successful\n\n');
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 2: computeZScores
fprintf('Test 2: computeZScores\n');
fprintf('---------------------------------\n');
try
    zResp = computeZScores(testRoi, 1);
    
    % Check dimensions
    assert(size(zResp, 1) == nRois, 'Wrong number of ROIs');
    assert(size(zResp, 2) == nTime, 'Wrong number of time points');
    
    % Check that z-scores have reasonable values
    meanZ = mean(zResp(:));
    stdZ = std(zResp(:));
    
    fprintf('  Z-score statistics:\n');
    fprintf('    Mean: %.3f (expected ~0)\n', meanZ);
    fprintf('    Std:  %.3f\n', stdZ);
    fprintf('    Range: [%.2f, %.2f]\n', min(zResp(:)), max(zResp(:)));
    
    if abs(meanZ) < 1
        fprintf('✓ PASSED: Z-scores computed correctly\n\n');
    else
        fprintf('⚠ WARNING: Z-score mean is far from 0\n\n');
    end
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 3: defineExperimentalGroups
fprintf('Test 3: defineExperimentalGroups\n');
fprintf('---------------------------------\n');
try
    groups = defineExperimentalGroups(testRoi);
    
    % Check that groups are logical arrays
    assert(islogical(groups.wtCtrl), 'Groups must be logical');
    assert(length(groups.wtCtrl) == nRois, 'Wrong length');
    
    % Check that all ROIs are accounted for
    totalRois = sum(groups.wtCtrl) + sum(groups.wtApb) + ...
                sum(groups.koCtrl) + sum(groups.koApb);
    assert(totalRois == nRois, 'Not all ROIs accounted for');
    
    fprintf('  Group counts:\n');
    fprintf('    WT Ctrl:     %3d ROIs\n', sum(groups.wtCtrl));
    fprintf('    WT APB:      %3d ROIs\n', sum(groups.wtApb));
    fprintf('    KO Ctrl:     %3d ROIs\n', sum(groups.koCtrl));
    fprintf('    KO APB:      %3d ROIs\n', sum(groups.koApb));
    fprintf('    WT OFF Ctrl: %3d ROIs\n', sum(groups.wtOffCtrl));
    fprintf('    WT ON Ctrl:  %3d ROIs\n', sum(groups.wtOnCtrl));
    fprintf('    Total:       %3d ROIs\n', totalRois);
    fprintf('✓ PASSED: Experimental groups defined correctly\n\n');
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 4: binByDepth
fprintf('Test 4: binByDepth\n');
fprintf('---------------------------------\n');
try
    depthBins = 0.2:0.2:0.8;
    data = testRoi.polIdx(:, 1);
    depths = testRoi.id(:, 1);
    
    [binCenters, binnedData] = binByDepth(data, depths, depthBins);
    
    % Check outputs
    nBins = length(depthBins) + 1;
    assert(length(binCenters) == nBins, 'Wrong number of bin centers');
    assert(length(binnedData) == nBins, 'Wrong number of binned data cells');
    
    fprintf('  Bin information:\n');
    for i = 1:nBins
        fprintf('    Bin %d (center %.1f%%): %3d ROIs\n', ...
                i, binCenters(i), size(binnedData{i}, 1));
    end
    
    % Check that all ROIs are in some bin
    totalBinned = sum(cellfun(@(x) size(x,1), binnedData));
    assert(totalBinned == nRois, 'Not all ROIs binned');
    
    fprintf('✓ PASSED: Data binned correctly by depth\n\n');
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 5: sem
fprintf('Test 5: sem (standard error of mean)\n');
fprintf('---------------------------------\n');
try
    testData = randn(100, 10);  % 100 samples, 10 variables
    
    % Test dimension 1
    semVals1 = sem(testData, 1);
    expectedSem1 = std(testData, 0, 1) / sqrt(size(testData, 1));
    assert(all(abs(semVals1 - expectedSem1) < 1e-10), 'SEM dim 1 incorrect');
    
    % Test dimension 2
    semVals2 = sem(testData, 2);
    expectedSem2 = std(testData, 0, 2) / sqrt(size(testData, 2));
    assert(all(abs(semVals2 - expectedSem2) < 1e-10), 'SEM dim 2 incorrect');
    
    fprintf('  SEM range (dim 1): [%.4f, %.4f]\n', min(semVals1), max(semVals1));
    fprintf('  SEM range (dim 2): [%.4f, %.4f]\n', min(semVals2), max(semVals2));
    fprintf('✓ PASSED: SEM computed correctly\n\n');
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 6: createNamedFigure
fprintf('Test 6: createNamedFigure\n');
fprintf('---------------------------------\n');
try
    % Test basic creation
    hFig1 = createNamedFigure('Test Figure 1', 101);
    assert(ishandle(hFig1), 'Figure handle invalid');
    
    % Test without number
    hFig2 = createNamedFigure('Test Figure 2');
    assert(ishandle(hFig2), 'Figure handle invalid');
    
    % Close test figures
    close(hFig1);
    close(hFig2);
    
    fprintf('✓ PASSED: Named figures created correctly\n\n');
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Test 7: shadePlot
fprintf('Test 7: shadePlot\n');
fprintf('---------------------------------\n');
try
    % Create test figure
    hFig = createNamedFigure('shadePlot Test', 102);
    
    x = 1:50;
    y = sin(x/5);
    e = 0.1 * ones(size(x));
    color = [0, 0, 0];
    
    shadePlot(x, y, e, color);
    title('Test: shadePlot');
    xlabel('X'); ylabel('Y');
    
    fprintf('  Created test shadePlot (Figure 102)\n');
    fprintf('  Please visually inspect the figure\n');
    fprintf('✓ PASSED: shadePlot executed without error\n\n');
    
    % Optionally close
    pause(0.5);
    close(hFig);
catch ME
    fprintf('✗ FAILED: %s\n\n', ME.message);
end

%% Summary
fprintf('=================================\n');
fprintf('All utility function tests completed!\n');
fprintf('=================================\n');
