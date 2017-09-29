function design = tools_createPrediction(pred,dummyCount)

% Creating all combination of contrast indicators using ndgrid
% Statement below will dynamically go through all available main factor in
% order to run ndgrid and output the necessary number of outputs based on
% the number of inputs
% ======================================================================= %
factors = fieldnames(pred);
evalstatement = '[';
    for fi = 1:length(factors)
        evalstatement = [evalstatement sprintf('pred.%s,',factors{fi})];
    end
evalstatement = [evalstatement(1:end-1) '] = ndgrid('];
    for fi = 1:length(factors)
        evalstatement = [evalstatement sprintf('pred.%s,',factors{fi})];
    end
evalstatement = [evalstatement(1:end-1) ');']; eval(evalstatement); clear evalstatement

% Unwrapping the results provided by ndgrid
% ======================================================================= %
for fi = 1:length(factors)
    if dummyCount(fi) > 0
        pred.(factors{fi}) = dummyvar(pred.(factors{fi})(:));
    else
        pred.(factors{fi}) = pred.(factors{fi})(:);
    end
end

% Starting our contrast table with the main factors
% ======================================================================= %
evalstatement = 'pred_table = table(';
evalstatement2 = 'pred_table.Properties.VariableNames = {';
for fi = 1:length(factors)
    evalstatement = [evalstatement sprintf('pred.%s,',factors{fi})];
    evalstatement2 = [evalstatement2 sprintf('''%s'',',factors{fi})];
end
evalstatement = [evalstatement(1:end-1) ');'];
evalstatement2 = [evalstatement2(1:end-1) '};'];
eval(evalstatement); eval(evalstatement2); clear evalstatement evalstatement2

% Creating all possible interaction terms - full factorial & add to
% contrast table started above
% ======================================================================= %
for ix = 2:length(factors(2:end))
    interactions.(sprintf('ix_%d',ix)) = nchoosek(factors(2:end),ix);    
    factorID.(sprintf('ix_%d',ix)) = nchoosek(2:length(factors),ix); % --- for indexing purposes
end
repcount = zeros(1,length(dummyCount));
repcount(dummyCount > 0) = prod(dummyCount(dummyCount> 0))./dummyCount(dummyCount>0);
repcount(dummyCount == 0) = prod(dummyCount(dummyCount> 0));

for ix = 2:length(factors(2:end))
    temp_ix = interactions.(sprintf('ix_%d',ix));
    temp_id = factorID.(sprintf('ix_%d',ix));
    for iix = 1:size(temp_ix)
        try
            evalstatement = sprintf('tempDat = pred_table.%s',temp_ix{iix,1}); 
            for ci = 2:size(temp_ix,2)
                evalstatement = [evalstatement sprintf('.*pred_table.%s',temp_ix{iix,ci})];
            end
            eval([evalstatement ';']);
        catch
            evalstatement = sprintf('tempDat = repmat(pred_table.%s,1,repcount(temp_id(%d,1)))',temp_ix{iix,1},iix);
            for ci = 2:size(temp_ix,2)
                evalstatement = [evalstatement sprintf('.*repmat(pred_table.%s,1,repcount(temp_id(%d,%d)))',temp_ix{iix,ci},iix,ci)];
            end
            eval([evalstatement ';']);
        end
        
        % creating a temporary table for the new interaction 
        tempTable = table(tempDat);
        evalstatement = sprintf('tempLabel = strcat(temp_ix{%d,1}',iix);
        for ci = 2:size(temp_ix,2)
            evalstatement = [evalstatement sprintf(',''_'',temp_ix{%d,%d}',iix,ci)];
        end
        eval([evalstatement ');']);
        tempTable.Properties.VariableNames = {tempLabel};
        
        % adding the temp table to our main prediction table
        pred_table = [pred_table,tempTable];
        clear evalstatement tempTable tempDat
    end
end
            
% Prediction table with associated labels
design = table2array(pred_table);


