function [] = Load_EEGLab_FieldTrip()

mainDir = uigetdir(pwd, 'Select processed data directory');
outDir = uigetdir(pwd, 'Select output data directory');

% removed any .DS_Store hidden files created if using MAC OS. These files
% are picked up by MATLAB in the script below so they should be removed.
% requires get_any_files.m which is a small script that spiders through the
% mainDir and identify all .DS_Store files to be deleted.
try
    dstore = get_any_files('.DS_Store',mainDir);
    for i = 1:length(dstore)
        delete(dstore{i});
    end
catch
end

% creating a batch list of all participants in the main directory
dirData = dir(mainDir); dirIndex = [dirData.isdir]; subDirs = {dirData(dirIndex).name};  
batchList = subDirs(find(cellfun(@isempty,strfind(subDirs,'.'))));
subject_selection = listdlg('ListString',batchList,...
                                        'SelectionMode','multiple',...
                                        'PromptString','Choose subjects to analyze');
subjects = batchList(subject_selection);
nsubj=length(subjects);

studyname = 'wmstroop';
run('EEGLab_Deploy.m'); % adding necessary folders to path to run eeglab

for si = 1:nsubj
    subID = subjects{si};
    subDir = fullfile(mainDir,subID);
    
    try
        display(sprintf('Running: Time-locked Averaging for subject %s',subID));
        convert_eeglab(subDir,outDir,subID,studyname);
        
        error_info{si} = [];
    catch me
        error_info{si} = me;
    end
end

end

function [] = convert_eeglab(subDir,outDir,subID,studyname)

% ======================================================================= %
% Loading in the data
% ======================================================================= %
EEG = pop_loadset([subID '_' studyname '_FinalPreproc_ICAd_Epoched_ART.set'],subDir);
load(fullfile(subDir,[subID '_' studyname '_trialStruct_art.mat']));

% Expand to 64 channels for easier plotting
EEG = pop_eegchanoperator(EEG,'channel_expansion_rveog.txt');
EEG = pop_chanedit(EEG,'load',{'mw64_actichamp_fixed_mwnames.ced' 'filetype' 'autodetect'});

% Export EEG to field trip
ft_defaults; data = eeglab2fieldtrip(EEG,'preprocessing');

% ======================================================================= %
% Extract & save necessary trial information and data
% ======================================================================= %

% Selecting trials to be used
trialStruct.accuracy(trialStruct.eventtype == 2 & ...
                             (trialStruct.reactionTime < 200 | trialStruct.reactionTime > 1200),1) = 0;
trialStruct.accuracy(trialStruct.eventtype == 5 & ...
                             (trialStruct.reactionTime < 200 | trialStruct.reactionTime > 2000),1) = 0;
trials = trialStruct.eventtype==2 & trialStruct.accuracy==1 & ~any([trialStruct.artThresh trialStruct.rmEpoch],2);

% Extracting only trials necessary to run GLM's with
cfg=[];
cfg.keeptrials = 'yes';
cfg.trials = trials;
data = eeglab2fieldtrip(EEG,'preprocessing');
ERPdat = ft_timelockanalysis(cfg, data);

% Saving necessary data for GLM's
save(fullfile(outDir,[subID '_Dat4GLM.mat']),'ERPdat','trialStruct','trials');

end