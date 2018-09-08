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
                idx = idx + 1; 
            end 
        end 
    end 
    input_filename = strcat(subjects{x}, '_long_inputdataset.csv');
    target_filename = strcat(subjects{x}, '_long_targetdataset.csv'); 
    writetable(array2table(subject_input_data), input_filename);
    writetable(array2table(subject_target_data), target_filename); 
end 








