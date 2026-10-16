function ax = plotViscosity(D, idx, varargin)
%PLOTVISCOSITY  Scatter plot (log-log) of viscosity vs shear rate for selected runs.
%
%   plotViscosity(D, idx)                 idx = run indices or logical mask over D.runs
%   plotViscosity(D, idx, 'Units','Pa-s') viscosity in Pa.s instead of cP (default cP)
%   plotViscosity(D, idx, 'Axes', ax)     draw into an existing axes
%
%   Example:  idx = find(D.info.T_C==25 & D.info.PW_wt==15 & D.info.Naphtha_wt==0);

p = inputParser;
addParameter(p, 'Units', 'cP', @(s) any(strcmpi(s, {'cP', 'Pa-s', 'mPa-s'})));
addParameter(p, 'Axes', []);
parse(p, varargin{:});

if islogical(idx), idx = find(idx); end
if isempty(idx), error('plotViscosity:empty', 'No runs selected.'); end

if isempty(p.Results.Axes), figure; ax = axes; else, ax = p.Results.Axes; end
hold(ax, 'on');
mk = {'o','s','^','d','v','>','<','p','h'};
scale = 1;  if strcmpi(p.Results.Units, 'Pa-s'), scale = 1e-3; end

for k = 1:numel(idx)
    r = D.runs(idx(k));
    x = r.data.ShearRate_1s;
    y = r.data.Viscosity_cP * scale;
    ok = x > 0 & y > 0;                       % log axes need positive values
    scatter(ax, x(ok), y(ok), 36, 'filled', 'Marker', mk{mod(k-1, numel(mk)) + 1}, ...
        'DisplayName', r.plotLabel);
end

set(ax, 'XScale', 'log', 'YScale', 'log');
grid(ax, 'on'); box(ax, 'on');
xlabel(ax, 'Shear rate [1/s]');
ylabel(ax, sprintf('Viscosity [%s]', p.Results.Units));
temps = unique([D.runs(idx).T_set_C]);
tt = sprintf('%g\\circ C, ', temps);
title(ax, ['Viscosity vs shear rate, ' tt(1:end-2)]);
legend(ax, 'Location', 'best', 'Interpreter', 'none');
end
