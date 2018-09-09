%% Save tables as csvs (Note: before running this script, need to open all subjects *_byresponse.mat' files)
directory = 'E:\checkout\elec4712-elec4713-thesis\simbrain\datasets\abridging2014\nodirection\reduced supervised model data\double\by subjects and responses\longs'; 
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'}; 

for i = 1:length(subjects)
    varnames = who(strcat('*_', subjects{i}));  
    for j = 1:12
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
single_short = [0.7, 0.02]; % i.e. 700ms traverse time, 2 up-and-down brush sweeps
double_short = [0.1, 0.02]; % i.e. 100ms, 2 up-and-down sweeps
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
clear;
clc; 
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
%         disp('training start: ');
%         disp(training_start);
%         disp('testing start: ');
%         disp(testing_start);
%         disp('validation start: ');
%         disp(validation_start); 
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

%% Construct data set 4: concatenate cross-training sets by subject
clc;
clear; 
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'}; 
long = '_long_';
short = '_short_';
for i = 1:length(subjects)
    all_input_csv = []; 
    all_target_csv = []; 
    for j = 1:22
       training_input_file_names{j} = strcat(subjects{i}, short, 'validationINPUT_', int2str(j), '.csv');
       training_target_file_names{j} = strcat(subjects{i}, short, 'validationTARGET_', int2str(j), '.csv');
%        training_input_file_names(j) = strcat(subjects{j}, long, 'validaINPUT_', int2str(j), '.csv');
       input_var_names{j} = strcat('testing_input_csv_', int2str(j)); 
       target_var_names{j} = strcat('testing_target_csv_', int2str(j)); 
       eval([input_var_names{j}, ' = csvread(training_input_file_names{j},1,0);']); 
       eval([target_var_names{j}, ' = csvread(training_target_file_names{j},1,0);']); 
       all_input_csv =  [all_input_csv; eval(input_var_names{j})];
       all_target_csv = [all_target_csv; eval(target_var_names{j})];
    end
    training_input_dataset_name = strcat(subjects{i}, short, 'double_validation_input_data.csv'); 
    training_target_dataset_name = strcat(subjects{i}, short, 'double_validation_target_data.csv'); 
    writetable(array2table(all_input_csv), training_input_dataset_name);
    writetable(array2table(all_target_csv), training_target_dataset_name);

end 

%% Normalise final dataset (0 to 1)
clear;
clc;
normCol = @(column) (column - min(column))/(max(column) - min(column));
roundN = @(x,n) round(x*10^n)./10^n; 
single_short = [0.7, 0.02]; % i.e. 700ms traverse time, 2 up-and-down brush sweeps
double_short = [0.1, 0.02]; % i.e. 100ms, 2 up-and-down sweeps
single_long = [0.7, 0.10]; % i.e. 700ms, 10 up-and-down sweeps
double_long = [0.1, 0.10]; % i.e. 100ms, 10 up-and-down sweeps
subjects = {'sonya', 'annie', 'fahed', 'hamid', 'julian', 'nastaran', 'norfizah', 'paja', 'rachel', 'sarah'}; 
long = '_long_';
short = '_short_';
training = 'double_training_';
testing = 'double_testing_';
validation = 'double_validation_';
inputtag = 'input_data.csv';
targettag = 'target_data.csv'; 
for i = 1:length(subjects)
    inFileName = strcat(subjects{i}, short, validation, inputtag);
    targFileName = strcat(subjects{i}, short, validation, targettag);
    in = csvread(inFileName, 1, 0);
    targ = csvread(targFileName, 1, 0);
    incolumn = in(:,1);
    targcolumn = targ(:,1); 
    incolnorm = normCol(incolumn); 
    targcolnorm = normCol(targcolumn); 
    for j = 1:size(incolumn,1)
        inOut(j,2:3) = double_long; 
        inOut(j,1) = incolnorm(j);
        targOut(j,1) = targcolnorm(j);  
    end
    roundedInTable = array2table(roundN(inOut,3)); 
    roundedTargTable = array2table(roundN(targOut,3)); 
    writetable(roundedInTable, strcat('norm_', inFileName));
    writetable(roundedTargTable, strcat('norm_', targFileName)); 
end 

