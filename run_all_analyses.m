%% RUN_ALL_ANALYSES - Master script to run all analyses
%
% This script runs all analysis scripts in sequence and generates
% all figures from the Soto et al. 2025 manuscript.
%
% USAGE:
%   1. Ensure iGluSnFR_IPL.mat is in the current directory
%   2. Run this script: run_all_analyses
%   3. Figures will be displayed and optionally saved to output/ directory
%
% CONFIGURATION:
%   Set saveFigures = true to save figures automatically
%   Set closeAfterSave = true to close figures after saving
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

%% Configuration
clear; close all; clc;

% Save figures to output directory?
saveFigures = false;  % Set to true to save figures

% Close figures after saving? (useful for batch processing)
closeAfterSave = false;

% Output directory for saved figures
outputDir = 'output';

%% Setup
fprintf('========================================\n');
fprintf('  iGluSnFR IPL Analysis - Full Run\n');
fprintf('  Soto et al. 2025\n');
fprintf('========================================\n\n');

% Add src directories to path
addpath(genpath('src'));

% Check for data file
if ~exist('iGluSnFR_IPL.mat', 'file')
    error('Data file iGluSnFR_IPL.mat not found. Please place it in the current directory.');
end

% Create output directory if needed
if saveFigures && ~exist(outputDir, 'dir')
    mkdir(outputDir);
    fprintf('Created output directory: %s\n', outputDir);
end

%% Load and Validate Data
fprintf('Loading data...\n');
load('iGluSnFR_IPL.mat');

fprintf('Validating data structure...\n');
validateRoiStructure(roi);
fprintf('\n');

%% Run Analysis 1: Main iGluSnFR IPL Analysis
fprintf('========================================\n');
fprintf('Running analyze_iGluSnFR_IPL.m\n');
fprintf('(Generates 4 figures)\n');
fprintf('========================================\n');

try
    analyze_iGluSnFR_IPL;
    fprintf('✓ analyze_iGluSnFR_IPL completed successfully\n\n');
    
    % Save figures if requested
    if saveFigures
        for figNum = 1:4
            if ishandle(figNum)
                figure(figNum);
                filename = sprintf('%s/iGluSnFR_IPL_fig%d', outputDir, figNum);
                saveas(gcf, [filename '.fig']);
                saveas(gcf, [filename '.png']);
                print(gcf, [filename '_hires'], '-dpng', '-r300');
                fprintf('  Saved Figure %d\n', figNum);
                
                if closeAfterSave
                    close(figNum);
                end
            end
        end
        fprintf('\n');
    end
catch ME
    fprintf('✗ ERROR in analyze_iGluSnFR_IPL:\n');
    fprintf('  %s\n\n', ME.message);
    rethrow(ME);
end

%% Run Analysis 2: Depth-Binned Analysis
fprintf('========================================\n');
fprintf('Running analyze_iGluSnFR_IPL_depth.m\n');
fprintf('(Generates 3 figures)\n');
fprintf('========================================\n');

try
    % Clear previous workspace variables except roi
    clearvars -except roi saveFigures closeAfterSave outputDir
    
    % Re-add paths
    addpath(genpath('src'));
    
    analyze_iGluSnFR_IPL_depth;
    fprintf('✓ analyze_iGluSnFR_IPL_depth completed successfully\n\n');
    
    % Save figures if requested (Figures 1-3 from depth analysis)
    if saveFigures
        for figNum = 1:3
            figHandle = figure(figNum);
            if ishandle(figHandle)
                filename = sprintf('%s/iGluSnFR_IPL_depth_fig%d', outputDir, figNum);
                saveas(figHandle, [filename '.fig']);
                saveas(figHandle, [filename '.png']);
                print(figHandle, [filename '_hires'], '-dpng', '-r300');
                fprintf('  Saved Depth Figure %d\n', figNum);
                
                if closeAfterSave
                    close(figHandle);
                end
            end
        end
        fprintf('\n');
    end
catch ME
    fprintf('✗ ERROR in analyze_iGluSnFR_IPL_depth:\n');
    fprintf('  %s\n\n', ME.message);
    rethrow(ME);
end

%% Summary
fprintf('========================================\n');
fprintf('All analyses completed successfully!\n');
fprintf('========================================\n\n');

fprintf('Generated figures:\n');
fprintf('  From analyze_iGluSnFR_IPL.m:\n');
fprintf('    Figure 1: Polarity vs IPL Depth\n');
fprintf('    Figure 2: Response Heatmaps (8 subplots)\n');
fprintf('    Figure 3: Mean ± SEM Shade Plots (8 subplots)\n');
fprintf('    Figure 4: Power and Reliability vs Depth (4 subplots)\n\n');

fprintf('  From analyze_iGluSnFR_IPL_depth.m:\n');
fprintf('    Figure 1: Mean ± SEM Envelopes by Depth Bin\n');
fprintf('    Figure 2: Reliability Histograms by Depth\n');
fprintf('    Figure 3: Fundamental Power Histograms by Depth\n\n');

if saveFigures
    fprintf('Figures saved to: %s/\n', outputDir);
    fprintf('  - .fig format (MATLAB figures)\n');
    fprintf('  - .png format (standard resolution)\n');
    fprintf('  - _hires.png (300 DPI publication quality)\n\n');
end

fprintf('Analysis complete. Review figures for results.\n');
fprintf('========================================\n');
