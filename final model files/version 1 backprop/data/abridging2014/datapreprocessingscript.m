%% Save tables as csvs (Note: before running this script, need to open all subjects *_byresponse.mat' files)
directory = 'D:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\single\by subjects and responses\shorts';
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'};

for i = 1:length(subjects)
    varnames = who(strcat('*_', subjects{i}));
    for j = 1:6
        file_name = strcat(varnames(j), '.csv');
%       file_dir = [directory filesep file_name];
        current_table = table2array(varnames(j));
%       writetable(current_table, current_file);
%       disp(varnames(n));
%       disp(current_table(1,1));
        eval(['dataset = ',current_table,';']);
        writetable(dataset, file_name{1});

    end
end

%% Construct data 1: index matrix for baseline (input) -> response (target) mapping
single_short = [0.7, 0.2]; % i.e. 700ms traverse time, 2 up-and-down brush sweeps
double_short = [0.1, 0.2]; % i.e. 100ms, 2 up-and-down sweeps
single_long = [0.7, 0.10]; % i.e. 700ms, 10 up-and-down sweeps
double_long = [0.1, 0.10]; % i.e. 100ms, 10 up-and-down sweeps
% We want every possible combination of inputs to targets.
    % Therefore, we want 6^2 permutations (6C2) of two-element vectors
    % MATLAB offers nchoosek function but not pchoosek.
    % Since we're dealing with 2 column matrix, we can simply flip combntn
    %   matrix horizontally to get perm. matrix.
    %   We also want repeats so append these @ end then randomise row order
    % Resultant matrix is used as as indices to map inputs -> targets for
    %   thorough cross-validation
responses = 6; % 6 runs for each subject
combos = nchoosek(1:responses, 2); % 2 because we're mapping inputs->targets
perm_count = length(combos)*factorial(2);
perms_wrepeats = responses^2;
idx = 1;
% NOTE: this method will only work w/ 2 column (variable) matrix
%   [which is fine since we're only ever going to be mapping input to target data]
for m = 1:perms_wrepeats
%     perms(m,:) = randperm(6,2);
   if m > perm_count
       perms(m,:) = m - perm_count;
   else
       perms(m,:) = combos(idx, :);
   end

   if (m == perm_count/2)
       combos = fliplr(combos);
       idx = 1;
   else
       idx = idx + 1;
   end
end

% shuffle row order
perms = perms(randperm(size(perms,1)),:);

%% Construct data 2: creating dataset
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'};
short_runs = 4;
long_runs = 2;
target_locations = 4;
perms_per_pair = (long_runs^2)*target_locations;
rowperms_per_pair = perms_per_pair/target_locations;
rowcombos = nchoosek(1:long_runs, 2);
rowperm_count = size(rowcombos,1)*factorial(2);
idx = 1;
for a = 1:rowperms_per_pair
    if a > rowperm_count
        rowperms(a,:) = a - rowperm_count;
    else
        rowperms(a,:) = rowcombos(idx, :);
    end

    if (a == rowperm_count/2)
        rowcombos = fliplr(rowcombos);
        idx = 1;
    else
        idx = idx + 1;
    end
end

% shuffle row mapping
rowperms = rowperms(randperm(size(rowperms,1)),:);

total_perms = perms_per_pair*perms_wrepeats;
for x = 1:length(subjects)
    idx = 1;
    subject_input_data = zeros(total_perms, 3);
    subject_target_data = zeros(total_perms, 1);
    target_vars = who(strcat('response*', subjects{x}));
    input_vars = who(strcat('base*', subjects{x}));
    for y = 1:perms_wrepeats
%         index_in = perms(x,1);
%         index_targ = perms(x,2);
        in_name = table2array(input_vars(perms(y,1)));
        targ_name = table2array(target_vars(perms(y,2)));
        eval(['current_in = ',in_name,';']);
        eval(['current_targ = ',targ_name,';']);
        for z = 1:rowperms_per_pair
            current_row_in = table2array(current_in(rowperms(z,1),:));
            current_row_targ = table2array(current_targ(rowperms(z,2),:));
            col_shuffler = randperm(4);
            for p = 1:4
                subject_input_data(idx,2:3) = double_long;
                subject_input_data(idx,1) = current_row_in(col_shuffler(p))/1000;
                subject_target_data(idx) = current_row_targ(col_shuffler(p))/1000;
                disp(idx);
                idx = idx + 1
            end
        end
    end
    input_filename = strcat(subjects{x}, '_long_inputdataset.csv');
    target_filename = strcat(subjects{x}, '_long_targetdataset.csv');
    writetable(array2table(subject_input_data), input_filename);
    writetable(array2table(subject_target_data), target_filename);
end

%% Construct data set 3: cross-validation
wrapN = @(x, N) (1 + mod(x-1,N));
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'};
short = '_short_';
long = '_long_';
for i = 1:length(subjects)
    inputcsvname_short = strcat(subjects{i}, short, 'inputdataset.csv');
    targetcsvname_short = strcat(subjects{i}, short, 'targetdataset.csv');
    input_short = csvread(inputcsvname_short,1,0);
    target_short = csvread(targetcsvname_short,1,0);
    % 70% for training, 20% for validation, 10% for testing (cycle)
    % say we have 20 cross-validations; we should shift sets by ~100 w/each
    data_length = length(input_short);
    training_length = floor(data_length*0.7);
    validation_length = floor(data_length*0.2);
    testing_length = floor(data_length*0.1);
    for j = 1:22
        training_start = round(wrapN(j*100 - 99, data_length));
        validation_start = round(wrapN(training_start + 0.7*data_length, data_length));
        testing_start = round(wrapN(training_start + 0.9*data_length, data_length));
        disp('training start: ');
        disp(training_start);
        disp('testing start: ');
        disp(testing_start);
        disp('validation start: ');
        disp(validation_start);
        for k = 1:training_length
            if (k+training_start > data_length)
                current_training_input_set(k,:) = input_short(wrapN(k+training_start,data_length),:);
                current_training_target_set(k,1) = target_short(wrapN(k+training_start,data_length));
            else
                current_training_input_set(k,:) = input_short(training_start+k,:);
                current_training_target_set(k,1) = target_short(training_start+k);
            end
        end

        for l = 1:validation_length
           if (l+validation_start > data_length)
               current_validation_input_set(l,:) = input_short(wrapN(l+validation_start,data_length),:);
               current_validation_target_set(l,1) = target_short(wrapN(l+validation_start,data_length));
           else
               current_validation_input_set(l,:) = input_short(validation_start+l,:);
               current_validation_target_set(l,1) = target_short(validation_start+l);

           end
        end

        for m = 1:testing_length
           if (m+testing_start > data_length)
               current_testing_input_set(m,:) = input_short(wrapN(m+testing_start, data_length),:);
               current_testing_target_set(m,1) = target_short(wrapN(m+testing_start, data_length));
           else
               current_testing_input_set(m,:) = input_short(testing_start+m,:);
               current_testing_target_set(m,1) = target_short(testing_start+m);
           end
        end

        training_input_filename = strcat(subjects{i}, short, 'trainingINPUT_', int2str(j), '.csv');
        training_target_filename = strcat(subjects{i}, short, 'trainingTARGET_', int2str(j), '.csv');
        testing_input_filename = strcat(subjects{i}, short, 'testingINPUT_', int2str(j), '.csv');
        testing_target_filename = strcat(subjects{i}, short, 'testingTARGET_', int2str(j), '.csv');
        validation_input_filename = strcat(subjects{i}, short, 'validationINPUT_', int2str(j), '.csv');
        validation_target_filename = strcat(subjects{i}, short, 'validationTARGET_', int2str(j), '.csv');

        writetable(array2table(current_training_input_set), training_input_filename);
        writetable(array2table(current_training_target_set), training_target_filename);
        writetable(array2table(current_testing_input_set), testing_input_filename);
        writetable(array2table(current_testing_target_set), testing_target_filename);
        writetable(array2table(current_validation_input_set), validation_input_filename);
        writetable(array2table(current_validation_target_set), validation_target_filename);

    end
end


%% Construct data set 4: concatenate cross-testing sets by subject
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'};
short = '_short_';
long = '_long_';
for i = 1:length(subjects)
    all_input_csv = [];
    all_target_csv = [];
    for j = 1:22
       testing_input_file_names{j} = strcat(subjects{i}, short, 'testingINPUT_', int2str(j), '.csv');
       testing_target_file_names{j} = strcat(subjects{i}, short, 'testingTARGET_', int2str(j), '.csv');
%        testing_input_file_names(j) = strcat(subjects{j}, short, 'validaINPUT_', int2str(j), '.csv');
       input_var_names{j} = strcat('testing_input_csv_', int2str(j));
       target_var_names{j} = strcat('testing_target_csv_', int2str(j));
       eval([input_var_names{j}, ' = csvread(testing_input_file_names{j},1,0);']);
       eval([target_var_names{j}, ' = csvread(testing_target_file_names{j},1,0);']);
       all_input_csv =  [all_input_csv; eval(input_var_names{j})];
       all_target_csv = [all_target_csv; eval(target_var_names{j})];
    end
    testing_input_dataset_name = strcat(subjects{i}, short, 'double_testing_input_data.csv');
    testing_target_dataset_name = strcat(subjects{i}, short, 'double_testing_target_data.csv');
    writetable(array2table(all_input_csv), testing_input_dataset_name);
    writetable(array2table(all_target_csv), testing_target_dataset_name);

end

%% Format data so runs are in same order as experiment
clear;
clc;
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'};
short = '_shortsALL_';
long = '_longsALL_';
target_directory = 'D:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\double\by subject and response\shorts';
shorts_directory = 'D:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\single\by subject and response\shorts';
longs_directory = 'D:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\single\by subject and response\longs';
savedirectory = 'D:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\single\ordered data';

for i = 1:length(subjects)
    ordered_input = [];
    ordered_target = [];
    single_short = [0.7, 0.02]; % i.e. 700ms traverse time, 2 up-and-down brush sweeps
%     double_short = [0.1, 0.02]; % i.e. 100ms, 2 up-and-down sweeps
    single_long = [0.7, 0.10]; % i.e. 700ms, 10 up-and-down sweeps
%     double_long = [0.1, 0.10]; % i.e. 100ms, 10 up-and-down sweeps
%     inputcsvname_short = strcat(subjects{i}, short, 'inputdataset.csv');
%     inputcsvname_long = strcat(subjects{i}, short, 'targetdataset.csv');
%     input_short = csvread(inputcsvname_short,1,0);
%     target_short = csvread(targetcsvname_short,1,0);
    idx = 1;
    for j = 1:6
        inputcsvname_short = [shorts_directory filesep strcat('single_response', int2str(j), short, subjects{i}, '.csv')];
        inputcsvname_long = [longs_directory filesep strcat('single_response', int2str(j), long, subjects{i}, '.csv')];
        targetcsvname = [target_directory filesep strcat('base', int2str(j), '_shorts_noCfitted_', subjects{i}, '.csv')];
        current_short_response = csvread(inputcsvname_short,1,0);
        current_long_response = csvread(inputcsvname_long,1,0);
        current_targets = csvread(targetcsvname,1,0);
        short_prelim_response_ordering = randperm(4); short_1_response_ordering = randperm(4); short_2_response_ordering = randperm(4); short_3_response_ordering = randperm(4);
        long_1_response_ordering = randperm(4); long_2_response_ordering = randperm(4);
%         ordered_input(j:j+3,1) = current_short_response(1, short_prelim_response_ordering(1:4));
%         ordered_input(j+4:j+7,1) = current_short_response(2, short_response
        ordered_input(idx:idx+3,1) = current_short_response(1, short_prelim_response_ordering(1:4));
        ordered_targets(idx:idx+3,1) = current_targets(1, short_prelim_response_ordering(1:4));
        ordered_input(idx+24:idx+27,1) = current_short_response(2, short_1_response_ordering(1:4));
        ordered_targets(idx+24:idx+27,1) = current_targets(2, short_1_response_ordering(1:4));
        ordered_input(idx+48:idx+51,1) = current_short_response(3, short_2_response_ordering(1:4));
        ordered_targets(idx+48:idx+51,1) = current_targets(3, short_2_response_ordering(1:4));
        
        for x = idx:idx+51
            ordered_input(x, 2:3) = single_short(1,:); 
        end 
        
        ordered_input(idx+72:idx+75,1) = current_long_response(1, long_1_response_ordering(1:4));
        ordered_targets(idx+72:idx+75,1) = current_targets(3, long_1_response_ordering(1:4));
        target_ordering = randperm(2);
        ordered_input(idx+96:idx+99,1) = current_long_response(2, long_2_response_ordering(1:4));
        ordered_targets(idx+96:idx+99,1) = current_targets(2+target_ordering(1), long_2_response_ordering(1:4));
        
        for y = idx+72:idx+99
            ordered_input(y,2:3) = single_long(1,:); 
        end 
        
        ordered_input(idx+120:idx+123,1) = current_short_response(4, short_3_response_ordering(1:4));
        ordered_targets(idx+120:idx+123,1) = current_targets(2+target_ordering(1), long_2_response_ordering(1:4));
        
        for z = idx+120:idx+123
            ordered_input(z,2:3) = single_short(1,:); 
        end 
        
        idx = idx + 4;
    end

    saved_inputs_name = [savedirectory filesep strcat(subjects{i}, '_single_ordered_INPUT_data.csv')];
    saved_targets_name = [savedirectory filesep strcat(subjects{i}, '_single_ordered_TARGET_data.csv')];
    writetable(array2table(ordered_input), saved_inputs_name);
    writetable(array2table(ordered_targets), saved_targets_name);

end

%% Compression data (figure 4B, 2014) pre-processing

directory = 'D:\checkout\elec4712-elec4713-thesis\final model files\version 1 backprop\data\abridging2014\nodirection\compression data';
input_set = csvread([directory filesep 'Abridging2014CompressionInputs.csv']);
target_set = csvread([directory filesep 'Abridging2014CompressionTargets.csv']);



input_set_scaled = linear_scale(input_set);
target_set_scaled = linear_scale(target_set);

% [target_set_scaled, target_set_scaled_PS] = mapminmax(target_set); 
% target_set_scaled = mapminmax('apply', target_set, input_set_scaled_PS); 
input_set_z = zscore(input_set);
target_set_z = zscore(target_set); 

indices = crossvalind('Kfold',target_set_scaled,10);

% mse = crossval('mse',input_set,target_set,'Predfun',feedforwardnet); 



%% Function definitions

function normalised_data = linear_scale(data)
% Normalise values of an array to be between -1 and 1
% (original sign of array values is maintained)
if abs(min(data)) > max(data)
    max_range_value = abs(min(data));
    min_range_value = min(data);
else
    max_range_value = max(data);
    min_range_value = -max(data);
end

normalised_data = 2.*data./(max_range_value - min_range_value); 
end

% **** Example (How to use function) *******
%
% hidlaysize1 = [15 30 70];
% hidlaysize2 = [10 20 50];
% trainopt = {'traingd' 'traingda' 'traingdm' 'traingdx'}; 
% maxepoch = [10 20 40 90];
% transferfunc = {'logsig' 'tansig'};
% bestparameters = gridSearchNN(x_train',y_train',hidlaysize1,...
%                               hidlaysize2,trainopt,maxepoch,transferfunc);
function out = gridSearchNN(trainX,trainY,param1,param2,param3,param4,...
                                   param5,varargin)
if(nargin > 4)
[p,q,r,s,t] = ndgrid(param1,param2,1:length(param3),param4,1:length(param5));
pairs = [p(:) q(:) r(:) s(:) t(:)];
% scoreboard = cell(size(pairs,1),4);
else
[p,q] = meshgrid(param1,param2);
pairs = [p(:) q(:)];
% scoreboard = cell(size(pairs,1),3);
end
valscores = zeros(size(pairs,1),1);
for i=1:size(pairs,1)
  setdemorandstream(672880951)
  net = patternnet([pairs(i,1) pairs(i,2)]);
  net.trainFcn = param3{pairs(i,3)};
  net.trainParam.epochs	= pairs(i,4);
  net.layers{2}.transferFcn = param5{pairs(i,5)};
  net.divideParam.trainRatio = 0.9;
  net.divideParam.valRatio = 0.1;
  net.divideParam.testRatio = 0;  
  
   vals = crossval(@(XTRAIN, YTRAIN, XTEST, YTEST)NNtrain(XTRAIN, YTRAIN, XTEST, YTEST, net),...
                     trainX, trainY);
   valscores(i) = mean(vals);  
%   net = train(net,trainX,trainY);
%   y_pred = net(valX);    
%   [~,indicesReal] = max(valY, [], 1); %336x1 matrix
%   [~, indicesPredicted] = max(y_pred,[],1);
%   valscores(i) = mean(double(indicesPredicted == indicesReal)); 
end
 [~,ind] = max(valscores);
 out = {pairs(ind,1) pairs(ind,2) param3{pairs(ind,3)} ...
        pairs(ind,4) param5{pairs(ind,5)}};
end
function testval = NNtrain(XTRAIN, YTRAIN, XTEST, YTEST, net)
    net = train(net, XTRAIN', YTRAIN');
    y_pred = net(XTEST');
    [~,indicesReal] = max(YTEST',[],1);
    [~,indicesPredicted] = max(y_pred,[],1);
     testval = mean(double(indicesPredicted == indicesReal));      
end
