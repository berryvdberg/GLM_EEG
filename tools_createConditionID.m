function conditions = tools_createConditionID(design,cond,labels)

des = double(design);
mainID = find(cellfun(@isempty,strfind(labels,'_')));

des = des(:,mainID);
labels = labels(mainID);
tempLabels = cell(size(des,1),size(des,2));

for id = 1:size(des,1)
    tempDes = des(id,:);

    for ci = 1:size(tempDes,2)
        val = cond.Values{ci};
        label = val(cell2mat(val(:,1))==tempDes(ci),2);
        tempLabels(id,ci) = label; clear val label
    end
end
        
conditions = {};
for id = 1:size(tempLabels,1)
    evalstatement = sprintf('conditions = [conditions;strcat(tempLabels{%d,1}',id);
    for ci = 2:size(tempLabels,2)
        if strcmpi(tempLabels(id,ci),'Null')
            continue;
        end
        evalstatement = [evalstatement sprintf(',''_'', tempLabels{%d,%d}',id,ci)];
    end
    eval([evalstatement ')];']);
end


        