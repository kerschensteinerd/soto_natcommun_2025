# Detailed Usage Guide

This document provides detailed examples and workflows for using the iGluSnFR IPL analysis code.

## Table of Contents
1. [Basic Workflow](#basic-workflow)
2. [Understanding the Data](#understanding-the-data)
3. [Customizing Parameters](#customizing-parameters)
4. [Interpreting Results](#interpreting-results)
5. [Advanced Usage](#advanced-usage)
6. [Troubleshooting](#troubleshooting)

## Basic Workflow

### Step 1: Load Data

```matlab
% Start MATLAB in the repository directory
cd /path/to/Soto2025_lrfn2-off-pathway

% Load the data file
load('iGluSnFR_IPL.mat')

% Verify the data loaded correctly
whos roi
```

You should see output like:
```
  Name      Size                  Bytes  Class     Attributes
  roi       1x1                   xxxxxx struct              
```

### Step 2: Inspect Data Structure

```matlab
% Check the structure fields
disp(fieldnames(roi))

% Check dimensions
fprintf('Number of ROIs: %d\n', size(roi.id, 1));
fprintf('Response dimensions: [%s]\n', num2str(size(roi.resp)));
fprintf('Number of stimulus sizes: %d\n', size(roi.resp, 3));
```

### Step 3: Run Analysis

```matlab
% Run main analysis (generates 4 figures)
analyze_iGluSnFR_IPL

% Run depth-binned analysis (generates 3 additional figures)
analyze_iGluSnFR_IPL_depth

% Or run everything at once
run_all_analyses
```

## Understanding the Data

### ROI Metadata (roi.id)

The `roi.id` matrix has 3 columns:

```matlab
% Column 1: IPL Depth (0 to 1)
depths = roi.id(:, 1);
histogram(depths, 20);
xlabel('IPL Depth'); ylabel('Count');
title('Distribution of ROI Depths');

% Column 2: Genotype (0=WT, 1=KO)
genotypes = roi.id(:, 2);
fprintf('Wild-type ROIs: %d\n', sum(genotypes == 0));
fprintf('Knockout ROIs: %d\n', sum(genotypes == 1));

% Column 3: Condition (0=Ctrl, 1=APB)
conditions = roi.id(:, 3);
fprintf('Control ROIs: %d\n', sum(conditions == 0));
fprintf('APB-treated ROIs: %d\n', sum(conditions == 1));
```

### Response Data (roi.resp)

The 4D response array has dimensions: `[time × repeats × stimSize × nRois]`

```matlab
% Get dimensions
[nTime, nRepeats, nStimSizes, nRois] = size(roi.resp);
fprintf('Time points per trial: %d\n', nTime);
fprintf('Repeats per condition: %d\n', nRepeats);
fprintf('Stimulus sizes: %d\n', nStimSizes);
fprintf('Total ROIs: %d\n', nRois);

% Plot example ROI response
roiIdx = 1;
stimIdx = 1;
figure;
plot(squeeze(roi.resp(:, :, stimIdx, roiIdx)));
xlabel('Time (frames)'); ylabel('Response');
title(sprintf('ROI %d Responses (all repeats)', roiIdx));

% Convert time to seconds (assuming 16.667 Hz frame rate)
timeInSeconds = (0:nTime-1) / 16.667;
```

### Reliability Metric (roi.repRel)

Repeat reliability measures consistency across trial repeats:

```matlab
% Plot reliability distribution
stimSize = 1;
figure;
histogram(roi.repRel(:, stimSize), 50);
xlabel('Repeat Reliability'); ylabel('Count');
title('Distribution of Repeat Reliability');

% Identify highly reliable ROIs
reliableIdx = roi.repRel(:, stimSize) > 0.4;
fprintf('Highly reliable ROIs (>0.4): %d / %d\n', sum(reliableIdx), nRois);
```

### Polarity Index (roi.polIdx)

Polarity indicates preference for ON vs OFF responses:

```matlab
% Plot polarity by depth
figure;
scatter(roi.id(:,1)*100, roi.polIdx(:,1), 10, 'filled', 'MarkerFaceAlpha', 0.3);
xlabel('IPL Depth (%)'); ylabel('Polarity Index');
title('Polarity vs IPL Depth');
xline(50, '--r', 'OFF/ON Boundary');
ylim([-1, 1]);
```

## Customizing Parameters

### Modifying Reliability Thresholds

In `analyze_iGluSnFR_IPL.m`:

```matlab
% Default values
wtRelThresh = 0.4;  % Wild-type reliability threshold
koRelThresh = 0.4;  % Knockout reliability threshold

% To be more stringent (fewer, more reliable ROIs):
wtRelThresh = 0.6;
koRelThresh = 0.6;

% To be more permissive (more ROIs, potentially noisier):
wtRelThresh = 0.2;
koRelThresh = 0.2;
```

### Changing Depth Bins

In `analyze_iGluSnFR_IPL_depth.m`:

```matlab
% Default: 6 bins from 0.2 to 0.8
depthBins = 0.2:0.1:0.8;

% For finer depth resolution (more bins):
depthBins = 0.1:0.05:0.9;

% For specific custom bins:
depthBins = [0.3, 0.4, 0.5, 0.6, 0.7];  % 6 bins total

% For OFF/ON comparison only:
depthBins = [0.5];  % 2 bins: <0.5 (OFF) and >0.5 (ON)
```

### Adjusting Color Schemes

```matlab
% In analyze_iGluSnFR_IPL.m, modify color definitions:

% Wild-type color (default: black)
COLOR_WT = [0, 0, 0];

% Knockout color (default: green)
COLOR_KO = [0, 180/255, 0];

% APB condition color (default: gray)
COLOR_APB = [0.5, 0.5, 0.5];
```

### Selecting Stimulus Size

```matlab
% Default analyzes stimulus size 1
stimSize = 1;

% To analyze a different stimulus size:
stimSize = 2;  % or 3, etc., if available

% To analyze all stimulus sizes:
for stimSize = 1:size(roi.resp, 3)
    fprintf('\n=== Analyzing Stimulus Size %d ===\n', stimSize);
    % Run analysis here
end
```

## Interpreting Results

### Figure 1: Polarity vs. IPL Depth

- **X-axis**: IPL depth (20-80%, excluding boundaries)
- **Y-axis**: Mean polarity index (-1 to +1)
- **Vertical line at 50%**: OFF/ON sublayer boundary
- **Black markers**: Wild-type
- **Green markers**: Knockout

**Interpretation**:
- Negative polarity = OFF response preference
- Positive polarity = ON response preference
- OFF sublayer (0-50%) should show negative polarity
- ON sublayer (50-100%) should show positive polarity

### Figure 2: Response Heatmaps

8 subplots organized as:
- **Top row**: WT OFF Ctrl, WT OFF APB, WT ON Ctrl, WT ON APB
- **Bottom row**: KO OFF Ctrl, KO OFF APB, KO ON Ctrl, KO ON APB

- **Colors**: White (low) to Black/Green (high)
- **Rows**: Individual ROIs (top 50% most reliable)
- **Columns**: Time course of response
- **Color scale**: Z-scored responses (-2 to 4)

**Interpretation**:
- Look for temporal patterns in each group
- Compare timing between OFF and ON sublayers
- Compare WT vs KO effects
- APB should reduce/eliminate ON responses (by blocking mGluR6)

### Figure 3: Shade Plots

Same organization as Figure 2, showing mean ± SEM envelopes.

- **Solid line**: Mean response across ROIs
- **Shaded region**: ± Standard error of the mean
- **X-axis**: Time (seconds)
- **Y-axis**: Z-scored fluorescence

**Interpretation**:
- Transient vs sustained responses
- Response amplitude differences between groups
- Effect of APB on each sublayer

### Figure 4: Power and Reliability

4 subplots:
1. WT Reliability vs Depth
2. WT Power vs Depth
3. KO Reliability vs Depth
4. KO Power vs Depth

- **Black**: Control condition
- **Gray**: APB condition
- **Vertical dashed line at 50%**: OFF/ON boundary

**Interpretation**:
- Reliability: How consistent are responses across trials?
- Power: How strong is the periodic component?
- Look for depth-dependent changes
- Compare control vs APB effects

## Advanced Usage

### Saving Figures Programmatically

```matlab
% Create output directory
if ~exist('output', 'dir')
    mkdir('output');
end

% In your script, after creating a figure:
hFig = gcf;  % Get current figure handle
figName = 'polarity_vs_depth';

% Save in multiple formats
saveas(hFig, ['output/' figName '.fig']);  % MATLAB figure
saveas(hFig, ['output/' figName '.png']);  % PNG image
saveas(hFig, ['output/' figName '.pdf']);  % PDF (publication)

% For higher resolution:
print(hFig, ['output/' figName '_hires'], '-dpng', '-r300');
```

### Batch Processing Multiple Datasets

```matlab
% List of data files
dataFiles = {'iGluSnFR_IPL_exp1.mat', 'iGluSnFR_IPL_exp2.mat'};

for i = 1:length(dataFiles)
    % Load data
    load(dataFiles{i});
    
    % Run analysis
    fprintf('Processing %s...\n', dataFiles{i});
    analyze_iGluSnFR_IPL;
    
    % Save figures with unique names
    for figNum = 1:4
        figure(figNum);
        saveas(gcf, sprintf('output/exp%d_fig%d.png', i, figNum));
    end
    
    % Close figures
    close all;
end
```

### Extracting Specific Results

```matlab
% After running analyze_iGluSnFR_IPL.m, variables are in workspace

% Get polarity for specific depth range
depthRange = [0.4, 0.6];
inRange = roi.id(:,1) >= depthRange(1) & roi.id(:,1) <= depthRange(2);
wtCtrl = roi.id(:,2) == 0 & roi.id(:,3) == 0 & inRange;

meanPolarity = mean(roi.polIdx(wtCtrl, 1));
fprintf('Mean polarity in depth range [%.1f, %.1f]: %.3f\n', ...
        depthRange(1), depthRange(2), meanPolarity);

% Export data to CSV
outputTable = table(roi.id(:,1), roi.id(:,2), roi.id(:,3), ...
                    roi.repRel(:,1), roi.polIdx(:,1), roi.f1Pow(:,1), ...
                    'VariableNames', {'Depth', 'Genotype', 'Condition', ...
                                     'Reliability', 'Polarity', 'Power'});
writetable(outputTable, 'output/roi_metrics.csv');
```

### Statistical Testing

```matlab
% Compare polarity between WT and KO in OFF sublayer
wtOff = roi.id(:,2) == 0 & roi.id(:,3) == 0 & roi.id(:,1) < 0.5;
koOff = roi.id(:,2) == 1 & roi.id(:,3) == 0 & roi.id(:,1) < 0.5;

wtPolarity = roi.polIdx(wtOff, 1);
koPolarity = roi.polIdx(koOff, 1);

% Two-sample t-test
[h, p, ci, stats] = ttest2(wtPolarity, koPolarity);
fprintf('WT vs KO OFF sublayer polarity:\n');
fprintf('  t(%.0f) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('  WT mean: %.3f ± %.3f\n', mean(wtPolarity), sem(wtPolarity));
fprintf('  KO mean: %.3f ± %.3f\n', mean(koPolarity), sem(koPolarity));
```

## Troubleshooting

### Memory Issues

If you encounter out-of-memory errors:

```matlab
% Clear unnecessary variables
clear avResp zResp;

% Process data in chunks
chunkSize = 100;  % Process 100 ROIs at a time
nRois = size(roi.resp, 4);

for i = 1:chunkSize:nRois
    endIdx = min(i+chunkSize-1, nRois);
    % Process roi.resp(:, :, :, i:endIdx)
end
```

### Path Issues

Ensure all functions are accessible:

```matlab
% Add src directories to path
addpath(genpath('src'));

% Verify functions are accessible
which sem
which shadePlot
which computeZScores
```

### Figure Display Issues

If figures don't display properly:

```matlab
% Ensure figures are visible
set(0, 'DefaultFigureVisible', 'on');

% Adjust figure size
figure('Position', [100, 100, 1200, 800]);

% For publication-quality figures
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5);
```

## Best Practices

1. **Always load data first**: Run `load('iGluSnFR_IPL.mat')` before any analysis
2. **Use version control**: Commit parameter changes to track your analysis
3. **Document modifications**: Add comments when changing thresholds or parameters
4. **Save figures systematically**: Use consistent naming conventions
5. **Export numerical results**: Save key metrics to CSV for further analysis
6. **Validate results**: Check that results make biological sense

## Getting Help

1. Check this documentation
2. Read inline comments in the source code
3. Refer to the manuscript for biological interpretation
4. Contact the authors for data-specific questions
