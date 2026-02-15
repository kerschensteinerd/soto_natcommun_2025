function shadePlot(x,y,e,color)
%plots line with shaded area. Inputs x, y, and e(i.e., error)
%need to be vectors of the same length. Color is [R G B].

%transpose input vectors if necessary
[nXRows,nXCols] = size(x);
if nXCols > nXRows
    x = x';
else
end
xNaNs = find(isnan(x));

[nYRows,nYCols] = size(y);
if nYCols > nYRows
    y = y';
else
end
yNaNs = find(isnan(y));

[nERows,nECols] = size(e);
if nECols > nERows
    e = e';
else
end
eNaNs = find(isnan(e));

allNaNs = unique([xNaNs;yNaNs;eNaNs]);
if ~isempty(allNaNs)
    x(allNaNs) = [];
    y(allNaNs) = [];
    e(allNaNs) = [];
else
end

% make shade color
noColor = find(color==0);
if isempty(noColor)
    shade = [0.75 0.75 0.75];
else
    shade = color;
    shade(noColor) = 0.75;
end

plusBorder = y + e;
minusBorder = y - e;
patch(vertcat(x,flipud(x)),vertcat(plusBorder,flipud(minusBorder)),shade,...
    'EdgeColor','none')

hold on
plot(x,y,'color',color)
