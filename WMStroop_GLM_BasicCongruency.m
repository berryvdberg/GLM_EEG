function [error_info] = WMStroop_GLM_BasicCongruency()

mainDir = uigetdir(pwd, 'Select input data');
[files,filenames] = get_any_files('_Dat4GLM.mat',mainDir);

% creating a batch list of all participants in the main directory
% ======================================================================= %
selection = listdlg('ListString',filenames,...
                                        'SelectionMode','multiple',...
                                        'PromptString','Choose subjects to analyze');
files = files(selection);
filenames = filenames(selection);
nsubj=length(filenames);

% Defining structure for data & beta names
% ======================================================================= %
glmDat = struct;
desDat = struct;

% Running ERP analysis
% ======================================================================= %
for si = 1:nsubj
    subID = filenames{si}(1:4);
    
    try
        display(sprintf('Running: Time-locked Averaging for subject %s',subID));
        [glmERP,labels,des] = Extract_ERP(files{si});
        
        desDat.(['Subject_' subID]).Design = des;
        desDat.(['Subject_' subID]).BetaLabels = labels;
        
        %---- some final renaming of fields
        for li = 1:length(labels);
            glmDat.(labels{li}){si} = glmERP.(['x' num2str(li)]);
        end

        error_info{si} = [];
    catch me
        error_info{si} = me;
    end    
end

% Set up a matrix to make a prediction grid
% NOTE: pred should have same order as below for des.Factor after "intercept"
% ======================================================================= %
pred = struct('intercept',1,...
              'task',[1;2],...
              'incon',[0;1]);
dummyCount = [0,2,0];      
design = tools_createPrediction(pred,dummyCount);
design = [design;...
         [[1;1],[0;0],[0;0],[0;1],[0;0],[0;0]]];
     
design = mat2dataset(design);
design.Properties.VarNames = labels;

% Identify the condition labels based on contrast design
% ======================================================================= %
cond.Factors = [{'intercept'},{'wm','cogload'},{'incon'}];
cond.Values = [{[{1;0},{'intercept';'nointercept'}]},...
               {[{1;0},{'wm';'Null'}]},...
               {[{1;0},{'cogload';'Null'}]},...
               {[{1;0},{'incon';'con'}]}];
conditions = tools_createConditionID(design,cond,labels);

save(fullfile(pwd,'GLM Outputs','Output_GLM_BasicCongruency.mat'),'glmDat','desDat','labels','design','conditions'); 

WMStroop_PredictGLM('BasicCongruency',fullfile(pwd,'GLM Outputs','Output_GLM_BasicCongruency.mat'))
end

function [glmERP,labels,des] = Extract_ERP(datafile)

% ======================================================================= %
% Loading in the data
% ======================================================================= %
load(datafile);
    
% ======================================================================= %
% Creating design matrix
% ======================================================================= %

% Factors involved
% Congruency:   2 levels: 0 = incon; 1 = con
% Task:         3 levels, dummy coded; exclude task == 3
%               Need to exclude due to rank deficiency
% ==================================== %
congruency = 1-trialStruct.congruency(trials); % incon = 0, con = 1

task = dummyvar(trialStruct.task(trials)); % anything greater than 2 levels - make dummyvars    
task = task(:,1:2); % classic condition not modeled (exlcuded)

des.Factors = {'task','incon'};
des.Levels = {{'wm','cogload'},'incon'};
des.DummyCount = [2,0];
des.Data = [{task},{congruency}];

% Full factorial design
des = tools_createDesign(des);
        
% ======================================================================= %
% Running the data through general linear model    
% ======================================================================= %
cfg = [];
cfg.latency = [-0.5 1.5]; % time window to analyze
cfg.normalize = 'no'; % think of this as signal intensity normalization
cfg.design = des.DatMatrix;
glmERP = stats_glm(cfg,ERPdat);
    
% ======================================================================= %
% Defining labels for the betas
% ======================================================================= %

labels = {'intercept'};
for ci = 2:size(des.CondMatrix,1)
    labels = [labels,des.CondMatrix{ci,strcmpi(des.CondMatrix(1,:),'Labels')}];
end
end