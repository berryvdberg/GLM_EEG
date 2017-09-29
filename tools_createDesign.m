function des = tools_createDesign(des)

% Function that goes through your design structure to build a full
% factorial model, using the factor names and data inside the deisgn
% structure fed into this script.
%
% The input design structure should have the following fields:
%
%     des.Factors:  All main factor names in cell matrix
%                   ex: {'task','incon','left','rts'};
%
%                   'task' is a factor that contains two dummy variables,
%                   one for each task being modeled. Task technically
%                   contains 3 levels, but kept one out in order to prevent
%                   model from being rank deficient.
%
%                   'incon' is a vector of binaries denoting if stroop stimulus
%                   was incongruent (1) or not (0)
%
%                   'left' is a vector of binaries denoting if a left hand
%                   was used to response (1) or not (0)
%
%                   'rts' is a vector continuous response times for each
%                   trials. You can put in the raw RT's or normalize it to
%                   help facilitate your contrast coding later.
%
%     des.Levels:   All levels per factor in cell matrix
%                   ex: {{'wm','cogload'},'incon','left','rts'};
%
%     des.DummyCount = If main factor contains dummy variables, this matrix
%                      includes the count of vars per factor: ex: [2,0,0,0];
%
%     des.Data = All data per factor in cell matrix
%                Each cell in the cell matrix contains a vector (m x n) of data
%                where each row (m) represents the trial and each column (n)
%                represents the levels you are modeling. If the data is for
%                a factor that was dummy coded, each column represents each
%                factor that was dummy coded.
%                ex: [{[[1;1;1;0;0;0],[0;0;0;1;1;1]]},{[0,1,0,1,1,1]},{[0,1,0,0,1,1]},{[1.2,3.2,2.3,2.2,1.5,2.1]}];
% 
% The output of this script is saved back to the design input file so that
% you can continue working on your model building afterward.
%
% Edit log:
%   Khoi D. Vo (Written - Sept. 20, 2017 - Duke University)
%       built & tested on MATLAB R2016a, macOS Sierra 10.12.5

% ======================================================================= %
% Setting up necessary environment to build full factorial model
% ======================================================================= %

% Creating all possible interaction terms - full factorial
% ======================================================================= %
for ix = 2:length(des.Factors)
    des.Interactions.(sprintf('ix_%d',ix)) = nchoosek(des.Factors,ix);    
    factorID.(sprintf('ix_%d',ix)) = nchoosek(1:length(des.Factors),ix); % --- for indexing purposes
    labels.(sprintf('ix_%d',ix)) = nchoosek(des.Levels,ix); % --- for labeling purposes (labeling of betas)
end

% Figure out which facor contains multiple columns of data (i.e. dummy
% coding) in order to correctly do element-wise matrix multiplication later
% ======================================================================= %
levels = zeros(1,length(des.DummyCount));
levels(des.DummyCount > 0) = prod(des.DummyCount(des.DummyCount> 0))./des.DummyCount(des.DummyCount>0);
levels(des.DummyCount == 0) = prod(des.DummyCount(des.DummyCount> 0));

% ======================================================================= %
% Constructing design matrix for full factorial
% ======================================================================= %
des.CondMatrix = {'Condition','Type','Labels','Data'};

    % main effects
    % =================================================================== %
    des.CondMatrix = [des.CondMatrix;...
                     [des.Factors',repmat({'main'},length(des.Factors),1),des.Levels',des.Data']];

    % interactions - dynamically go through all levels of interaction,
    % based on the number of factors entered (starts with 2-way interaction)
    % =================================================================== %
    for ix = 2:length(des.Factors)
        
        % building a list of interaction condition labels
        evalstatement = sprintf('temp = strcat(des.Interactions.ix_%d(:,1)',ix);
        for i = 2:size(des.Interactions.(sprintf('ix_%d',ix)),2)
            evalstatement = [evalstatement sprintf(',''_'',des.Interactions.ix_%d(:,%d)',ix,i)];
        end
        eval([evalstatement ');']);

        % For each interaction condition, create the data vector
        % If the interaction condition is between conditions with dummy
        % coding, this code will account for this and create multiple data
        % vectors accordingly.
        for ix_id = 1:size(temp,1)
            % building the interaction data vector(s)
            try
                evalstatement2 = sprintf('tempDat = des.Data{factorID.ix_%d(%d,1)}',ix,ix_id); 
                for ci = 2:size(factorID.(sprintf('ix_%d',ix)),2)
                    evalstatement2 = [evalstatement2 sprintf('.*des.Data{factorID.ix_%d(%d,%d)}',ix,ix_id,ci)];
                end
                eval([evalstatement2 ';']);
            catch
                evalstatement2 = sprintf('tempDat = repmat(des.Data{factorID.ix_%d(%d,1)},1,levels(factorID.ix_%d(%d,1)))',ix,ix_id,ix,ix_id);
                for ci = 2:size(factorID.(sprintf('ix_%d',ix)),2)
                    evalstatement2 = [evalstatement2 sprintf('.*repmat(des.Data{factorID.ix_%d(%d,%d)},1,levels(factorID.ix_%d(%d,%d)))',ix,ix_id,ci,ix,ix_id,ci)];
                end
                eval([evalstatement2 ';']);
            end

            % label(s) for the created data vector (e.g. beta label(s))
            evalstatement3 = sprintf('tempLabel = strcat(des.Levels{factorID.ix_%d(%d,1)}',ix,ix_id); 
            for ci = 2:size(factorID.(sprintf('ix_%d',ix)),2)
                evalstatement3 = [evalstatement3 sprintf(',''_'',des.Levels{factorID.ix_%d(%d,%d)}',ix,ix_id,ci)];
            end
            eval([evalstatement3 ');']);
            
            % save the results in a condition matrix
            des.CondMatrix = [des.CondMatrix;...
                             [temp(ix_id),sprintf('ix_%d',ix),{tempLabel},{tempDat}]];
            clear tempDat tempLabel evalstatement evalstatement2 evalstatement3
        end
        clear temp
    end
    
% Constructing a full factorial data matrix to run with matlab's glmfit
% If you do not want a full factorial model, then create a new matrix with
% the appropriate data for your desired betas using the information in
% des.CondMatrix.
des.DatMatrix = [];
for i = 2:size(des.CondMatrix,1)
    des.DatMatrix = [des.DatMatrix,des.CondMatrix{i,strcmpi(des.CondMatrix(1,:),'Data')}];
end
