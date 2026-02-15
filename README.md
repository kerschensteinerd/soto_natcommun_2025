# iGluSnFR IPL Analysis - Soto et al. 2025

Analysis code for glutamate signaling in the retinal inner plexiform layer (IPL), supporting the manuscript:

**"Molecular mechanism establishing the OFF pathway in vision"**  
*Soto et al., Nature Communications, 2025*

## Overview

This repository contains MATLAB scripts for analyzing iGluSnFR (glutamate sensor) signals from the inner plexiform layer (IPL) of the retina. The analysis compares glutamate release patterns between:
- **Genotypes**: Wild-type (WT) vs. Knockout (KO)
- **Conditions**: Control (Ctrl) vs. APB (mGluR6 blocker)
- **Layers**: OFF sublayer (0-50% IPL depth) vs. ON sublayer (50-100% IPL depth)

## Requirements

- **MATLAB**: R2019b or newer recommended
- **Toolboxes**: 
  - Statistics and Machine Learning Toolbox (for `std`, statistical functions)
  - Image Processing Toolbox (optional, for some visualization features)
- **Data**: `iGluSnFR_IPL.mat` (240 MB) - Contact authors for access

## Quick Start

1. **Load the data**:
   ```matlab
   load('iGluSnFR_IPL.mat')
   ```

2. **Run the main analysis**:
   ```matlab
   analyze_iGluSnFR_IPL
   ```
   This generates 4 figures showing polarity, heatmaps, shade plots, and power/reliability metrics.

3. **Run the depth-binned analysis**:
   ```matlab
   analyze_iGluSnFR_IPL_depth
   ```
   This generates 3 figures showing depth-binned envelopes and histograms.

4. **Run all analyses at once**:
   ```matlab
   run_all_analyses
   ```

## File Structure

```
.
├── README.md                          # This file
├── USAGE.md                           # Detailed usage guide
├── analyze_iGluSnFR_IPL.m            # Main analysis script (generates 4 figures)
├── analyze_iGluSnFR_IPL_depth.m      # Depth-binned analysis (generates 3 figures)
├── anchoredProfile.m                  # Cone protein profile alignment
├── run_all_analyses.m                 # Master script to run all analyses
├── demo_analysis.m                    # Quick demo with example workflow
├── src/                               # Source code modules
│   ├── analysis/                      # Core analysis functions
│   │   ├── computeZScores.m
│   │   ├── defineExperimentalGroups.m
│   │   └── binByDepth.m
│   ├── plotting/                      # Plotting utilities
│   │   └── createNamedFigure.m
│   └── utils/                         # Shared utility functions
│       ├── sem.m
│       ├── shadePlot.m
│       └── validateRoiStructure.m
├── tests/                             # Test scripts
│   └── test_utils.m
├── iGluSnFR_IPL.mat                   # Data file (not in git)
└── Soto et al. 2025 - *.pdf          # Manuscript (not in git)
```

## Data Structure

The `iGluSnFR_IPL.mat` file contains a structure `roi` with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `roi.id` | [nRois × 3] | ROI metadata: [IPL depth (0-1), genotype (0=WT, 1=KO), condition (0=Ctrl, 1=APB)] |
| `roi.resp` | 4D array | Response data: (time × repeats × stimSize × nRois) |
| `roi.repRel` | [nRois × nStimSizes] | Repeat reliability measure (correlation between trial repeats) |
| `roi.polIdx` | [nRois × nStimSizes] | Polarity index (ON vs OFF response preference) |
| `roi.f1Pow` | [nRois × nStimSizes] | First-harmonic power (strength of periodic response) |

### IPL Depth Convention
- **0.0 - 0.5**: OFF sublayer (responds to light decrements)
- **0.5 - 1.0**: ON sublayer (responds to light increments)

### Genotype & Condition Encoding
- **Genotype**: 0 = Wild-type (WT), 1 = Knockout (KO)
- **Condition**: 0 = Control (Ctrl), 1 = APB treatment

## Figures Generated

### `analyze_iGluSnFR_IPL.m`
1. **Figure 1**: Polarity index vs. IPL depth (WT and KO comparison)
2. **Figure 2**: Response heatmaps (8 subplots: WT/KO × OFF/ON × Ctrl/APB)
3. **Figure 3**: Mean ± SEM shade plots (same organization as Figure 2)
4. **Figure 4**: Power and reliability vs. IPL depth (4 subplots)

### `analyze_iGluSnFR_IPL_depth.m`
1. **Figure 1**: Mean ± SEM envelopes by depth bin (6 depth bins × 4 conditions)
2. **Figure 2**: Reliability (roi.repRel) histograms by depth
3. **Figure 3**: Fundamental power (roi.f1Pow) histograms by depth

## Key Functions

### Analysis Functions
- `computeZScores(roi, stimSize)` - Compute z-scored responses
- `defineExperimentalGroups(roi)` - Create logical indices for all experimental groups
- `binByDepth(data, depths, depthBins)` - Bin data by IPL depth

### Utility Functions
- `sem(x, dim)` - Standard error of the mean
- `shadePlot(x, y, e, color)` - Plot line with shaded error region
- `validateRoiStructure(roi)` - Validate data structure integrity

### Plotting Functions
- `createNamedFigure(name, number)` - Create figure with descriptive name

## Customization

Key parameters can be adjusted at the top of each script:

```matlab
% In analyze_iGluSnFR_IPL.m
wtRelThresh = 0.4;              % WT reliability threshold
koRelThresh = 0.4;              % KO reliability threshold
depthDivider = 0.5;             % OFF/ON boundary (IPL depth)
stimSize = 1;                   % Stimulus size to analyze

% In analyze_iGluSnFR_IPL_depth.m
depthBins = [0.3, 0.4, 0.5, 0.6, 0.7];  % Depth bin boundaries
nRoisIncl = 500;                         % Max ROIs per bin
```

## Citation

If you use this code, please cite:

```
Soto et al. (2025). Molecular mechanism establishing the OFF pathway in vision.
Nature Communications. [DOI to be added]
```

## Authors

Daniel Kerschensteiner  
Date: January 8, 2025

## License

Please contact the authors for licensing information.

## Contact

For questions about the code or data, please contact the corresponding author through the manuscript.

## Troubleshooting

**Problem**: "The variable 'roi' is not found in the workspace"  
**Solution**: Run `load('iGluSnFR_IPL.mat')` before running analysis scripts

**Problem**: "Undefined function 'sem'"  
**Solution**: Ensure `src/utils/` is in your MATLAB path, or run from the repository root

**Problem**: Figures are not saving  
**Solution**: Check that the `output/` directory exists and is writable

## Version History

- **v1.1** (2025-02-15): Refactored code with improved organization and documentation
- **v1.0** (2025-01-08): Initial release with manuscript
