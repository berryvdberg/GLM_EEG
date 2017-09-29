function [glmDat] = stats_glm(cfg,dat)

% ======================================================================= %
% Checking data type to see if running ERP or TFR analysis on EEG data
% Also checking for the integrity of the input data prior to running analysis
% ======================================================================= %
ft_defaults;
[type, dimord] = ft_datatype(dat);

switch type
    case 'freq' % time frequency representation analysis
        if ~strcmp(dat.dimord, 'rpt_chan_freq_time')
            error('time-frequency matrix should have dimensions rpt_chan_freq_time');
        end
        
        if isfield(cfg,'channels')
           channel = ft_channelselection(cfg.channels,dat.label);
           dat = ft_selectdata(dat,'channel',channel);
        end
        
        dimRpt = size(dat.powspctrm,1);
        dimChan = size(dat.powspctrm,2);
        dimFreq = size(dat.powspctrm,3);
        dimTime = size(dat.powspctrm,4);
        modDat  = reshape(dat.powspctrm,dimRpt,[]);
    case 'timelock' % event-related potential analysis        
        if ~strcmp(dat.dimord, 'rpt_chan_time')
            error('timelock matrix should have dimensions rpt_chan_time');
        end
        
        if isfield(cfg,'channels')
           channel = ft_channelselection(cfg.channels,dat.label);
           dat = ft_selectdata(dat,'channel',channel);
        end
        if isfield(cfg,'latency')
            tmpcfg = [];
            tmpcfg.latency = cfg.latency;
            dat = ft_selectdata(cfg,dat);
        end

        dimRpt = size(dat.trial,1);
        dimChan = size(dat.trial,2);
        dimTime = size(dat.trial,3);
        modDat  = reshape(dat.trial,dimRpt,[]);
end

% ======================================================================= %
% If you want to normalize your timeseries data before running GLM
% ======================================================================= %
if strcmpi(cfg.normalize,'yes')
    modDat = (modDat - repmat(mean(modDat),dimRpt,1))./repmat(std(modDat),dimRpt,1); % z-tranformation
end

% ======================================================================= %
% Run GLM using mldivide 
% 
% x = A\B or x = mldivide(A,B) solves the system of linear equations A*x=B
%
% A & B must have the same number of rows
%   A = design matrix (Ntrials * regressors)
%   B = timeseries data (Ntrials * timeseries)
% ======================================================================= %
design = [ones(size(cfg.design,1),1),cfg.design]; % first regressor to account for the intercept
betas = design\modDat;

% ======================================================================= %
% Reshape data back to original dimensions
% ======================================================================= %
switch type
    case 'freq'
        for i= 1:size(betas,1)
            glmDat.(['x' num2str(i)]).label = dat.label;
            glmDat.(['x' num2str(i)]).dimord = 'chan_freq_time';
            glmDat.(['x' num2str(i)]).freq = dat.freq;
            glmDat.(['x' num2str(i)]).time = dat.time;
            glmDat.(['x' num2str(i)]).cumtapcnt = dat.cumtapcnt;
            glmDat.(['x' num2str(i)]).elec = dat.elec;
            glmDat.(['x' num2str(i)]).cfg = [];
            glmDat.(['x' num2str(i)]).powspctrm = reshape(betas(i,:),[dimChan,dimFreq,dimTime]);
        end
    case 'timelock'
        for i= 1:size(betas,1)
            glmDat.(['x' num2str(i)]).label = dat.label;
            glmDat.(['x' num2str(i)]).dimord = 'chan_time';
            glmDat.(['x' num2str(i)]).time = dat.time;
            glmDat.(['x' num2str(i)]).elec = dat.elec;
            glmDat.(['x' num2str(i)]).cfg = [];
            glmDat.(['x' num2str(i)]).avg = reshape(betas(i,:),[dimChan,dimTime]);
        end
end

