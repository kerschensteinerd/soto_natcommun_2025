# Quick Reference Card

## Getting Started

```matlab
% 1. Load data
load('iGluSnFR_IPL.mat')

% 2. Run analyses
analyze_iGluSnFR_IPL         % Main analysis (4 figures)
analyze_iGluSnFR_IPL_depth   % Depth analysis (3 figures)

% OR run everything at once:
run_all_analyses
```

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Main documentation |
| `USAGE.md` | Detailed usage guide |
| `IMPROVEMENTS.md` | Summary of code improvements |
| `demo_analysis.m` | Quick demo workflow |
| `run_all_analyses.m` | Run all analyses |

## Main Analysis Scripts

### analyze_iGluSnFR_IPL.m
Generates 4 figures:
1. Polarity vs IPL Depth
2. Response Heatmaps (8 subplots)
3. Mean ± SEM Shade Plots (8 subplots)
4. Power & Reliability vs Depth (4 subplots)

### analyze_iGluSnFR_IPL_depth.m
Generates 3 figures:
1. Mean ± SEM Envelopes by Depth Bin
2. Reliability Histograms
3. Fundamental Power Histograms

## Utility Functions (in src/)

### Analysis Functions
- `computeZScores(roi, stimSize)` - Z-score responses
- `defineExperimentalGroups(roi)` - Create group indices
- `binByDepth(data, depths, bins)` - Bin by IPL depth
- `validateRoiStructure(roi)` - Validate data

### Plotting Functions
- `createNamedFigure(name, num)` - Create named figure
- `shadePlot(x, y, err, color)` - Plot with shaded error
- `sem(data, dim)` - Standard error of mean

## Customizable Constants

In `analyze_iGluSnFR_IPL.m`:
```matlab
FRAME_RATE_HZ = 16.667;
STIM_SIZE = 1;
WT_RELIABILITY_THRESH = 0.4;
KO_RELIABILITY_THRESH = 0.4;
IPL_DEPTH_DIVIDER = 0.5;
COLOR_WT = [0, 0, 0];
COLOR_KO = [0, 180/255, 0];
```

In `analyze_iGluSnFR_IPL_depth.m`:
```matlab
DEPTH_BINS = [0.3, 0.4, 0.5, 0.6, 0.7];
MAX_ROIS_PER_BIN = 500;
STIM_SIZE = 1;
```

## Data Structure

`roi` structure fields:
- `roi.id` - [nRois × 3] metadata [depth, genotype, condition]
- `roi.resp` - [time × repeats × stimSize × nRois] responses
- `roi.repRel` - [nRois × nStimSizes] reliability
- `roi.polIdx` - [nRois × nStimSizes] polarity index
- `roi.f1Pow` - [nRois × nStimSizes] fundamental power

## Common Tasks

### View specific ROI
```matlab
roiIdx = 1;
stimIdx = 1;
plot(squeeze(roi.resp(:, :, stimIdx, roiIdx)));
xlabel('Time'); ylabel('Response');
```

### Filter by group
```matlab
groups = defineExperimentalGroups(roi);
wtCtrlData = roi.resp(:, :, :, groups.wtCtrl);
```

### Compute z-scores
```matlab
zResp = computeZScores(roi, 1);
imagesc(zResp);  % Heatmap
```

### Save figures
```matlab
saveas(gcf, 'output/my_figure.png');
saveas(gcf, 'output/my_figure.fig');
```

## Testing

```matlab
% Run unit tests
cd tests
test_utils
```

## Troubleshooting

**Error: "roi" not found**
→ Run `load('iGluSnFR_IPL.mat')` first

**Error: Undefined function 'sem'**
→ Run `addpath(genpath('src'))` or run from repository root

**Figures not displaying**
→ Check `set(0, 'DefaultFigureVisible', 'on')`

## Getting Help

1. Read README.md for overview
2. Read USAGE.md for detailed examples
3. Check IMPROVEMENTS.md for what changed
4. Look at demo_analysis.m for example workflow
5. Contact authors via manuscript

## Citation

```
Soto et al. (2025). Molecular mechanism establishing the 
OFF pathway in vision. Nature Communications.
```

## Version

- **v1.1** (2025-02-15): Refactored with improvements
- **v1.0** (2025-01-08): Initial release
