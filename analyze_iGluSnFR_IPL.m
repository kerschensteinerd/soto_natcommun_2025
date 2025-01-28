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
%   - Custom functions required:
%       sem(...)       -> standard error of the mean
%       shadePlot(...) -> for plotting mean ± SEM shading
%
% Figures:
%   1) Polarity vs. IPL Depth
%   2) Heatmaps of z-scored responses
%   3) Mean ± SEM shade plots (same ordering as Figure 2)
%   4) Reliability and power vs. IPL depth
%
% Author: Daniel Kerschensteiner
% Date:  01/08/2025

%% Check if 'roi' exists
if ~exist('roi','var') || isempty(roi)
    error('The variable "roi" is not found in the workspace. Load iGluSnFR_IPL.mat first.');
end

%% ========== 1. DEFINING GROUP INDICES ==========

wtCtrlIdx = roi.id(:,2)==0 & roi.id(:,3)==0;
wtApbIdx  = roi.id(:,2)==0 & roi.id(:,3)==1;
koCtrlIdx = roi.id(:,2)==1 & roi.id(:,3)==0;
koApbIdx  = roi.id(:,2)==1 & roi.id(:,3)==1;

%% ========== 2. POLARITY INDEX AS A FUNCTION OF IPL DEPTH (FIGURE 1) ==========

wtRelThresh = 0.4;
koRelThresh = 0.4;

depthBins = 0.2:0.1:0.8; 
depthCent = depthBins + 0.5 * mean(diff(depthBins));
depthCent(end) = [];
nDepths = numel(depthCent);

stimSize = 1;  
avResp = mean(roi.resp(:,:,stimSize,:),1); %#ok<NASGU> 

wtPolIdx  = zeros(nDepths,1);
wtPolIdxE = zeros(nDepths,1);
koPolIdx  = zeros(nDepths,1);
koPolIdxE = zeros(nDepths,1);

relWtCtrl = (roi.id(:,2)==0 & roi.id(:,3)==0 & roi.repRel(:,stimSize) > wtRelThresh);
relKoCtrl = (roi.id(:,2)==1 & roi.id(:,3)==0 & roi.repRel(:,stimSize) > koRelThresh);

for i=1:nDepths
    currWt = relWtCtrl & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    wtPolIdx(i)  = mean(roi.polIdx(currWt,stimSize));
    wtPolIdxE(i) = sem(roi.polIdx(currWt,stimSize));

    currKo = relKoCtrl & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    koPolIdx(i)  = mean(roi.polIdx(currKo,stimSize));
    koPolIdxE(i) = sem(roi.polIdx(currKo,stimSize));
end

% -- Figure 1 --
hFigPol = figure(1); 
clf(hFigPol,'reset');
set(hFigPol,'Name','Figure 1: Polarity vs. IPL Depth','Color','w');

errorbar(depthCent*100, wtPolIdx, wtPolIdxE,...
    'Color',[0 0 0],'LineStyle','none','Marker','o','CapSize',0)
hold on
errorbar(depthCent*100, koPolIdx, koPolIdxE,...
    'Color',[0 180/255 0],'LineStyle','none','Marker','o','CapSize',0)
plot([50 50],[-1 1],'--k')
box off
xlabel('IPL depth (%)')
ylabel('Polarity')
title('Polarity vs. IPL Depth')

%% ========== 3. RESPONSE HEATMAPS SORTED BY REPEAT RELIABILITY (FIGURE 2) ==========

stimSize = 1; 
sdResp  = squeeze(std(roi.resp(:,:,stimSize,:),0,[1 2]));
avSub   = squeeze(mean(roi.resp(:,:,stimSize,:),[1 2]));
avResp  = squeeze(mean(roi.resp(:,:,stimSize,:),1))';
zResp   = zeros(size(avResp));

nRois = numel(sdResp);
for i=1:nRois
    zResp(i,:) = (avResp(i,:) - avSub(i)) / sdResp(i);
end

depthDivider = 0.5; 

% WT ON CTRL
wtOnCtrl = (roi.id(:,2)==0 & roi.id(:,3)==0 & roi.id(:,1) > depthDivider);
wtOnCtrlResp = zResp(wtOnCtrl,:);
[~, wtOnCtrlSort] = sort(roi.repRel(wtOnCtrl,stimSize), 'descend'); 
wtOnCtrlSort = wtOnCtrlSort(1 : round(numel(wtOnCtrlSort)/2));

% WT ON APB
wtOnApb = (roi.id(:,2)==0 & roi.id(:,3)==1 & roi.id(:,1) > depthDivider);
wtOnApbResp = zResp(wtOnApb,:);
[~, wtOnApbSort] = sort(roi.repRel(wtOnApb,stimSize), 'descend'); 
wtOnApbSort = wtOnApbSort(1 : round(numel(wtOnApbSort)/2));

% WT OFF CTRL
wtOffCtrl = (roi.id(:,2)==0 & roi.id(:,3)==0 & roi.id(:,1) < depthDivider);
wtOffCtrlResp = zResp(wtOffCtrl,:);
[~, wtOffCtrlSort] = sort(roi.repRel(wtOffCtrl,stimSize), 'descend');
wtOffCtrlSort = wtOffCtrlSort(1 : round(numel(wtOffCtrlSort)/2));

% WT OFF APB
wtOffApb = (roi.id(:,2)==0 & roi.id(:,3)==1 & roi.id(:,1) < depthDivider);
wtOffApbResp = zResp(wtOffApb,:);
[~, wtOffApbSort] = sort(roi.repRel(wtOffApb,stimSize), 'descend'); 
wtOffApbSort = wtOffApbSort(1 : round(numel(wtOffApbSort)/2));

% KO ON CTRL
koOnCtrl = (roi.id(:,2)==1 & roi.id(:,3)==0 & roi.id(:,1) > depthDivider);
koOnCtrlResp = zResp(koOnCtrl,:);
[~, koOnCtrlSort] = sort(roi.repRel(koOnCtrl,stimSize), 'descend'); 
koOnCtrlSort = koOnCtrlSort(1 : round(numel(koOnCtrlSort)/2));

% KO ON APB
koOnApb = (roi.id(:,2)==1 & roi.id(:,3)==1 & roi.id(:,1) > depthDivider);
koOnApbResp = zResp(koOnApb,:);
[~, koOnApbSort] = sort(roi.repRel(koOnApb,stimSize), 'descend'); 
koOnApbSort = koOnApbSort(1 : round(numel(koOnApbSort)/2));

% KO OFF CTRL
koOffCtrl = (roi.id(:,2)==1 & roi.id(:,3)==0 & roi.id(:,1) < depthDivider);
koOffCtrlResp = zResp(koOffCtrl,:);
[~, koOffCtrlSort] = sort(roi.repRel(koOffCtrl,stimSize), 'descend'); 
koOffCtrlSort = koOffCtrlSort(1 : round(numel(koOffCtrlSort)/2));

% KO OFF APB
koOffApb = (roi.id(:,2)==1 & roi.id(:,3)==1 & roi.id(:,1) < depthDivider);
koOffApbResp = zResp(koOffApb,:);
[~, koOffApbSort] = sort(roi.repRel(koOffApb,stimSize), 'descend'); 
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
hFigHeat = figure(2);
clf(hFigHeat,'reset');
set(hFigHeat,'Name','Figure 2: Heatmaps','Color','w');

clims = [-2 4];

% Top row:   WT OFF CTRL, WT OFF APB, WT ON CTRL, WT ON APB
% Bottom row:KO OFF CTRL, KO OFF APB, KO ON CTRL, KO ON APB

subplot(2,4,1)
imagesc(wtOffCtrlResp(wtOffCtrlSort,:), clims)
colormap(gca, blackMap)
ylabel('ROIs (#)')
title('WT OFF CTRL')

subplot(2,4,2)
imagesc(wtOffApbResp(wtOffApbSort,:), clims)
colormap(gca, blackMap)
title('WT OFF APB')

subplot(2,4,3)
imagesc(wtOnCtrlResp(wtOnCtrlSort,:), clims)
colormap(gca, blackMap)
title('WT ON CTRL')

subplot(2,4,4)
imagesc(wtOnApbResp(wtOnApbSort,:), clims)
colormap(gca, blackMap)
title('WT ON APB')

subplot(2,4,5)
imagesc(koOffCtrlResp(koOffCtrlSort,:), clims)
colormap(gca, darkGreenMap)
ylabel('ROIs (#)')
title('KO OFF CTRL')

subplot(2,4,6)
imagesc(koOffApbResp(koOffApbSort,:), clims)
colormap(gca, darkGreenMap)
title('KO OFF APB')

subplot(2,4,7)
imagesc(koOnCtrlResp(koOnCtrlSort,:), clims)
colormap(gca, darkGreenMap)
title('KO ON CTRL')

subplot(2,4,8)
imagesc(koOnApbResp(koOnApbSort,:), clims)
colormap(gca, darkGreenMap)
title('KO ON APB')

% Convert heatmap x-axis from datapoints to time (s)
nTimePoints = size(zResp,2);
xVals = (0:nTimePoints-1) / 16.667;
for sp = 1:8
    subplot(2,4,sp)
    xticks(linspace(1,nTimePoints,5))
    xLabVals = linspace(0,xVals(end),5);
    xticklabels(arrayfun(@(v) sprintf('%.1f',v), xLabVals, 'UniformOutput',false))
    xlabel('Time (s)')
end

%% ========== 4. SHADEPLOTS (FIGURE 3) WITH THE SAME ORDER AS FIGURE 2 ==========

timeBins = (0:(size(zResp,2)-1)) / 16.667;

% -- Figure 3: Shade Plots --
hFigShade = figure(3);
clf(hFigShade,'reset');
set(hFigShade,'Name','Figure 3: Shade Plots','Color','w');

% REORDER to match Figure 2 EXACTLY:
% 1) WT OFF CTRL, 2) WT OFF APB, 3) WT ON CTRL, 4) WT ON APB,
% 5) KO OFF CTRL, 6) KO OFF APB, 7) KO ON CTRL, 8) KO ON APB

subplot(2,4,1)
shadePlot(timeBins, mean(wtOffCtrlResp), sem(wtOffCtrlResp), [0 0 0])
ylabel('Fz')
title('WT OFF CTRL')

subplot(2,4,2)
shadePlot(timeBins, mean(wtOffApbResp), sem(wtOffApbResp), [0 0 0])
title('WT OFF APB')

subplot(2,4,3)
shadePlot(timeBins, mean(wtOnCtrlResp), sem(wtOnCtrlResp), [0 0 0])
title('WT ON CTRL')

subplot(2,4,4)
shadePlot(timeBins, mean(wtOnApbResp), sem(wtOnApbResp), [0 0 0])
title('WT ON APB')

subplot(2,4,5)
shadePlot(timeBins, mean(koOffCtrlResp), sem(koOffCtrlResp), [0 1 0])
ylabel('Fz')
title('KO OFF CTRL')

subplot(2,4,6)
shadePlot(timeBins, mean(koOffApbResp), sem(koOffApbResp), [0 1 0])
title('KO OFF APB')

subplot(2,4,7)
shadePlot(timeBins, mean(koOnCtrlResp), sem(koOnCtrlResp), [0 1 0])
title('KO ON CTRL')

subplot(2,4,8)
shadePlot(timeBins, mean(koOnApbResp), sem(koOnApbResp), [0 1 0])
title('KO ON APB')

% Label x-axis for all subplots
for sp = 1:8
    subplot(2,4,sp)
    xlabel('Time (s)')
end

%% ========== 5. POWER AND RELIABILITY BY DEPTH (FIGURE 4) ==========

stimSize = 1;
depthBins = 0.2:0.1:0.8;
depthCent = depthBins + 0.5*mean(diff(depthBins));
depthCent(end) = [];
nDepths = numel(depthCent);

wtCtrl = (roi.id(:,2)==0 & roi.id(:,3)==0);
wtApb  = (roi.id(:,2)==0 & roi.id(:,3)==1);
koCtrl = (roi.id(:,2)==1 & roi.id(:,3)==0);
koApb  = (roi.id(:,2)==1 & roi.id(:,3)==1);

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

for i=1:nDepths
    currWtCtrl = wtCtrl & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    wtCtrlRel(i)  = mean(roi.repRel(currWtCtrl,stimSize));
    wtCtrlRelE(i) = sem(roi.repRel(currWtCtrl,stimSize));
    wtCtrlPow(i)  = mean(roi.f1Pow(currWtCtrl,stimSize));
    wtCtrlPowE(i) = sem(roi.f1Pow(currWtCtrl,stimSize));

    currWtApb = wtApb & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    wtApbRel(i)  = mean(roi.repRel(currWtApb,stimSize));
    wtApbRelE(i) = sem(roi.repRel(currWtApb,stimSize));
    wtApbPow(i)  = mean(roi.f1Pow(currWtApb,stimSize));
    wtApbPowE(i) = sem(roi.f1Pow(currWtApb,stimSize));

    currKoCtrl = koCtrl & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    koCtrlRel(i)  = mean(roi.repRel(currKoCtrl,stimSize));
    koCtrlRelE(i) = sem(roi.repRel(currKoCtrl,stimSize));
    koCtrlPow(i)  = mean(roi.f1Pow(currKoCtrl,stimSize));
    koCtrlPowE(i) = sem(roi.f1Pow(currKoCtrl,stimSize));

    currKoApb = koApb & (roi.id(:,1) > depthBins(i)) & (roi.id(:,1) <= depthBins(i+1));
    koApbRel(i)  = mean(roi.repRel(currKoApb,stimSize));
    koApbRelE(i) = sem(roi.repRel(currKoApb,stimSize));
    koApbPow(i)  = mean(roi.f1Pow(currKoApb,stimSize));
    koApbPowE(i) = sem(roi.f1Pow(currKoApb,stimSize));
end

% -- Figure 4: Power & Reliability --
hPowRel = figure(4);
clf(hPowRel,'reset');
set(hPowRel,'Name','Figure 4: Power & Reliability','Color','w');

% Subplot 1: Reliability (WT)
subplot(1,4,1)
errorbar(depthCent*100, wtCtrlRel, wtCtrlRelE,...
    'Color',[0 0 0],'LineStyle','-','CapSize',0)
hold on
errorbar(depthCent*100, wtApbRel, wtApbRelE,...
    'Color',[0.5 0.5 0.5],'LineStyle','-','CapSize',0)
plot([50 50], [min([wtCtrlRel-wtCtrlRelE; wtApbRel-wtApbRelE]), ...
               max([wtCtrlRel+wtCtrlRelE; wtApbRel+wtApbRelE])],'--k')
box off
axis([20, 80, ...
    min([wtCtrlRel-wtCtrlRelE; wtApbRel-wtApbRelE]), ...
    max([wtCtrlRel+wtCtrlRelE; wtApbRel+wtApbRelE])])
xlabel('IPL depth (%)')
ylabel('Reliability (R)')
title('WT Reliability')

% Subplot 2: Power (WT)
subplot(1,4,2)
errorbar(depthCent*100, wtCtrlPow, wtCtrlPowE,...
    'Color',[0 0 0],'LineStyle','-','CapSize',0)
hold on
errorbar(depthCent*100, wtApbPow, wtApbPowE,...
    'Color',[0.5 0.5 0.5],'LineStyle','-','CapSize',0)
plot([50 50], [min([wtCtrlPow-wtCtrlPowE; wtApbPow-wtApbPowE]), ...
               max([wtCtrlPow+wtCtrlPowE; wtApbPow+wtApbPowE])],'--k')
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
    'Color',[0 1 0],'LineStyle','-','CapSize',0)
hold on
errorbar(depthCent*100, koApbRel, koApbRelE,...
    'Color',[0 0.5 0],'LineStyle','-','CapSize',0)
plot([50 50], [min([koCtrlRel-koCtrlRelE; koApbRel-koApbRelE]), ...
               max([koCtrlRel+koCtrlRelE; koApbRel+koApbRelE])],'--k')
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
    'Color',[0 1 0],'LineStyle','-','CapSize',0)
hold on
errorbar(depthCent*100, koApbPow, koApbPowE,...
    'Color',[0 0.5 0],'LineStyle','-','CapSize',0)
plot([50 50], [min([koCtrlPow-koCtrlPowE; koApbPow-koApbPowE]), ...
               max([koCtrlPow+koCtrlPowE; koApbPow+koApbPowE])],'--k')
box off
axis([20, 80, ...
    min([koCtrlPow-koCtrlPowE; koApbPow-koApbPowE]), ...
    max([koCtrlPow+koCtrlPowE; koApbPow+koApbPowE])])
xlabel('IPL depth (%)')
ylabel('Power (rel.)')
title('KO Power')