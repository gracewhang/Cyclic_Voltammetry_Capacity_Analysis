%CV_Capacity_Analysis (01/07/21)
%The program can take a .txt file input of CV data and calculate the
%capacity. The data must have:
%time (hours) in column 1
%current (mA)in column 2

%% Data Import
clc;
clear all;
fprintf('Select your CV file. Reminder: \nMake sure column 1= time [hours] column 2= current [mA]\n'); % prints instructions on command window
[filename,path]=uigetfile('*.txt','Select your CV file'); % selects only .txt files and "Select your CV file" appears on window bar
fid=fullfile(path,filename);
data=importdata(fid); %imports txt file data into workspace

time=data.data(:,1); %assigns column 1 of data to the variable "current"
current=data.data(:,2); %assigns column 2 of data to the variable "time"
time=time-time(1);  %this baselines the first time point to be the 0 hr mark


%% Create Plot of Raw Data
figure %create new figure window
plot(time,current,'o-','MarkerSize',2,'Color','#C88691')
%set plot parameters
x0=10; %border pixel
y0=10; %border pixel
width=800;
height=600;
set(gcf,'position',[x0,y0,width,height]) %current figure settings
set(gca,'Fontsize',18,'FontName','Calibiri','color','none') %current axis; set axis font to size 14 calibiri

%set plot axis labels
xlabel('Time (hr)') %designate x axis label
ylabel('Current (mA)') %designate y axis label


%% Now lets process the current vs time data
%--> find out when plot crosses y axis to determine our integral limits

x=length(current); %figure out the length of data that we should scan through
c=1; %create counter variable to keep track of index while scanning through the "current" array
critical_index=[]; %keeps track of the actual position and not the time at the critical position
critical_time=[]; %create vector in which we will add the critical points; yes, I know-this is no computationally efficient
d=2; %creates counter variable for critical time array location- note:starts at 2 since first position is reserved for t=0
critical_time(1)=0; %sets first crititical time as the starting time in data set (should be 0)
critical_index(1)=0;
%we'll scan through each of our current values looking for 0
while c<x
    if current(c)*current(c+1) < 0 %when the signs of the current and next data point are different
        critical_time(d)=time(c);
        critical_index(d)=c;
        d=d+1; %increment whenever we do add a new d value to critical time array
    end
    c=c+1; %increment
end


%% integrate
F = griddedInterpolant(time,current); %Interpolate entire data
func = @(t) F(t); %create function for entire data

figure %for each iteration generate new plot
x0=10; %border pixel
y0=10; %border pixel
width=800;
height=600;

set(gcf,'position',[x0,y0,width,height]) %current figure
set(gca,'Fontsize',18,'FontName','Calibiri','color','none')
plot(time,func(time),'o-') %plot function

%designate colors for integration shading
% ~~ in the future, need to figure out how it can just loop colors
newcolors = {'#C88691','#AD85BA','#95A1c3','#74A18E','#81ADB5','#B2C891','#B99C6B','#E49969','#C9C27F','#C88691','#AD85BA','#95A1c3','#74A18E','#81ADB5','#B2C891','#B99C6B','#E49969','#C9C27F'};
colororder(newcolors)

hold on

reduction=[];
oxidation=[];
r=1; %counter for reduction peak data
o=1; %counter for oxidation peak data

for i=1:length(critical_time) %integrate for how many crossover points we have on the y-axis

    if i==1  %for the first set of data, use time(1) as start time
%         q=integral(func,time(1),critical_time(i)); 
%         fprintf('\nIntegral from %.3f hr to %.3f hr is %.3f mAh\n',time(i),critical_time(i), q);
%         area(time(1:critical_index(i)),func(time(1:critical_index(i))),'FaceColor','#6495ed');
        q=integral(func,critical_time(i),critical_time(i+1));
        fprintf('\nIntegral from %.3f hr to %.3f hr is %.5f mAh\n',critical_time(i),critical_time(i+1), q);
        area(time(1:critical_index(i+1)),func(time(1:critical_index(i+1))),'FaceColor','#6495ed');
    end
    
    if i==length(critical_time) %for the last set of data, use ___ as end time
        q=integral(func,critical_time(i),time(end)); %NEED TO MAKE THIS WORK IN A LOOP
        fprintf('\nIntegral from %.3f hr to %.3f hr is %.5f mAh\n',critical_time(i),time(end), q); %integrate till end of the time array
        %embedded shading for last critical data set
        area(time(critical_index(i):end),func(time(critical_index(i):end)),'FaceColor','#AD85BA'); %need to change end to work for multi-cycle data
    end
    
    
    %for middle sets of data, use i and i+1 as limits of integration
    if i<length(critical_time) && i>1 
        q=integral(func,critical_time(i),critical_time(i+1));
        fprintf('\nIntegral from %.3f hr to %.3f hr is %.5f mAh\n',critical_time(i),critical_time(i+1), q);
        area(time(critical_index(i):critical_index(i+1)),func(time(critical_index(i):critical_index(i+1))),'FaceColor', newcolors{i})
    end
  
 %store reduction and oxidation capacity in an array   
    if q<0
        reduction(r)=q;
        r=r+1;
    else
        oxidation(o)=q;
        o=o+1;
    end
end
    hold off
    
x0=10; %border pixel
y0=10; %border pixel
width=800;
height=600;
set(gcf,'position',[x0,y0,width,height]) %current figure
set(gca,'Fontsize',18,'FontName','Calibiri','color','none') %current axis; set axis font to size 14 calibiri
xlabel('Time (hr)') %designate x axis label
ylabel('Current (mA)') %designate y axis label
%% create table with data
%sorts out reduction from oxidation peaks
%display in terms of capacity and specific capacity
%average and standard deviation
active_mass_input=input('\nWould you like to calculate specific capacity [mAh/g]? ("y" or "n"?): ','s');
if active_mass_input=='y'
    active_mass=input('\nEnter active material mass loading [mg]: ');
    fprintf('\nActive mass has been recorded.\n');
else
    fprintf('\nOnly capacity [mAh] will be reported\n');
end
%% This script removes capacity data stemming from partial(not-complete) peak data that might be present in the beginning of the data plotted
% It is important to look a the graph and see if there are initial snippets
% that do not capture a full cycle. The number of oxidation and reduction
% regions should be equal and not removing the initial excess (if present)
% will result in errors

scrap_peak=input('\nWould you like to remove any partial/cutoff peaks present in the beginning of your data? ["y" or "n"]: ','s');
if scrap_peak=='y'
    which_peak=input('\nIs the first peak a reduction[1] or oxidation peak[2]?: ');
    if which_peak==1
        reduction=reduction(2:end);
    elseif which_peak==2
        oxidation=oxidation(2:end);
    else
        fprintf('\nError. Neither 1 or 2 was chosen\n');    
    end
end
%% Output Table with Results
% The calculated capacities will be recorded into tables and a for loop
% will automatically create row labels for the number of cycles present in
% the data set

num_of_cycles=length(oxidation); % numbers of row names we need for the output table
rowNames={}; % empty cell to collect rowNames. 

%this for loop will generate the table row labels for each cycle in the data 
for j=1:num_of_cycles
   rowNames{j}= ['Cycle',num2str(j)];
end
varNames={'Reduction Capacity [mAh]', 'Oxidation Capacity [mAh]'}; %column labels
T = table(transpose(reduction),transpose(oxidation),'VariableNames',varNames,'RowNames',rowNames)

%% For Specific Capacity 
% specific capacity will be calculated based off of active mass input

if active_mass_input=='y'
fprintf('Since active mass was reported, here is also a table of specific capacities [mAh/g].\n')
reduction_spec=reduction/active_mass*1000; %1000 is a conversion between mg and g
oxidation_spec=oxidation/active_mass*1000;
varNames={'Reduction Specific Capacity [mAh/g]', 'Oxidation Specific Capacity [mAh/g]'};
T2 = table(transpose(reduction_spec),transpose(oxidation_spec),'VariableNames',varNames,'RowNames',rowNames)
end

%% export table
% saves table in the same directory as the file. If active mass was
% recorded, two txts file will be written for both capacity [mAh] and specific
% capacity [mAh/g]

save_table=input('Do you want to save table as a txt file? ["y" or "n"]: ','s');

if save_table=='y' 
    table_file_name=strcat(filename(1:end-4),' CV_Capacity_Table'); %filename(1:end-4) removes the .txt from filename
    table_path_format=[path table_file_name,'.txt'];
    writetable(T, table_path_format, 'Delimiter',' ');

    
    if active_mass_input=='y'
        table_file_name2=strcat(filename(1:end-4),' CV_Specific_Capacity_Table'); %filename(1:end-4) removes the .txt from filename
        table_path_format2=[path table_file_name2,'.txt'];
        writetable(T2, table_path_format2, 'Delimiter',' ');
    end
end
