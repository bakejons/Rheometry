function fullfiles = getfiles()
% returns cell of filepaths for user selected files
    [filenames, pathname] = uigetfile({'*.txt;*.csv', 'Data Files'}, 'Select Files', 'MultiSelect', 'on');
    
    if isequal(filenames,0) || isequal(pathname,0)
        disp('User canceled the selection.');
    else
        % If only one file is selected, MATLAB returns a char array instead of a cell array.
        % Convert to cell array to keep processing consistent.
        if ischar(filenames)
            filenames = {filenames};
        end
        
        % Loop through and display each selected filename
        for i = 1:length(filenames)
            
            fprintf('File %d: %s\n', i, filenames{i});
        end
        fullfiles = cell(size(filenames));
        for i = 1:length(filenames)
            fullfiles{i} = strcat(pathname, filenames{i});
        end
   
    end
    
    
    fprintf("___________________________________________________________________________________\n")
end