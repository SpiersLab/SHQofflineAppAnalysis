%% script to process SHQ data from offline app

%EZ PATAI 2018-19
%UCL, Institute of Behavioural Neuroscience
%e.patai@ucl.ac.uk
%% USER INPUT START
%% set some stuff up (ie CHANGE THESE PATHS etc)

% %set the path to the data and the .m files needed for the script(parse_json.m)
addpath('/Users/ezpatai/Downloads/SHQofflineAppAnalysis-master/')

% % go to the directory with the data
cd '/Users/ezpatai/Downloads/Users/annabelvondietze/Desktop/RM_files_100420/'

% %lists all the folders with the json files inside (should be organized per participant, so this will find folders like: S045_XXXX etc))
listing = dir('/Users/ezpatai/Downloads/Users/annabelvondietze/Desktop/RM_files_100420/F*');

% % filename for excel output
outputfilename = '/Users/ezpatai/Downloads/Users/annabelvondietze/Desktop/RM_files_100420/summary_nonorm.xlsx';

%% all the levels you need (i.e. which you ran as part of your protocol)
%     %TG
%     needed=[1:4,6:9,11:14,16:19,21:24,26:29,31:34,36:39,41:43,43,43,44,49,54,59,64,69,74,100,200,300,400,500];
%     flares=[4,9,14,19,24,29,34,39,44,49,54,59,64,69,74];
%     radial=[100,200,300,400,500];%the radial levels i've added 00 to the end to differentiate from normal levels
%     normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)),[43,43]);

%     %EZP
    needed=[1:4,6:9,11:14,16:19,21:24,26:29,31:34,36:39,41:43,43,43,44,49,54,59,64,69,74,100,200,300,400,500];
    flares=[4,9,14,19,24,29,34,39,44,49,54,59,64,69,74];
    radial=[100,200,300,400,500];
    normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)),[43,43]);

%     %GZ
%     needed=[1,2,4,6,11,16,34,44,46,51,54,400];
%     flares=[4,34,44,54];
%     radial=[400];
%     normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)));
    
%% do you want to normalize results by level 1&2 (practice) 
normalize=0;
%% USER INPUT OVER
%% prepare the summary data
    summary_dist=nan(size(listing,1),size(normal_levels,2));
    summary_dur=nan(size(listing,1),size(normal_levels,2));
    summary_mapview=nan(size(listing,1),size(normal_levels,2));
    summary_flare=nan(size(listing,1),size(flares,2));
    summary_radialtech=nan(size(listing,1),size(radial,2));
    summary_radialacc=nan(size(listing,1),size(radial,2));
    summary_radialprobes=nan(size(listing,1),size(radial,2));
%% process files 
  
for s =1:size(listing,1)
    
    dirpath=strcat(listing(s).name,'/'); %name of the folder containing the file to process
    
    dir_data=dir([dirpath '*.json']);%load all the json files within this folder
    
    vect_distance=NaN(length(dir_data),1);%creates empty vector for future distance
    vect_duration=NaN(length(dir_data),1);%and duration
    
    %check what is 'real' data
    for i=1:length(dir_data)
        if strcmp('radial', dir_data(i).name(1:6)) | strcmp('level', dir_data(i).name(1:5))
            data(i)=1;
        else
            data(i)=0;
        end
    end
    
    for ifile=1:sum(data)%length(dir_data) %Loop over all the json file
        
        %Extract coordinates from current .json file
        filename = [dirpath dir_data(ifile).name];
        data_participant=importdata(filename);
        data_participant=[data_participant{:}];
        data_participant = parse_json(data_participant);
        data_participant=[data_participant{:}];
        route=[data_participant.player{:}];
        x_coord=5*[route.x];
        y_coord=5*[route.y];
        
        % %     %Plot coordinates over map
        % %     if strcmp('radial', dir_data(ifile).name(1:6))
        % %         map=imread('levels-export/radial.png');
        % %     else
        % %         level_nb=str2double(dir_data(ifile).name(6:6+2));
        % %         map=imread(['levels-export/level' num2str(level_nb) '.png']);
        % %     end
        % %     map=double(map(:,:,1));
        % %     map=flipud(map);
        % %     map=imcomplement(map);
        % %     map(map<1)=0; %binarise map
        % %
        % %     imshow(map,[])
        % %     %colormap('jet')
        % %     hold on
        % %     plot(x_coord,y_coord,'g','LineWidth',2)
        % %     axis([1 size(map,2) 1 size(map,1)])
        
        if strcmp('radial', dir_data(ifile).name(1:6))
            level_nb=str2double(dir_data(ifile).name(13:13+2))*100;
        else
            level_nb=str2double(dir_data(ifile).name(6:6+2));
        end
        
% %     get general duration/distance info

        d=diff([x_coord' y_coord']);% compute the distance
        dist=sum(sqrt(sum(d.^2,2)));
        
        duration=length(x_coord)/2; %comptute the duration because there are 2 points by second
        
        vect_distance(ifile)=dist; %store computed distance in array
        vect_duration(ifile)=duration;%store computed duration in array
        vect_levels(ifile)=level_nb;%store the list of levels completed
        
        if isfield(data_participant.meta, 'map_view_duration') == 1
        map_view_dur(ifile)=data_participant.meta.map_view_duration;
        else
            map_view_dur(ifile)=nan;
        end
        
        if isfield(data_participant.meta, 'flare_accuracy') ==1 
        flare_acc(ifile)=data_participant.meta.flare_accuracy;
        end
        
        if isfield(data_participant.meta, 'radial_technique') ==1 
            radial_tech(ifile)=data_participant.meta.radial_technique;
        else
            radial_tech(ifile)=nan;
        end
              
% %     get radial accuracies
        if level_nb == 100 || level_nb == 200 || level_nb == 300 || level_nb == 400 || level_nb == 500
                j=1;
                for i=1:size(data_participant.events,2)
                    if strcmp(data_participant.events{i}.type,'radial_section')==1
                        relevant_events(j)=i;
                        j=j+1;
                    else
                    end 
                end

                for i=1:size(relevant_events,2)
                    sections(i)=data_participant.events{relevant_events(i)}.section;
                    errors(i)=data_participant.events{relevant_events(i)}.error;%remember that error=1 is an error, so 0s and 1s are reversed in terms of accuracy
                end

                %radial acc
                dump=[];
                for i=1:size(sections,2)
                    dump=cat(2,dump,sections(i));
                    dump_u=size(unique(dump),2);
                    if dump_u <=3
                        part(i)=1;
                    else
                        part(i)=2;
                    end
                end

                s1=sections(part==1);s2=sections(part==2);

                [a,b]=hist(s2,unique(s2));

                probes=sum(a(b==2|b==3|b==6)/2);if isempty(probes)==1;probes=0;end

                tempp2=a(b==1|b==4|b==5)-2;
                wm_err=sum(tempp2(tempp2>1)/2);
  
                
                radial_probeerr(ifile)=probes;%entry into part1 arms in part2
                radial_wmerr(ifile)=wm_err;%multiple entry into already visited part2 arms in part2
                       
        
        else
                radial_probeerr(ifile)=nan;
                radial_wmerr(ifile)=nan;
                
        end
        clear relevant_events sections part probes wm_err a b 
        
    end %end current ifile
    

    for i=1:size(needed,2)
        temp(i)=sum(vect_levels==needed(i));
    end
    whatsmissing=needed(temp==0);
    
    for i=1:size(normal_levels,2)
        if sum(vect_levels==normal_levels(i))>1
            temp = vect_distance(vect_levels==normal_levels(i),1);
            temp2 = vect_duration(vect_levels==normal_levels(i),1);
            if normal_levels(i)==43
                if i==27;j=1;elseif i==28;j=2;else j=3;end
                vect_distance_reg(i)=temp(j);vect_duration_reg(i)=temp2(j);
            elseif temp(1)==0
                vect_distance_reg(i)=temp(2);vect_duration_reg(i)=temp2(2);
            else
                vect_distance_reg(i)=temp(1);vect_duration_reg(i)=temp2(1);
            end
        elseif sum(vect_levels==normal_levels(i))==0
            vect_distance_reg(i)=nan;
            vect_duration_reg(i)=nan;
        else
            vect_distance_reg(i)=vect_distance(vect_levels==normal_levels(i));
            vect_duration_reg(i)=vect_duration(vect_levels==normal_levels(i));
            
        end
    end
    
    for i=1:size(normal_levels,2)
        if sum(vect_levels==normal_levels(i))>1
            temp = map_view_dur(vect_levels==normal_levels(i));
            if normal_levels(i)==43
                if i==27;j=1;elseif i==28;j=2;else j=3;end
                vect_duration_map(i)=temp(j);
            else
            end
        elseif sum(vect_levels==normal_levels(i))==0            
                vect_duration_map(i)=nan;
        else
                vect_duration_map(i)=map_view_dur(vect_levels==normal_levels(i));
        end
    end
    
    if exist('flare_acc','var') 
        for i=1:size(flares,2)
            if sum(vect_levels==flares(i))>1
                temp = flare_acc(vect_levels==flares(i));
                flare_acc_reg(i)=temp(1);
            elseif sum(vect_levels==flares(i))==0
                flare_acc_reg(i)=nan;
            else
                flare_acc_reg(i)=flare_acc(vect_levels==flares(i));
            end   
        end
    else flare_acc_reg=nan;
    end
    
    for i=1:size(radial,2)
        if sum(vect_levels==radial(i))>1 %if done multiple times take 1st instance
            temp = radial_tech(vect_levels==radial(i));temp2 = radial_probeerr(vect_levels==radial(i));temp3 = radial_wmerr(vect_levels==radial(i));
            radial_tech_reg(i)=temp(1);
            radial_acc_reg(i)=temp2(1);
            radial_incorrect_probe_reg(i)=temp3(1);
        elseif sum(vect_levels==radial(i))==0
            radial_tech_reg(i)=nan;
            radial_acc_reg(i)=nan;
            radial_incorrect_probe_reg(i)=nan;
        else
            radial_tech_reg(i)=radial_tech(vect_levels==radial(i));
            radial_acc_reg(i)=radial_probeerr(vect_levels==radial(i));
            radial_incorrect_probe_reg(i)=radial_wmerr(vect_levels==radial(i));
        end
    end
    
    %divide all map levels with average of level 1&2 to normalize
    %performance
    if normalize==1
        summary_dist(s,:)=vect_distance_reg/mean([vect_distance(vect_levels==1),vect_distance(vect_levels==2)]);
        summary_dur(s,:)=vect_duration_reg/mean([vect_duration(vect_levels==1),vect_duration(vect_levels==2)]);
        summary_mapview(s,:)=vect_duration_map/mean([map_view_dur(vect_levels==1),map_view_dur(vect_levels==2)]);
    else
        summary_dist(s,:)=vect_distance_reg;
        summary_dur(s,:)=vect_duration_reg;
        summary_mapview(s,:)=vect_duration_map;
    end
    summary_flare(s,:)=flare_acc_reg;
    summary_radialtech(s,:)=radial_tech_reg;
    summary_radialacc(s,:)=radial_acc_reg;
    summary_radialprobes(s,:)=radial_incorrect_probe_reg;
    if isempty(whatsmissing)==1;summary_whatsmissing{s}=0;else;summary_whatsmissing{s}=whatsmissing;end
    
    
    clearvars -except summary_* listing needed flares normal_levels radial normalize outputfilename
    
end

%% save all the data to a file

save('summary_data.mat','summary_*','normal_levels','flares','needed','radial','listing')

for i=1:size(listing,1);subjlist{i,1}=listing(i).name;end
% S=table(subjlist,summary_dist,summary_dur,summary_mapview,summary_flare,summary_radialtech,summary_radialacc,summary_radialprobes);
% writetable(S,filename);

Tab1 = array2table(cat(2,subjlist,num2cell(summary_dist)),'VariableNames',{'subjID','DISTANCE_L1','L2','L3','L6','L7','L8','L11','L12','L13','L16','L17','L18','L21','L22','L23','L26','L27','L28','L31','L32','L33','L36','L37','L38','L41','L42','L43_1','L43_2','L43_3'});
Tab2 = array2table(cat(2,subjlist,num2cell(summary_dur)),'VariableNames',{'subjID','DURATION_L1','L2','L3','L6','L7','L8','L11','L12','L13','L16','L17','L18','L21','L22','L23','L26','L27','L28','L31','L32','L33','L36','L37','L38','L41','L42','L43_1','L43_2','L43_3'});
Tab3 = array2table(cat(2,subjlist,num2cell(summary_mapview)),'VariableNames',{'subjID','MAPVIEW_L1','L2','L3','L6','L7','L8','L11','L12','L13','L16','L17','L18','L21','L22','L23','L26','L27','L28','L31','L32','L33','L36','L37','L38','L41','L42','L43_1','L43_2','L43_3'});
Tab4 = array2table(cat(2,subjlist,num2cell(summary_flare)),'VariableNames',{'subjID','FLARE_L4','L9','L14','L19','L24','L29','L34','L39','L44','L49','L54','L59','L64','L69','L74'});
Tab5 = array2table(cat(2,subjlist,num2cell(summary_radialtech)),'VariableNames',{'subjID','RADIALTECH_L1','L2','L3','L4','L5'});
Tab6 = array2table(summary_radialacc,'VariableNames',{'RADIALLTM_L1','L2','L3','L4','L5'});
Tab7 = array2table(summary_radialprobes,'VariableNames',{'RADIALWM_L1','L2','L3','L4','L5'});

 sheet = 1;
 writetable(Tab1,outputfilename,'sheet',sheet,'Range','A1')
 sheet = 2;
 writetable(Tab2,outputfilename,'sheet',sheet,'Range','A1')
 sheet = 3;
 writetable(Tab3,outputfilename,'sheet',sheet,'Range','A1')
 sheet = 4;
 writetable(Tab4,outputfilename,'sheet',sheet,'Range','A1')
 sheet = 5;
 writetable(Tab5,outputfilename,'sheet',sheet,'Range','A1') 
 writetable(Tab6,outputfilename,'sheet',sheet,'Range','G1') 
 writetable(Tab7,outputfilename,'sheet',sheet,'Range','L1')
 
%% plot data
clear

load('summary_data.mat')

for i=1:size(normal_levels,2);labelz{i}=num2str(normal_levels(i));end
for i=1:size(flares,2);labelf{i}=num2str(flares(i));end

figure;set(gcf,'color','w');plot(nanmean(summary_dist,1),'k');...
    errorbar(nanmean(summary_dist,1),nanstd(summary_dist,1)/sqrt(size(summary_dist,1)),'k');ylabel('distance (virtual units?)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(nanmean(summary_dur,1),'k');...
    errorbar(nanmean(summary_dur,1),nanstd(summary_dur,1)/sqrt(size(summary_dist,1)),'k');ylabel('duration (sec)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(nanmean(summary_mapview,1),'k');...
    errorbar(nanmean(summary_mapview,1),nanstd(summary_mapview,1)/sqrt(size(summary_dist,1)),'k');ylabel('map view duration (sec)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(nanmean(summary_flare,1),'k');...
    errorbar(nanmean(summary_flare,1),nanstd(summary_flare,1)/sqrt(size(summary_dist,1)),'k');ylabel('accuracy');xlabel(' flare level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelf)

figure;set(gcf,'color','w');
subplot(1,4,1);
plot(nanmean(summary_radialacc,1),'k');...
    errorbar(nanmean(summary_radialacc,1),nanstd(summary_radialacc,1)/sqrt(size(summary_dist,1)),'k');ylabel('LTM error - part 1 arm entered in part 2');xlabel('level');
set(gca,'Xtick',1:5);set(gca,'XTickLabel',{'arctic';'golden';'mystic';'kano';'high'})

subplot(1,4,2);
plot(nanmean(summary_radialprobes,1),'k');...
    errorbar(nanmean(summary_radialprobes,1),nanstd(summary_radialprobes,1)/sqrt(size(summary_dist,1)),'k');ylabel('WM error - re-entry into part 2 arm');xlabel('level');
set(gca,'Xtick',1:5);set(gca,'XTickLabel',{'arctic';'golden';'mystic';'kano';'high'})

subplot(1,4,3:4);
   S1=cat(2,sum(summary_radialtech(:,1)==1),sum(summary_radialtech(:,2)==1),sum(summary_radialtech(:,3)==1),sum(summary_radialtech(:,4)==1),sum(summary_radialtech(:,5)==1));
   S2=cat(2,sum(summary_radialtech(:,1)==2),sum(summary_radialtech(:,2)==2),sum(summary_radialtech(:,3)==2),sum(summary_radialtech(:,4)==2),sum(summary_radialtech(:,5)==2));
   S3=cat(2,sum(summary_radialtech(:,1)==3),sum(summary_radialtech(:,2)==3),sum(summary_radialtech(:,3)==3),sum(summary_radialtech(:,4)==3),sum(summary_radialtech(:,5)==3));
   Sother=cat(2,sum(summary_radialtech(:,1)<=0),sum(summary_radialtech(:,2)<=0),sum(summary_radialtech(:,3)<=0),sum(summary_radialtech(:,4)<=0),sum(summary_radialtech(:,5)<=0));
   bar(cat(1,Sother,S1,S2,S3));
   ylabel('# of participants using technique / level');
% set(gca,'Xtick',0:1:3);
set(gca,'XTickLabel',{'none';'counting';'landmark';'count from 1 landmark'})
legend({'arctic';'golden';'mystic';'kano';'high'});colormap(gray);

%% ignore this for now (it's a correlation b/w SHQ performance and the Navigational Strategies Questionanire - see Patai et al 2019 Cerebral Cortex or Brunec at al 2018 Current Biology)

% nsq=[1,7,5,7,6,7,7,8,9,2,9,3];
% 
% [r p]=corr(nsq,mean(summary_dist,2));
% [r p]=corr(nsq,mean(summary_flare,2));
% [r p]=corr(nsq,mean(summary_radialacc,2));
% [r p]=corr(nsq,mean(summary_radialtech,2));
% [r p]=corr(nsq,summary_radialtech(:,2));