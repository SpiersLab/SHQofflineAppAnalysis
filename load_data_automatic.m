clear 

%% set some stuff up (CHANGE THIS)

% %set the path to the data and the .m files needed for the script(parse_json.m)
addpath('E:\shq vbm\DATA\shq\')
% % go to the directory with the data
cd('E:\shq vbm\DATA\shq\json');

% %lists all the folders with the json files inside (should be organized per participant, so this will find folders like: S045_XXXX etc))
listing = dir('E:\shq vbm\DATA\shq\json\S*');

% % all the levels you need (i.e. which you ran)
%     %TG
    needed=[1:4,6:9,11:14,16:19,21:24,26:29,31:34,36:39,41:43,43,43,44,49,54,59,64,69,74,100,200,300,400,500];
    flares=[4,9,14,19,24,29,34,39,44,49,54,59,64,69,74];
    radial=[100,200,300,400,500];%the radial levels i've added 00 to the end to differentiate from normal levels
    normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)),[43,43]);

%     %EZP
%     needed=[1:4,6:9,11:14,16:19,21:24,26:29,31:34,36:39,41:43,43,43,44,49,54,59,64,69,74,100,200,300,400,500];
%     flares=[4,9,14,19,24,29,34,39,44,49,54,59,64,69,74];
%     radial=[100,200,300,400,500];
%     normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)),[43,43]);

%     %GZ
%     needed=[1,2,4,6,11,16,34,44,46,51,54,400];
%     flares=[4,34,44,54];
%     radial=[400];
%     normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)));
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
        elseif isfield(data_participant.meta, 'flare_accuracy') ==1 
        flare_acc(ifile)=data_participant.meta.flare_accuracy;
        elseif isfield(data_participant.meta, 'radial_technique') ==1 
        radial_tech(ifile)=data_participant.meta.radial_technique;
        else
            %
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
                    errors(i)=data_participant.events{relevant_events(i)}.error;%remember that error=1 is an error, so 0s and 1s are reversed
                end

                j=1;
                for i=1:size(sections,2)
                    if i==size(sections,2) && errors(i)==0 
                        r_acc(j)=1;
                    elseif i==size(sections,2) && errors(i)==1 
                        r_acc(j)=0;    
                    elseif sections(i)==sections(i+1) && errors(i)==0 && errors(i+1)==1
                        r_acc(j)=1;j=j+1;
                    elseif sections(i)==sections(i+1) && errors(i)==1 && errors(i+1)==1
                        r_acc(j)=0;j=j+1;
                    elseif i>1 && sections(i)~=sections(i+1) && sections(i)~=sections(i-1)&& errors(i)==0   
                        r_acc(j)=1;j=j+1;
                    elseif i>1 && sections(i)~=sections(i+1) && sections(i)~=sections(i-1)&& errors(i)==1   
                        r_acc(j)=0;j=j+1;
                    elseif i==1 && sections(i)~=sections(i+1) && errors(i)==0
                        r_acc(j)=1;j=j+1;
                    elseif i==1 && sections(i)~=sections(i+1) && errors(i)==1
                        r_acc(j)=0;j=j+1;
                    elseif sections(i)~=sections(i+1) 
                       continue 
                    end
                end

                radial_acc(ifile)=mean(r_acc);
                radial_incorrect_probe(ifile)=sum(r_acc==0);
              
        else
                radial_acc(ifile)=nan;
                radial_incorrect_probe(ifile)=nan;
                
        end
        clear relevant_events sections errors r_acc
        
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
        else
                vect_duration_map(i)=map_view_dur(vect_levels==normal_levels(i));
        end
    end
    
    
    for i=1:size(flares,2)
        if sum(vect_levels==flares(i))>1
            temp = flare_acc(vect_levels==flares(i));
            flare_acc_reg(i)=temp(1);
        else
            flare_acc_reg(i)=flare_acc(vect_levels==flares(i));
        end
    end
    
    for i=1:size(radial,2)
        if sum(vect_levels==radial(i))>1
            temp = radial_tech(vect_levels==radial(i));temp2 = radial_acc(vect_levels==radial(i));temp3 = radial_incorrect_probe(vect_levels==radial(i));
            radial_tech_reg(i)=temp(1);
            radial_acc_reg(i)=temp2(1);
            radial_incorrect_probe(i)=temp3(1);
        elseif sum(vect_levels==radial(i))==0;
            radial_tech_reg(i)=0;
            radial_acc_reg(i)=0;
            radial_incorrect_probe(i)=0;
        else
            radial_tech_reg(i)=radial_tech(vect_levels==radial(i));
            radial_acc_reg(i)=radial_acc(vect_levels==radial(i));
            radial_incorrect_probe_reg(i)=radial_incorrect_probe(vect_levels==radial(i));
        end
    end
    
    
    
    summary_dist(s,:)=vect_distance_reg;
    summary_dur(s,:)=vect_duration_reg;
    summary_mapview(s,:)=vect_duration_map;
    summary_flare(s,:)=flare_acc_reg;
    summary_radialtech(s,:)=radial_tech_reg;
    summary_radialacc(s,:)=radial_acc_reg;
    summary_radialprobes(s,:)=radial_incorrect_probe_reg;
    if isempty(whatsmissing)==1;summary_whatsmissing(s,:)=0;else;summary_whatsmissing(s,:)=whatsmissing;end;
    
    
    clearvars -except summary_* listing needed flares normal_levels radial
    
end

%% save all the data to a file

save('summary_data.mat','summary_*','normal_levels','flares','needed','radial')

%% plot data
clear

load('summary_data.mat')

%     needed=[1:4,6:9,11:14,16:19,21:24,26:29,31:34,36:39,41:43,43,43,44,49,54,59,64,69,74,100,200,300,400,500];
%     flares=[4,9,14,19,24,29,34,39,44,49,54,59,64,69,74];
%     radial=[100,200,300,400,500];
%     normal_levels=cat(2,setdiff(needed,cat(2,flares,radial)),[43,43]);
    
    
    for i=1:size(normal_levels,2);labelz{i}=num2str(normal_levels(i));end;
    for i=1:size(flares,2);labelf{i}=num2str(flares(i));end;
    
%     summary_dist(1:2,:)=[];summary_dur(1:2,:)=[];summary_mapview(1:2,:)=[];summary_flare(1:2,:)=[];summary_radialacc(1:2,:)=[];summary_radialprobes(1:2,:)=[];summary_radialtech(1:2,:)=[];
    
figure;set(gcf,'color','w');plot(mean(summary_dist,1),'k');...
    errorbar(mean(summary_dist,1),std(summary_dist,1)/sqrt(size(summary_dist,1)),'k');ylabel('distance (virtual units?)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(mean(summary_dur,1),'k');...
    errorbar(mean(summary_dur,1),std(summary_dur,1)/sqrt(size(summary_dist,1)),'k');ylabel('duration (sec)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(mean(summary_mapview,1),'k');...
    errorbar(mean(summary_mapview,1),std(summary_mapview,1)/sqrt(size(summary_dist,1)),'k');ylabel('map view duration (sec)');xlabel('level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelz)

figure;set(gcf,'color','w');plot(mean(summary_flare,1),'k');...
    errorbar(mean(summary_flare,1),std(summary_flare,1)/sqrt(size(summary_dist,1)),'k');ylabel('accuracy');xlabel(' flare level');
set(gca,'Xtick',1:size(normal_levels,2));set(gca,'XTickLabel',labelf)

figure;set(gcf,'color','w');
subplot(1,3,1);
plot(mean(summary_radialacc,1),'k');...
    errorbar(mean(summary_radialacc,1),std(summary_radialacc,1)/sqrt(size(summary_dist,1)),'k');ylabel('accuracy');xlabel('level');
set(gca,'Xtick',1:5);set(gca,'XTickLabel',{'arctic';'golden';'mystic';'kano';'high'})

subplot(1,3,2);
plot(mean(summary_radialprobes,1),'k');...
    errorbar(mean(summary_radialprobes,1),std(summary_radialprobes,1)/sqrt(size(summary_dist,1)),'k');ylabel('probes entered');xlabel('level');
set(gca,'Xtick',1:5);set(gca,'XTickLabel',{'arctic';'golden';'mystic';'kano';'high'})

subplot(1,3,3);
   hist(summary_radialtech,3);ylabel('# of participants using technique / level');
set(gca,'Xtick',1:1:3);set(gca,'XTickLabel',{'counting';'landmark';'count from 1 landmark'})
legend({'arctic';'golden';'mystic';'kano';'high'});colormap(gray);

%% ignore this for now (it's a correlation b/w SHQ performance and the Navigational Strategies Questionanire)

% nsq=[1,7,5,7,6,7,7,8,9,2,9,3];
% 
% [r p]=corr(nsq,mean(summary_dist,2));
% [r p]=corr(nsq,mean(summary_flare,2));
% [r p]=corr(nsq,mean(summary_radialacc,2));
% [r p]=corr(nsq,mean(summary_radialtech,2));
% [r p]=corr(nsq,summary_radialtech(:,2));