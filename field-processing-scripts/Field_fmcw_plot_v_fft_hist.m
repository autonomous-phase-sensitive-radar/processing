 %% FMCW Plot V FFT Histograms
% 
% adapted from fmcw_plot & related scripts
%
% Intended for a quick look at ApRES data in the field. 
% Only select one file for processing.
% Script separates by burst (attenuation setting) and then plots:
%       - voltage vs. time & corresponding histogram
%       - fft & phase
%
% Averages all chirps in a burst. Plots each attenuation setting in a separate figure. 
%
% For simplicity, only works with RMB5 format
%
% Elizabeth Case, April 2022
%% Settings
maxchirps = 100;
depthset = 1500;
pad = 2;
win = @blackman;

%% Load data
% GUI asks you to choose one file; if desired, can comment out line 24 and
% input file and pathnames in 25 and 26

    [filename, pathname] = uigetfile({'*.dat';'*.DAT'},'Choose radar file to plot');
    %filename = '';
    %pathname = '';
    if isa(filename,'double') % no files chosen
        return
    end
    
    name = filename;
    filename=[pathname,filename];

    burstlist = 1:2; 
    chirplist = 1:maxchirps;

    getBurst = 1;
    BurstNo = 0;
    
    % loop through bursts in file
    while BurstNo<length(burstlist) && getBurst
        
        %sets thisburst to current burst
        BurstNo = BurstNo + 1;
        thisburst = burstlist(BurstNo);

        vdat = Field_load(filename,thisburst); % load data
        
        if vdat.Code == -4 % burst not found in file
            
            disp([num2str(BurstNo-1) ' burst(s) found in file'])
            %return
            getBurst = 0;
        
        elseif vdat.Code == -5
            
            disp(['No chirp starts found in file ' filename ' burst ' int2str(thisburst) ': - Corrupted data?'])
            %getBurst = 0;
        
        else %data is good
        
         % Split burst into various attenuator settings
        
         vdats = Field_burst_split_by_att(vdat);

        %% Plot
        
        
        for AttSetNum = 1:length(vdats) % attenuator setting number

            % Generate labels for each chirp to plot
            shotNamePrefix = [strrep(name,'_','-') ' b:' int2str(thisburst) ' c:'];
            
            %average chirps from burst
            vdat = Field_burst_mean(vdats(AttSetNum));
            vdat.chirpname = [shotNamePrefix ' avg' int2str(real(vdat.chirpAtt)) '+' int2str(imag(vdat.chirpAtt)) 'dB '];
            
            % Figure 1a & b: % plot voltage vs. time series, histogram of the avg. chirp,
            % and note if there is any cutoff
                
                [tax,hax,aax,pax] = open_plot(vdat);
                
                axes(tax), hold on
                ht = plot(vdat.t,vdat.vif); % signal

                axes(hax), hold on
                hh = histogram(vdat.vif,'Orientation','horizontal');
                plot(linspace(1,max(hh.Values())+100,size(vdat.t,2)),repmat(0,size(vdat.t)),'r','HandleVisibility','off'); 
                plot(linspace(1,max(hh.Values())+100,size(vdat.t,2)),repmat(2.5,size(vdat.t)),'r','HandleVisibility','off');
                xlim([0 max(hh.Values())+100])

            % Figure 1c & d: plot amplitude/phase profile
            
                % phase process data
                [rc,~,~,su] = fmcw_range(vdat,pad,depthset,win);

                axes(pax), hold on
                plot(rc,angle(su));
                xlim([0 depthset])

                axes(aax), hold on
                plot(rc,20*log10(abs(su)));
                xlim([0 depthset])

                if any(round(vdat.vif,2)==0) || any(round(vdat.vif,2)==2.5)
                    disp(['!!!!!!! The signal might be clipped in ' vdat.chirpname '!!!!!!!!']); 
                end
                    
        end


    end

    end
    
%% 
function [tax,hax,aax,pax] = open_plot(vdat)
    figure('Position',[680,181,1010,797]);
    t=tiledlayout(4,4);

    tax = nexttile(1,[2,2]);
    set(tax,'tag','tax');
    title('Voltage')
    hold on
    box on
    xlabel('Time (s)')
    ylabel('Voltage')
    ylim([-0.25 2.75])
    plot(vdat.t,repmat(0,size(vdat.t)),'r','HandleVisibility','off'); % ADC saturation level
    plot(vdat.t,repmat(2.5,size(vdat.t)),'r','HandleVisibility','off'); % ADC saturation level
    
    hax = nexttile(3,[2,2]);
    set(hax,'tag','hax');
    title('Histogram of voltage')
    xlabel('Count')
    ylabel('Voltage')
    hold on
    box on
    ylim([-0.25 2.75])
    

    % Amp subplot
    aax = nexttile(9,[1,4]);
    set(aax,'tag','aax')
    title('Amplitude (dB)')
    box on
    xlabel('Range (m)');
    ylabel('amplitude (dB Vrms)')
    
    % Phase subplot
    pax = nexttile(13,[1,4]);
    set(pax,'tag','pax');
    box on
    xlabel('Range (m)');
    ylim([-3.5 3.5])
    set(pax,'YLimMode','auto') % to allow rescale
    ylabel('Phase (rad)')
    title('Phase')

    linkaxes([aax,pax],'x');

    title(t,vdat.chirpname);

end