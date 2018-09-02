%% All location codes
clear
row_names = strings(64,1); 
for i = 0:32
    location_codes(i+1,:) = de2bi(i,6,'left-msb');
    row_names(i+1) = strcat(num2str(i*0.6), " cm"); 
    if i ~= 32
        str = num2str(i); 
        row_names(i+33) = strcat("Unused (",str,")"); 
    else
        row_names(i*2) = "Occluded"; 
        location_codes(i*2,:) = de2bi(63,6,'left-msb'); 
    end 
end 

var_names = {"Bit_1_MSB" "Bit_2" "Bit_3" "Bit_4" "Bit_5" "Bit_6_LSB"}; 
location_codes_table = array2table(location_codes, 'RowNames', cellstr(row_names), 'VariableNames', cellstr(var_names)); 
data_directory = 'D:\Uniwork\6th year\Thesis\Milestones\10th of August milestones (SIMBRAIN)\V. SORN for 2014 abridging localisation\data'; 
all_location_codes_csv = [data_directory filesep 'all_location_codes_14.5cms_41.38msinterval.csv'];
writetable(location_codes_table, all_location_codes_csv, 'WriteRowNames', true); 
% speed = 14.5 cm/s
% each location code is 0.6 cm apart

%% Short run (single brushing)
clear short_single_run_once short_single_run_twice short_single_run_once_table short_single_run_twice_table
for n = 1:33  
    current_location = bin2dec(num2str(location_codes(n,:)))*0.6; 
    if (current_location >= 4.6) && (current_location <= 14.6)
        short_single_run_once(n,:) = location_codes(64);
    else 
        short_single_run_once(n,:) = location_codes(n,:); 
    end
end 

flipped_single_run_array = flipud(short_single_run_once); 
short_single_run_once = [short_single_run_once; flipped_single_run_array(2:end-1,:)]; 

short_single_run_twice = [short_single_run_once; short_single_run_once]; 
short_single_run_once_table = array2table(short_single_run_once); short_single_run_twice_table = array2table(short_single_run_twice); 

data_directory = 'D:\Uniwork\6th year\Thesis\Milestones\10th of August milestones (SIMBRAIN)\V. SORN for 2014 abridging localisation\data'; 
short_single_run_once_csv = [data_directory filesep 'short_single_run_once_14.5cms_41.38msinterval.csv']; short_single_run_twice_csv = [data_directory filesep 'short_single_run_twice_14.5cms_41.38msinterval.csv'];
writetable(short_single_run_once_table, short_single_run_once_csv); writetable(short_single_run_twice_table, short_single_run_twice_csv); 

%% Short run (double brushing)
clear short_double_run_once short_double_run_twice short_double_run_once_table short_double_run_twice_table
b1_current = 0.0;
b2_current = 9.0; 
cnt = 1;
while (b2_current < 19.2) 
    b1_current = bin2dec(num2str(location_codes(cnt,:)))*0.6; 
    b2_current = b1_current + 9.0;
    if (b1_current >= 4.6) && (b2_current <= 14.6)
        short_double_run_once(cnt,:) = location_codes(64);
    elseif (b1_current >= 4.6)
        short_double_run_once(cnt,:) = de2bi(round((b2_current/0.6)),6,'left-msb');
    elseif (b2_current <= 14.6)
        short_double_run_once(cnt,:) = de2bi(round((b1_current/0.6)),6,'left-msb');
    end 
    cnt = cnt + 1; 
end    

flipped_double_run_array = flipud(short_double_run_once); 
short_double_run_once = [short_double_run_once; flipped_double_run_array(2:end-1,:)]; 
short_double_run_twice = [short_double_run_once; short_double_run_once]; 
short_double_run_once_table = array2table(short_double_run_once); short_double_run_twice_table = array2table(short_double_run_twice); 

data_directory = 'D:\Uniwork\6th year\Thesis\Milestones\10th of August milestones (SIMBRAIN)\V. SORN for 2014 abridging localisation\data'; 
short_double_run_once_csv = [data_directory filesep 'short_double_run_once_14.5cms_41.38msinterval.csv']; short_double_run_twice_csv = [data_directory filesep 'short_double_run_twice_14.5cms_41.38msinterval.csv'];
writetable(short_double_run_once_table, short_double_run_once_csv); writetable(short_double_run_twice_table, short_double_run_twice_csv); 

%% Long (single and double pre-runs)

% 2 up-and-down single runs = 6 seconds. For the single long pre-run, we
% want 7.5 minutes = 450 seconds of non-stop up and down brushing.
% This is 450/6 = 75 of the short_single_run_twice concatenated

% 2 up-and-down double runs = 3 seconds. For the double long pre-run, we
% want 4 minutes = 240 seconds of non-stop up and down brushing.
% This is 240/3 = 80 of the short_double_run_twice concatenated.

% Therefore, we'll concatenate each 80 times (since 75 is close to 80)

long_single_prerun_160 = short_single_run_twice; 
long_double_prerun_160 = short_double_run_twice;
for k = 1:80
    long_single_prerun_160 = [long_single_prerun_160; short_single_run_twice]; 
    long_double_prerun_160 = [long_double_prerun_160; short_double_run_twice];  
end

long_single_prerun_160_table = array2table(long_single_prerun_160); long_double_prerun_160_table = array2table(long_double_prerun_160); 

data_directory = 'D:\Uniwork\6th year\Thesis\Milestones\10th of August milestones (SIMBRAIN)\V. SORN for 2014 abridging localisation\data'; 
long_single_prerun_160_csv = [data_directory filesep 'long_single_prerun_160_14.5cms_41.38msinterval.csv']; long_double_prerun_160_csv = [data_directory filesep 'long_double_prerrun_160_14.5cms_41.38msinterval.csv'];
writetable(long_single_prerun_160_table, long_single_prerun_160_csv); writetable(long_double_prerun_160_table, long_double_prerun_160_csv); 