function hFig = createNamedFigure(name, number, varargin)
% CREATEnamedfigure Create a figure with descriptive name and optional properties
%
% USAGE:
%   hFig = createNamedFigure(name)
%   hFig = createNamedFigure(name, number)
%   hFig = createNamedFigure(name, number, 'Property', Value, ...)
%
% INPUTS:
%   name     - String describing the figure content
%   number   - (Optional) Figure number. If omitted, MATLAB assigns one
%   varargin - (Optional) Additional figure property-value pairs
%
% OUTPUT:
%   hFig - Handle to the created figure
%
% DESCRIPTION:
%   Creates a figure with a descriptive name instead of just "Figure 1".
%   This makes it easier to manage multiple figures and identify them
%   in the figure window list. The figure is automatically set to have
%   a white background and is cleared if it already exists.
%
% EXAMPLES:
%   % Simple usage
%   hFig = createNamedFigure('Polarity vs Depth');
%
%   % With figure number
%   hFig = createNamedFigure('Polarity vs Depth', 1);
%
%   % With custom properties
%   hFig = createNamedFigure('Polarity vs Depth', 1, ...
%                           'Position', [100 100 800 600], ...
%                           'Color', 'w');
%
%   % Without number title
%   hFig = createNamedFigure('Heatmaps', [], 'NumberTitle', 'off');
%
% Author: Daniel Kerschensteiner
% Date: 02/15/2025

% Handle optional arguments
if nargin < 2 || isempty(number)
    % Create figure without specific number
    hFig = figure('Name', name, ...
                  'NumberTitle', 'off', ...
                  'Color', 'w', ...
                  varargin{:});
else
    % Create or get figure with specific number
    hFig = figure(number);
    set(hFig, 'Name', name, ...
              'NumberTitle', 'on', ...
              'Color', 'w', ...
              varargin{:});
    clf(hFig, 'reset');  % Clear figure
end

% Bring figure to front
figure(hFig);

end
