%% Basic model - congruent vs. incongruent for all 3 conditions

load(fullfile(pwd,'Contrast Outputs','Output_Contrast_BasicCongruency.mat'));

cfg = [];
cfg.parameter = 'individual';
cfg.keeptrials = 'no';
cfg.operation = 'x2-x1';   

inconEffect.Basic.WM = ft_math(cfg,contrasts.intercept_wm_con,contrasts.intercept_wm_incon);
inconEffect.Basic.CogLoad = ft_math(cfg,contrasts.intercept_cogload_con,contrasts.intercept_cogload_incon);
inconEffect.Basic.Classic = ft_math(cfg,contrasts.intercept_con,contrasts.intercept_incon);

% convert to dimord = chan_time
fields = {'WM','CogLoad','Classic'};
for fi = 1:length(fields)
    inconEffect.Basic.(fields{fi}).avg = squeeze(mean(inconEffect.Basic.(fields{fi}).individual,1));
    inconEffect.Basic.(fields{fi}).var = squeeze(var(inconEffect.Basic.(fields{fi}).individual,[],1));
    inconEffect.Basic.(fields{fi}).dof = repmat(size(inconEffect.Basic.(fields{fi}).individual,1)-1,...
                                                size(inconEffect.Basic.(fields{fi}).avg,1),...
                                                size(inconEffect.Basic.(fields{fi}).avg,2));
    inconEffect.Basic.(fields{fi}) = rmfield(inconEffect.Basic.(fields{fi}),'individual');
    inconEffect.Basic.(fields{fi}).dimord = 'chan_time';
    
    inconEffect.Basic.(fields{fi}) = tools_filterDat(inconEffect.Basic.(fields{fi}),[-0.3,0],250,20,10); % filtering final ERP output
end

load('layoutmw64_martyPlot_labeled.mat');
cfg = [];
cfg.layout = layoutmw64_martyPlot;
cfg.interactive='yes';
cfg.xlim = [-0.3 1.3];
figure;ft_multiplotER(cfg,inconEffect.Basic.WM,inconEffect.Basic.CogLoad,inconEffect.Basic.Classic);