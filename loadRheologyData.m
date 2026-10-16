function D = loadRheologyData(files, varargin)
%LOADRHEOLOGYDATA  Import rheometer shear-ramp exports into one organized structure.
%
%   D = loadRheologyData(files)
%   D = loadRheologyData(files, 'Temperature', 40)   % override test temperature (deg C)
%   D = loadRheologyData(newFiles, 'Append', D)      % add more files to an existing D
%
%   files : char / string / cellstr of file paths (wildcards allowed, e.g. '*.csv').
%           Each file may contain several "Test:" blocks (one sample per block).
%
%   Output D (struct):
%     D.runs : 1xN struct array, one element per test (sample) with fields
%                id, label, plotLabel, name, project, fileName, filePath,
%                oil, oilVisc_cSt, comp (name/wt of each component), sampleTag,
%                PW_wt, Naphtha_wt, Hx_wt     (wt%, 0 if not present)
%                T_set_C   (nominal test temperature, used for grouping)
%                T_meas_C  (mean measured temperature)
%                repeat, nRepeats  (same composition + temperature seen more than once)
%                nPoints, resultName
%                data : table with columns
%                       Point, ShearRate_1s, ShearStress_Pa, Viscosity_cP,
%                       Temperature_C, Torque_mNm, Status
%     D.info : summary table, one row per run (row k  <->  D.runs(k)).
%              Use it to filter:  idx = find(D.info.T_C==25 & D.info.Naphtha_wt==5);
%
%   Temperature: by default the nominal temperature is the mean measured
%   temperature rounded to the nearest degree C (so 25.00-25.04 -> 25).
%   Pass 'Temperature' to force a value for all files in the call.
%
%   To track another component, add its name to KNOWN below (e.g. 'Hx', 'PW').

p = inputParser;
addParameter(p, 'Temperature', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
addParameter(p, 'Append', [], @(x) isempty(x) || isstruct(x));
parse(p, varargin{:});

files = cellstr(files(:));
paths = {};
for i = 1:numel(files)
    d = dir(files{i});
    d = d(~[d.isdir]);
    if isempty(d)
        error('loadRheologyData:noFile', 'No file found: %s', files{i});
    end
    for j = 1:numel(d)
        paths{end+1} = fullfile(d(j).folder, d(j).name); %#ok<AGROW>
    end
end

runs = [];
if ~isempty(p.Results.Append)
    runs = p.Results.Append.runs;
end
for i = 1:numel(paths)
    runs = [runs, parseFile(paths{i}, p.Results.Temperature)]; %#ok<AGROW>
end

[runs, info] = finalize(runs);
D.runs = runs;
D.info = info;
end

% ======================================================================
function runs = parseFile(file, Toverride)
txt   = readTextFile(file);
lines = cellstr(splitlines(string(txt)));
[~, fn, ext] = fileparts(file);

project = '';
runs = [];
cur  = [];
rows = zeros(0, 6);
stat = {};

for k = 1:numel(lines)
    ln = lines{k};
    if startsWith(ln, 'Project:')
        project = strtrim(extractAfter(ln, 'Project:'));

    elseif startsWith(ln, 'Test:')
        [runs, cur] = closeRun(runs, cur, rows, stat, Toverride);
        rows = zeros(0, 6);  stat = {};
        cur = newRun();
        cur.name     = strtrim(extractAfter(ln, 'Test:'));
        cur.project  = project;
        cur.fileName = [fn ext];
        cur.filePath = file;
        s = parseTestName(cur.name);
        cur.oil = s.oil;  cur.oilVisc_cSt = s.oilVisc_cSt;
        cur.comp = s.comp;  cur.sampleTag = s.sampleTag;

    elseif ~isempty(cur) && startsWith(ln, 'Result:')
        cur.resultName = strtrim(extractAfter(ln, 'Result:'));

    elseif ~isempty(cur) && startsWith(ln, 'Interval and data points:')
        f = strsplit(ln, '\t');
        cur.nPointsDeclared = str2double(f{end});

    elseif ~isempty(cur)
        f = strsplit(ln, '\t', 'CollapseDelimiters', false);
        % data row: empty first field, then Point No. and >= 5 numeric columns
        if numel(f) >= 7 && isempty(strtrim(f{1})) && ~isnan(str2double(f{2}))
            rows(end+1, :) = str2double(f(2:7)); %#ok<AGROW>
            if numel(f) >= 8, stat{end+1, 1} = strtrim(f{8}); else, stat{end+1, 1} = ''; end %#ok<AGROW>
        end
    end
end
[runs, ~] = closeRun(runs, cur, rows, stat, Toverride);
end

% ----------------------------------------------------------------------
function [runs, cur] = closeRun(runs, cur, rows, stat, Toverride)
if isempty(cur), return; end
if isempty(rows)
    warning('loadRheologyData:noData', 'No data rows found for "%s" in %s; skipped.', cur.name, cur.fileName);
    cur = [];  return;
end
cur.data = table(rows(:,1), rows(:,2), rows(:,3), rows(:,4), rows(:,5), rows(:,6), string(stat), ...
    'VariableNames', {'Point','ShearRate_1s','ShearStress_Pa','Viscosity_cP','Temperature_C','Torque_mNm','Status'});
cur.data.Properties.VariableUnits = {'', '1/s', 'Pa', 'cP', 'degC', 'mN*m', ''};
cur.nPoints = height(cur.data);
if ~isnan(cur.nPointsDeclared) && cur.nPointsDeclared ~= cur.nPoints
    warning('loadRheologyData:pointMismatch', '"%s": header says %d points, read %d.', ...
        cur.name, cur.nPointsDeclared, cur.nPoints);
end
cur.T_meas_C = mean(cur.data.Temperature_C, 'omitnan');
if isempty(Toverride), cur.T_set_C = round(cur.T_meas_C); else, cur.T_set_C = Toverride; end
cur.PW_wt      = compWt(cur.comp, 'PW');
cur.Naphtha_wt = compWt(cur.comp, 'Naphtha');
cur.Hx_wt      = compWt(cur.comp, 'Hx');
cur.label      = makeLabel(cur);
runs = [runs, cur];
cur = [];
end

% ----------------------------------------------------------------------
function r = newRun()
% Template: every run has exactly these fields (needed for struct-array concatenation)
r = struct('id', NaN, 'label', '', 'plotLabel', '', 'name', '', 'project', '', ...
    'fileName', '', 'filePath', '', 'oil', '', 'oilVisc_cSt', NaN, ...
    'comp', struct('name', {}, 'wt', {}), 'sampleTag', '', ...
    'PW_wt', 0, 'Naphtha_wt', 0, 'Hx_wt', 0, ...
    'T_set_C', NaN, 'T_meas_C', NaN, 'repeat', 1, 'nRepeats', 1, ...
    'nPoints', 0, 'nPointsDeclared', NaN, 'resultName', '', 'data', table());
end

% ----------------------------------------------------------------------
function s = parseTestName(name)
% "15 kCSt MO w/ 15% wt. PW + 5% Naphtha + 0.01% wt. Hx 10-2"
%   -> oil "15 kCSt MO", comps PW 15 / Naphtha 5 / Hx 0.01, sampleTag "10-2"
s = struct('oil', '', 'oilVisc_cSt', NaN, 'comp', struct('name', {}, 'wt', {}), 'sampleTag', '');
txt = name;
tag = regexp(txt, '\s(\d+-\d+)\s*$', 'tokens', 'once');
if ~isempty(tag)
    s.sampleTag = tag{1};
    txt = regexprep(txt, '\s\d+-\d+\s*$', '');
end
parts = strsplit(txt, ' w/ ');
base = strtrim(parts{1});
s.oil = base;
v = regexp(base, '(\d+(?:\.\d+)?)\s*kCSt', 'tokens', 'once');
if ~isempty(v), s.oilVisc_cSt = str2double(v{1}); end
if numel(parts) > 1
    items = strtrim(strsplit(strjoin(parts(2:end), ' w/ '), '+'));
    for i = 1:numel(items)
        t = regexp(items{i}, '^([\d.]+)\s*%\s*(?:wt\.?)?\s*(.+)$', 'tokens', 'once');
        if ~isempty(t)
            s.comp(end+1) = struct('name', strtrim(t{2}), 'wt', str2double(t{1})); %#ok<AGROW>
        end
    end
end
end

% ----------------------------------------------------------------------
function w = compWt(comp, nm)
w = 0;
if isempty(comp), return; end
m = strcmpi({comp.name}, nm);
wts = [comp.wt];
w = sum(wts(m));
end

% ----------------------------------------------------------------------
function lbl = makeLabel(r)
if isempty(r.comp)
    lbl = r.name;  return;
end
c = arrayfun(@(x) sprintf('%g%% %s', x.wt, x.name), r.comp, 'UniformOutput', false);
lbl = strjoin(c, ' + ');
end

% ----------------------------------------------------------------------
function [runs, info] = finalize(runs)
n = numel(runs);
keys = cell(n, 1);
for i = 1:n
    runs(i).id = i;
    keys{i} = sprintf('%s @ %g', runs(i).label, runs(i).T_set_C);
end
for i = 1:n
    same = strcmp(keys, keys{i});
    runs(i).repeat   = sum(same(1:i));
    runs(i).nRepeats = sum(same);
    if runs(i).nRepeats > 1
        runs(i).plotLabel = sprintf('%s (run %d)', runs(i).label, runs(i).repeat);
        if ~isempty(runs(i).sampleTag)
            runs(i).plotLabel = sprintf('%s [%s]', runs(i).plotLabel, runs(i).sampleTag);
        end
    else
        runs(i).plotLabel = runs(i).label;
    end
end
info = table([runs.id]', string({runs.label})', [runs.T_set_C]', ...
    [runs.PW_wt]', [runs.Naphtha_wt]', [runs.Hx_wt]', ...
    string({runs.sampleTag})', [runs.repeat]', [runs.nPoints]', string({runs.fileName})', ...
    'VariableNames', {'ID','Label','T_C','PW_wt','Naphtha_wt','Hx_wt','Tag','Repeat','nPts','File'});
end

% ----------------------------------------------------------------------
function txt = readTextFile(file)
% Rheometer exports are UTF-16 LE with BOM; also handle UTF-8/ASCII.
fid = fopen(file, 'r');
if fid < 0, error('loadRheologyData:open', 'Cannot open %s', file); end
c = onCleanup(@() fclose(fid)); %#ok<NASGU>
b = fread(fid, Inf, '*uint8')';
if numel(b) >= 2 && all(b(1:2) == [255 254])          % UTF-16 LE
    b = b(3:end);  b = b(1:2*floor(numel(b)/2));
    txt = char(typecast(b, 'uint16'));
elseif numel(b) >= 2 && all(b(1:2) == [254 255])      % UTF-16 BE
    b = b(3:end);  b = b(1:2*floor(numel(b)/2));
    txt = char(swapbytes(typecast(b, 'uint16')));
else
    txt = native2unicode(b, 'UTF-8');
end
end

