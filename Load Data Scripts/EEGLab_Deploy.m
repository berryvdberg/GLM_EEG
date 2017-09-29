function [] = EEGLab_Deploy()

    eeglabpath = mywhich('eeglab.m');
    eeglabpath = eeglabpath(1:end-length('eeglab.m'));

    myaddpath( eeglabpath, 'eeg_checkset.m',   [ 'functions' filesep 'adminfunc'        ]);
    myaddpath( eeglabpath, 'eeg_checkset.m',   [ 'functions' filesep 'adminfunc'        ]);
    myaddpath( eeglabpath, ['@mmo' filesep 'mmo.m'], 'functions');
    myaddpath( eeglabpath, 'readeetraklocs.m', [ 'functions' filesep 'sigprocfunc'      ]);
    myaddpath( eeglabpath, 'supergui.m',       [ 'functions' filesep 'guifunc'          ]);
    myaddpath( eeglabpath, 'pop_study.m',      [ 'functions' filesep 'studyfunc'        ]);
    myaddpath( eeglabpath, 'pop_loadbci.m',    [ 'functions' filesep 'popfunc'          ]);
    myaddpath( eeglabpath, 'statcond.m',       [ 'functions' filesep 'statistics'       ]);
    myaddpath( eeglabpath, 'timefreq.m',       [ 'functions' filesep 'timefreqfunc'     ]);
    myaddpath( eeglabpath, 'icademo.m',        [ 'functions' filesep 'miscfunc'         ]);
    myaddpath( eeglabpath, 'eeglab1020.ced',   [ 'functions' filesep 'resources'        ]);
    myaddpath( eeglabpath, 'startpane.m',      [ 'functions' filesep 'javachatfunc' ]);
    addpathifnotinlist(fullfile(eeglabpath, 'plugins'));
    eeglab_options;
    
end

function res = mywhich(varargin)
    try
        res = which(varargin{:});
    catch
        fprintf('Warning: permission error accesssing %s\n', varargin{1});
    end
end

function myaddpath(eeglabpath, functionname, pathtoadd)
    tmpp = mywhich(functionname);
    tmpnewpath = [ eeglabpath pathtoadd ];
    if ~isempty(tmpp)
        tmpp = tmpp(1:end-length(functionname));
        if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
        if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
        %disp([ tmpp '     |        ' tmpnewpath '(' num2str(~strcmpi(tmpnewpath, tmpp)) ')' ]);
        if ~strcmpi(tmpnewpath, tmpp)
            warning('off', 'MATLAB:dispatcher:nameConflict');
            addpath(tmpnewpath);
            warning('on', 'MATLAB:dispatcher:nameConflict');
        end
    else
        %disp([ 'Adding new path ' tmpnewpath ]);
        addpathifnotinlist(tmpnewpath);
    end
end

function addpathifnotinlist(newpath)
    comp = computer;
    if strcmpi(comp(1:2), 'PC')
        newpathtest = [ newpath ';' ];
    else
        newpathtest = [ newpath ':' ];
    end
    if ismatlab
        p = matlabpath;
    else p = path;
    end
    ind = strfind(p, newpathtest);
    if isempty(ind)
        if exist(newpath) == 7
            addpath(newpath);
        end
    end
end

function res = ismatlab
    v = version;
    if v(1) > '4'
        res = 1;
    else
        res = 0;
    end
end