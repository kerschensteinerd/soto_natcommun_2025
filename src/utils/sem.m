function [y] = sem(x,dim)

if nargin==1
    % Determine which dimension sem will use
    dim = find(size(x)~=1, 1 );
    if isempty(dim), dim = 1; end
    
    y = std(x,'omitnan')/sqrt(size(x,dim));
else
    y = std(x,0,dim,'omitnan')/sqrt(size(x,dim));
end

