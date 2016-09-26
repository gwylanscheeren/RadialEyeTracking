%This function starts a GUI which can be used for post-processing of eye
%tracking data
%
%Written by Gwylan Scheeren
%Modified by Guido Meijer

function runPupilPostProcessingStarburst
    
    % clear workspace, figures and command window
    clear all
    close all
    clc
    
    % initialise values and switches
    global intCurrentFrame sMovie vecTimeStamps gui oldpointer ROImask cfg sEyeTracking sTempEyeTracking FilePath cropppedVideoPath SesPath cellSignalTypes Reprocess FileSourcePath vecArea vecPosX vecPosY h2 h3 TimeFrameSelection Areacolor Areacolor1 Areacolor2 Areatextcolor1 Areatextcolor2 Eyecolor Eyecolor1 Eyecolor2 Eyetextcolor1 Eyetextcolor2 g strProp vecA vecB vecAlpha vecZ limit
    
    % set paths
    cropppedVideoPath = 'C:\Users\Stephan\Desktop\Stage\TestCroppedVideos'; %set initial file path
    SesPath = 'C:\Users\Stephan\Desktop\Stage\TestSessionFiles'; %set initial file path

    % load data
    LoadEyetracking;
        
    % initialise values and switches
    cellSignalTypes = {'Pupil Area','X-Position','Y-Position'};
    Areacolor = [.6 .7 .9]; Areacolor1 = [.7 .8 1]; Areacolor2 = [.3 .4 .6]; Areatextcolor1 = 'k'; Areatextcolor2 = 'w';
    Eyecolor = [.2 .8 .5]; Eyecolor1 = [.3 .9 .6]; Eyecolor2 = [0 .6 .3]; Eyetextcolor1 = 'k'; Eyetextcolor2 = 'w';
    strProp = 'area';
    intCurrentFrame = 2;
    intFrames = size(vecArea,2);
    
    %% Create a frame figure and axes
    
    f = figure('units','normalized','outerposition',[0 0 1 1]);
    s=subplot('Position',[.05 .43 .425 .52]);
    g=subplot('Position',[.05 .05 .9 .3]);
    gui = uipanel('Title','Functions','FontSize',12,'FontWeight','bold','BackgroundColor','white','Position',[.5250 .43 .425 .52]);
    axframes = axes('Position',[.05 .35 .9 .08],'Visible','off');
    %RGBcolormap=colorGray(64,0);

    subplot(s);
    h = imshow(mat2gray(sMovie.matMovie(:,:,intCurrentFrame+intStart-1))); %CHANGE 1: imagesc -> imshow(mat2gray(...
    %colormap(RGBcolormap); 
    axis off;
    hold on
    handle = plotellipse(vecZ(intCurrentFrame+intStart-1,:),vecA(intCurrentFrame+intStart-1),vecB(intCurrentFrame+intStart-1),vecAlpha(intCurrentFrame+intStart-1),'r');
    set(handle,'LineWidth',3)
    plot(vecPosX(intCurrentFrame+intStart-1),vecPosY(intCurrentFrame+intStart-1),'gx')
    htitle = title(sprintf('frame %.0f Recording %s%s',intCurrentFrame,cfg.strSes,cfg.strRec));

    subplot(g);
    t = plot(vecArea);
    xlim([-200 length(vecArea)+200]);
    glegend = legend('Estimated pupil area','Location','North');
    gframeline = line([intCurrentFrame intCurrentFrame],get(gca,'YLim'),'Color','g','LineWidth',1,'LineStyle','--');
    axframes;
    glinetext = text(intCurrentFrame,0.55,sprintf('| <- selected frame: %d',intCurrentFrame));

    
    
    %% Create all sliders and buttons
    
    %initiate sliderstep values
    smallstep = [1/intFrames,10/intFrames];
    bigstep = [50/intFrames,500/intFrames];

    % Create slider & Add a text uicontrol to label the slider
    uicontrol('Parent',gui,'Style','text','Units','normalized','BackgroundColor',[.9 .9 1],'Position', [.02 .945 .4 .04],'FontSize',11,'String','-1                         frame +/- 10                         +1');
    sldframe = uicontrol('Interruptible','off','BusyAction','cancel','Parent',gui,'Style', 'slider','Tag','slider1','Min',1,'Max',intFrames,'SliderStep',smallstep,'Value',intCurrentFrame,'BackgroundColor',[.9 .9 1],'Units','normalized','Position', [.02 .878 .4 .06],'Callback', @plotframe);
    sldframeTooltip = sprintf('Use the arrow buttons or arrow keys to advance or return one frame or click trough slider for steps of 10 frames at once\nBefore being able to use the arrow keys, one of the buttons need to be clicked');
    set(sldframe,'TooltipString',sldframeTooltip);
    uicontrol('Parent',gui,'Style','text','BackgroundColor',[.8 1 .8],'Units','normalized','Position', [.02 .808 .4 .04],'FontSize',11,'String','-50                    frames +/- 500                   +50');
    sldframe2 = uicontrol('Interruptible','off','BusyAction','cancel','Parent',gui,'Style', 'slider','Min',1,'Max',intFrames,'SliderStep',bigstep,'Value',intCurrentFrame,'BackgroundColor',[.8 1 .8],'Units','normalized','Position', [.02 .741 .4 .06],'Callback', @plotframe);
    sldframe2Tooltip = sprintf('Use the arrow buttons or arrow keys to advance or return 50 frames at once or click trough slider for steps of 100\nBefore being able to use the arrow keys, one of the buttons need to be clicked');
    set(sldframe2,'TooltipString',sldframe2Tooltip);

    % Create push button for frame selection
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Select single frame','FontSize',11,'Value',intCurrentFrame,'Units','normalized','Position', [.24 .56 .18 .05],'Callback', @SelectSingleFrameFrameplot);

    % create pop-up menu with all different selectable signal types
    uicontrol('Parent',gui,'Style', 'text','BackgroundColor',[.5 .7 1],'FontSize',11,'String', 'Signal selection','Units','normalized','Position', [.5 .07 .16 .04]);
    signalpopup1 = uicontrol('Parent',gui,'Style', 'popup','ForegroundColor',[0 0 1],'Tag','1','String', cellSignalTypes,'FontSize',10,'Units','normalized','Position', [.5 .02 .16 .05],'Callback', @signalselection);
    set(signalpopup1,'Value',1);

%     % create push button
%     btnROIswitch = uicontrol('Parent',gui,'Style', 'togglebutton','BackgroundColor',[0 .5 .7],'String','ROImask ON','ForegroundColor','w','FontSize',9,'Units','normalized','Position', [.02 .64 .16 .06],'Callback', @switchROImask);
%     if ~exist('m'); set(btnROIswitch,'Visible','on'); end
%     btnEyeswitch = uicontrol('Parent',gui,'Style', 'togglebutton','BackgroundColor',[0 .5 .7],'String','Eye-mask ON','ForegroundColor','w','FontSize',9,'Units','normalized','Position', [.02 .58 .16 .06],'Callback', @switchEyemask);
%     if ~exist('r'); set(btnEyeswitch,'Visible','on'); end
%     uicontrol('Parent',gui,'Style', 'togglebutton','BackgroundColor',[.7 .7 .3],'String','Ses Events ON','ForegroundColor','w','FontSize',9,'Units','normalized','Position', [.24 .64 .16 .06],'Callback', @switchSesEvents);
%     

    % push buttons for filtering, removal of 0s and setting to NaN
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Remove 0''s','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.55 .92 .3 .06],'Callback', @doRemoveZeros);
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Filter','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.55 .84 .3 .06],'Callback', @Filter);
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Set to NaN','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.55 .76 .3 .06],'Callback', @doSetNaN);
%     uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Set 0''s to NaN','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.55 .68 .3 .06],'Callback', @doSetZeroToNaN);
        
    % create push buttons for redraw area, redo eye tracking and redo
    % pre-processing
    
    
    uicontrol('Parent',gui,'Style', 'pushbutton','Tag','now', 'String', 'Re-perform EyeTracking','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.55 .68 .3 .06],'Callback', @Process);
    
    
    
    
        %TrackSensetooltip = sprintf('Adjust the acceptable range of pupil luminance for the area detection algorithm\n\nHigher values result in more points for more acurate selection (takes longer to compute)');
        %set(TrackSenseedit,'TooltipString',TrackSensetooltip);
    
    
    %create Edits for Re perform processing  
    
    %Number of rays
    uicontrol('Parent',gui,'Style', 'text','Tag','now', 'String', 'Rays','FontSize',10,'Units','normalized','Position', [.566 .62 .12 .04]);
    raysStringEdit = uicontrol('Parent',gui,'Style', 'edit','ForegroundColor',[0 0 1],'String', 16,'FontSize',10,'Units','normalized','Position', [.5885 .55 .08 .06]);
    
    %standard deviation for outlier detection
    uicontrol('Parent',gui,'Style', 'text','Tag','now', 'String', 'std.dev.','FontSize',10,'Units','normalized','Position', [.711 .62 .12 .04]);
    oStringEdit = uicontrol('Parent',gui,'Style', 'edit','ForegroundColor',[0 0 1],'String', 2,'FontSize',10,'Units','normalized','Position', [.7335 .55 .08 .06]);
    
    
    uicontrol('Parent',gui,'Style', 'text','Tag','now', 'String', 'Radii','FontSize',10,'Units','normalized','Position', [.64 .5 .12 .04]);
    
    %Radii steps 
    radiiStartStringEdit = uicontrol('Parent',gui,'Style', 'edit','ForegroundColor',[0 0 1],'String', 5,'FontSize',10,'Units','normalized','Position', [.635 .435 .03 .06]);
    radiiStepStringEdit = uicontrol('Parent',gui,'Style', 'edit','ForegroundColor',[0 0 1],'String', 2,'FontSize',10,'Units','normalized','Position', [.685 .435 .03 .06]);
    radiiStopStringEdit = uicontrol('Parent',gui,'Style', 'edit','ForegroundColor',[0 0 1],'String', 21,'FontSize',10,'Units','normalized','Position', [.735 .435 .03 .06]);
    
    
    %Create button for remove faulty (negative and high area calculations 
    limit = uicontrol('Parent',gui,'Style','edit','ForegroundColor',[0 0 1],'String',3000,'FontSize',10,'Units','normalized','Position', [.67 .29 .06 .06]);
    uicontrol('Parent',gui,'Style', 'pushbutton','Tag','now', 'String', 'Remove Faulty Area Calculations','FontSize',10,'Units','normalized','Position', [.55 .35 .3 .06],'Callback', @removeOutliers);
    
    
    
    
    % save and close button
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Undo','BackgroundColor',[.3 .3 .3],'Units','normalized','Position', [.7 .203 .2 .06],'Callback', {@Undo,'load'});
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Load','BackgroundColor',[.3 .3 .9],'Units','normalized','Position', [.7 .142 .2 .06],'Callback', @LoadEyetracking);
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Save','BackgroundColor',[.1 .7 .1],'Units','normalized','Position', [.7 .081 .2 .06],'Callback', @SaveEyetracking);
    uicontrol('Parent',gui,'Style', 'pushbutton', 'String', 'Close','BackgroundColor',[.75 .1 .1],'Units','normalized','Position', [.7 .02 .2 .06],'Callback', 'close');

    % buttons for ROI (re)selection
    uipanel('Parent',gui,'Title','Edit EyeTrack ROI','FontSize',10,'FontWeight','bold','BackgroundColor','white','Position',[.01 .26 .42 .25]);
    uicontrol('Parent',gui,'Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'draw','FontSize',10,'Value',true,'Selected', 'off','Units','normalized','Position', [.02 .38 .075 .05],'Callback', {@ROI,'new'});
    btnEditROI = uicontrol('Parent',gui,'Visible','off','Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'Edit','FontSize',10,'Value',true,'Units','normalized','Position', [.097 .38 .15 .05],'Callback', {@ROI,'edit'});
   
    % push buttons for setting start end stop frame individually or both in one go    
    uicontrol('Parent',gui,'Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'Start Frame','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.02 .14 .17 .05],'Callback', {@setFrame,'start'});
    uicontrol('Parent',gui,'Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'End Frame','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.25 .14 .14 .05],'Callback', {@setFrame,'end'});
    uicontrol('Parent',gui,'Style','pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'Time-Frame Selection','FontSize',10,'Value',intCurrentFrame,'Units','normalized','Position', [.02 .08 .4 .05],'Callback', @SelectFramePupilDetect);
    uicontrol('Parent',gui,'Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'First Frame','FontSize',10,'Value',1,'Units','normalized','Position', [.02 .02 .17 .05],'Callback', {@setFrame,'start'});
    uicontrol('Parent',gui,'Style', 'pushbutton','BackgroundColor',Eyecolor,'ForegroundColor',Eyetextcolor1, 'String', 'Last Frame','FontSize',10,'Value',size(vecArea,2),'Units','normalized','Position', [.25 .02 .17 .05],'Callback', {@setFrame,'end'});
    btnEyeTimeselectionswitch = uicontrol('Parent',gui,'Visible','off','Style','togglebutton','String','Time selection','FontSize',9,'Units','normalized','Position', [.02 .20 .25 .05],'Callback', @switchEyeTimeselection);
    
    % buttons for switching and deleting ROI selection
    btnROIselectionswitch = uicontrol('Parent',gui,'Visible','off','Style', 'togglebutton', 'String', 'ROI selection','FontSize',9,'Units','normalized','Position', [.02 .32 .19 .05],'Callback', @switchROIselection);
    btndeleteROIselection = uicontrol('Parent',gui,'Visible','off','Style', 'pushbutton', 'String', 'X','FontSize',9,'Value',intCurrentFrame,'Units','normalized','Position', [.216 .32 .03 .05],'Callback', @deleteROIselection);    
    
    %% List with nested functions
    
    set(f,'Visible','on');
    
    % This code uses dot notation to set properties.
    % Dot notation runs in R2014b and later.
    % For R2014a and earlier: set(f,'Visible','on');


    function plotframe(hObject,~)
        if isstruct(hObject)
            frame = round(hObject.Value);
        else
            frame = round(get(hObject,'Value'));
        end
        
        lastframe = size(vecTimeStamps,2);
        if frame+intStart >= lastframe; warndlg('Last frame of cropped movie'); return; end

        set(sldframe,'Value',frame); set(sldframe2,'Value',frame);
        
        if exist('gframeline')
            figure(f);
            subplot(g);
            set(gframeline,'XData',[frame frame]);
            [pos] = get(glinetext,'Position');
            set(glinetext,'Position',[frame pos(2) pos(3)],'String',sprintf('| <- selected frame: %d',frame));
            
            subplot(s);
            h = imshow(mat2gray(sMovie.matMovie(:,:,frame+intStart-1)));
            hold on 
            
            handle = plotellipse(vecZ(frame,:),vecA(frame),vecB(frame),vecAlpha(frame),'r');
            set(handle,'LineWidth',3)
            plot(vecPosX(frame),vecPosY(frame),'gx')
            htitle = title(sprintf('frame %.0f Recording %s%s',frame,cfg.strSes,cfg.strRec));    
                
            
            hold off 
            %set(h,'CData',sMovie.matMovie(:,:,frame+intStart-1));
            %set(htitle,'String',sprintf('frame %.0f Recording %s%s',frame,cfg.strSes,cfg.strRec));
        end
    end

    function signalselection(hObject,~)
        val = get(hObject,'Value');
        tag = get(hObject,'Tag');
        signalselection = get(hObject,'String');
        currentsignal{str2double(tag)} = signalselection{val};
        signal = currentsignal{str2double(tag)};
        
        figure(f);
        subplot(g);
        switch signal
            case 'Pupil Area'
                vecSignal = vecArea;
                legendString = 'estimated pupil area';
                strProp = 'area';
                ylim([min(vecArea)-100 max(vecArea)+100]);
            case 'X-Position'
                vecSignal = vecPosX;
                legendString = 'X-Position';
                ylim([min(vecPosX)-10 max(vecPosX)+10]);
                strProp = 'xpos';
            case 'Y-Position'
                vecSignal = vecPosY;
                legendString = 'Y-Position';
                ylim([min(vecPosY)-10 max(vecPosY)+10]);
                strProp = 'ypos';
        end
        set(t,'YData',vecSignal);
        set(glegend,'String',legendString);
        xlim([-200 length(vecSignal)+200]);
         
    end



    function switchROIselection(~,~)
        status = get(h2,'Visible');
        switch status
            case 'on'
                set(h2,'Visible','off');
                set(btnROIselectionswitch,'BackgroundColor',Eyecolor1,'String','ROI selection OFF','ForegroundColor',Eyetextcolor1);
                set(btnEditROI,'Visible','off');
            case 'off'
                set(h2,'Visible','on');
                set(btnROIselectionswitch,'BackgroundColor',Eyecolor2,'String','ROI selection ON','ForegroundColor',Eyetextcolor2);
                set(btnEditROI,'Visible','on');
        end
        frame.Value = get(sldframe2,'Value');
        plotframe(frame);
    end


    function deleteROIselection(~,~)
        Reprocess.newROImask = [];
        Reprocess.XYpolyROI = []; 
        Reprocess.vecRectROI = [];
        delete(h2);
        set(btndeleteROIselection,'Visible','off');
        set(btnROIselectionswitch,'Visible','off');
        set(btnEditROI,'Visible','off');
    end

    function switchEyeTimeselection(~,~)
        if ~isempty(TimeFrameSelection)
            status = get(TimeFrameSelection.hX3,'Visible');
            switch status
                case 'on'
                    set(TimeFrameSelection.hX1,'Visible','off');
                    set(TimeFrameSelection.hX2,'Visible','off');
                    set(TimeFrameSelection.hX3,'Visible','off');
                    set(TimeFrameSelection.fT2,'Visible','off');
                    set(TimeFrameSelection.fT3,'Visible','off');
                    set(btnEyeTimeselectionswitch,'BackgroundColor',Eyecolor1,'String','Time-frame selection OFF','ForegroundColor',Eyetextcolor1);
                case 'off'
                    set(TimeFrameSelection.hX1,'Visible','on');
                    set(TimeFrameSelection.hX2,'Visible','on');
                    set(TimeFrameSelection.hX3,'Visible','on');
                    set(TimeFrameSelection.fT2,'Visible','on');
                    set(TimeFrameSelection.fT3,'Visible','on');
                    set(btnEyeTimeselectionswitch,'BackgroundColor',Eyecolor2,'String','Time-frame selection ON','ForegroundColor',Eyetextcolor2);
            end
        end
    end

    function ROI(~,~,mode)
        val = get(sldframe,'Value');
        figure(f);
        subplot(s);
        set(htitle,'String',sprintf('ROI selection for session %s%s (double-click on selection to continue)',cfg.strSes,cfg.strRec));
        if exist('h2','var'); delete(h2); end
        %get poly-point selection region
        switch mode
            case 'new'
                h2 = impoly;
            case 'edit'
                if isempty(Reprocess.XYpolyROI)
                    h2 = impoly;
                else
                    h2 = impoly(gca,Reprocess.XYpolyROI);
                end
        end
        hold on
        
        %create mask and rectangle from selection
        Reprocess.newROImask = createMask(h2,h);
        Reprocess.XYpolyROI = wait(h2);
        Reprocess.vecRectROI = [min(Reprocess.XYpolyROI(:,1)) min(Reprocess.XYpolyROI(:,2)) (max(Reprocess.XYpolyROI(:,1)) - min(Reprocess.XYpolyROI(:,1))) (max(Reprocess.XYpolyROI(:,2)) - min(Reprocess.XYpolyROI(:,2)))];
        hold off
        set(btnROIselectionswitch,'Visible','on','Selected','on','BackgroundColor',Eyecolor2,'String','ROI selection ON','ForegroundColor',Areatextcolor2);
        set(btndeleteROIselection,'Visible','on','BackgroundColor',[.9 .2 .2],'String','X','ForegroundColor','w');
        set(btnEditROI,'Visible','on');
        set(htitle,'String',sprintf('frame %.0f Recording %s%s',val,cfg.strSes,cfg.strRec));
        drawnow;
    end

    function SelectSingleFrameFrameplot(~,~)
        xy = ginput(1);
        val = round(xy(1));
        frame.Value = val;
        plotframe(frame);
    end

    function SelectFramePupilDetect(~,~)
        val = get(sldframe,'Value');        
        thisParent = g; ParentAxes = axframes;
        thisylim = get(thisParent,'YLim');
        
        % remove previous patch
        if isfield(TimeFrameSelection,'hX1'); delete(TimeFrameSelection.hX1); end
        if isfield(TimeFrameSelection,'hX2'); delete(TimeFrameSelection.hX2); delete(TimeFrameSelection.fT2); end
        if isfield(TimeFrameSelection,'hX3'); delete(TimeFrameSelection.hX3); delete(TimeFrameSelection.fT3); end

        %ask for FrameStart and plot boundary
        [FrameStart,~,intButton] = ginput(1);
        FrameStart = round(FrameStart);

        TimeFrameSelection.hX2 = line([FrameStart FrameStart],thisylim,'Color',Eyecolor,'LineWidth',1,'LineStyle','--','Parent',thisParent);
        TimeFrameSelection.fT2 = text(FrameStart,0.16,sprintf('| %d',round(FrameStart)),'Parent',ParentAxes,'Color',Eyecolor2);

        %ask for FrameStart and plot boundary
        [FrameStop,~,intButton] = ginput(1);
        FrameStop = round(FrameStop);

        TimeFrameSelection.hX3 = line([FrameStop FrameStop],thisylim,'Color',Eyecolor,'LineWidth',1,'LineStyle','--','Parent',thisParent);
        TimeFrameSelection.fT3 = text(FrameStop,0.36,sprintf('| %d',round(FrameStop)),'Parent',ParentAxes,'Color',Eyecolor2);
        %plot frame selection
        %             TimeFrameSelection.hX1 = line([FrameStart FrameStop],[Ystop Ystop],'Color',Eyecolor,'LineWidth',1,'LineStyle','--','Parent',thisParent);
        if isfield(TimeFrameSelection,'hX3')
            vert = [FrameStart 0;FrameStop 0;FrameStop thisylim(2);FrameStart thisylim(2)];
            fvc = [Eyecolor;Eyecolor2;Eyecolor;Eyecolor1];
            TimeFrameSelection.hX1 = patch('Faces',[1 2 3 4],'Vertices',vert,'FaceVertexCData',fvc,'FaceColor','interp','EdgeColor',Eyecolor,'FaceAlpha',0.3,'Parent',thisParent);
        end

        Reprocess.TimeFrame = [FrameStart FrameStop];
            
        set(btnEyeTimeselectionswitch,'Visible','on','BackgroundColor',Eyecolor1,'String','Time-frame selection ON','ForegroundColor',Eyetextcolor1);
        %set(htitle,'String',sprintf('frame %.0f Recording %s%s',val,cfg.strSes,cfg.strRec));
    end

    function setFrame(hObject,~,mode)
        if strcmp(get(hObject,'String'),'Start Frame') || strcmp(get(hObject,'String'),'End Frame')
            thisFrame = get(sldframe,'Value');
        elseif strcmp(get(hObject,'String'),'Last Frame')
            thisFrame = size(vecArea,2);
        else
            thisFrame = 1;
        end
        thisParent = g; ParentAxes = axframes;
        thisylim = get(thisParent,'YLim');

        if isfield(TimeFrameSelection,'hX1'); delete(TimeFrameSelection.hX1); end
        switch mode
            case 'start'
                if isfield(TimeFrameSelection,'hX2'); delete(TimeFrameSelection.hX2); delete(TimeFrameSelection.fT2); end
                TimeFrameSelection.hX2 = line([thisFrame thisFrame],get(thisParent,'YLim'),'Color',Eyecolor,'LineWidth',1,'LineStyle','--','Parent',thisParent);
                TimeFrameSelection.fT2 = text(thisFrame,0.16,sprintf('| %d',round(thisFrame)),'Parent',ParentAxes,'Color',Eyecolor2);
                Reprocess.TimeFrame(1) = thisFrame;
            case 'end'
                if isfield(TimeFrameSelection,'hX3'); delete(TimeFrameSelection.hX3); delete(TimeFrameSelection.fT3); end
                TimeFrameSelection.hX3 = line([thisFrame thisFrame],thisylim,'Color',Eyecolor,'LineWidth',1,'LineStyle','--','Parent',thisParent);
                TimeFrameSelection.fT3 = text(thisFrame,0.36,sprintf('| %d',round(thisFrame)),'Parent',ParentAxes,'Color',Eyecolor2);
                Reprocess.TimeFrame(2) = thisFrame;
        end
        
        %plot frame selection
        if isfield(TimeFrameSelection,'hX2') && isfield(TimeFrameSelection,'hX3')
            vert = [Reprocess.TimeFrame(1) 0;Reprocess.TimeFrame(2) 0;Reprocess.TimeFrame(2) thisylim(2);Reprocess.TimeFrame(1) thisylim(2)];
            fvc = [Eyecolor;Eyecolor2;Eyecolor;Eyecolor1];
            TimeFrameSelection.hX1 = patch('Faces',[1 2 3 4],'Vertices',vert,'FaceVertexCData',fvc,'FaceColor','interp','EdgeColor',Eyecolor,'FaceAlpha',0.3,'Parent',thisParent);
            set(btnEyeTimeselectionswitch,'Visible','on','BackgroundColor',Eyecolor2,'String','Time-frame selection ON','ForegroundColor',Eyetextcolor2);
        end
    end

    function doRemoveZeros(~,~)
        %Create undo option
        Undo([],[],'save');
        
        %Get time-frame selection
        if isfield(TimeFrameSelection,'hX3') && strcmp(get(TimeFrameSelection.hX3,'Visible'),'on')
            X1 = get(TimeFrameSelection.hX2,'XData');
            X2 = get(TimeFrameSelection.hX3,'XData');
            vecX = X1(1):X2(1);
        else
            vecX = 1:size(vecArea,2);
        end       
        
        %Find and interpolate 0's and NaN's
        indZeros = find(vecArea(vecX) == 0);
        indZeros(indZeros < 3 | indZeros > length(vecArea)-2) = [];
        for z = indZeros
            vecArea(z) = mean(vecArea(z-2:z+2));
            vecPosX(z) = nanmean(vecPosX(z-2:z+2));
            vecPosY(z) = nanmean(vecPosY(z-2:z+2));
        end
        updateUI; %Update plot window
    end

    function Filter(~,~)
        Undo([],[],'save'); %Create undo option
        [B,A] = butter(1,0.1,'low'); %Create 1st order low-pass Buttersworth filter
        
        %Filter on time selection or entire trace
        if isfield(TimeFrameSelection,'hX3') && strcmp(get(TimeFrameSelection.hX3,'Visible'),'on')
            X1 = get(TimeFrameSelection.hX2,'XData');
            X2 = get(TimeFrameSelection.hX3,'XData');
            vecArea(X1(1):X2(1)) = filtfilt(B,A,vecArea(X1(1):X2(1)));
            vecPosX(X1(1):X2(1)) = filtfilt(B,A,vecPosX(X1(1):X2(1)));
            vecPosY(X1(1):X2(1)) = filtfilt(B,A,vecPosY(X1(1):X2(1)));
        else
            vecArea(~isnan(vecArea)) = filtfilt(B,A,vecArea(~isnan(vecArea)));
            vecPosX(~isnan(vecPosX)) = filtfilt(B,A,vecPosX(~isnan(vecPosX)));
            vecPosY(~isnan(vecPosY)) = filtfilt(B,A,vecPosY(~isnan(vecPosY)));
        end 
        updateUI; %Update plot window
    end

    function doSetNaN(~,~)
        %Create undo option
        Undo([],[],'save');
        
        %Get time-frame selection
        if isfield(TimeFrameSelection,'hX3') && strcmp(get(TimeFrameSelection.hX3,'Visible'),'on')
            X1 = get(TimeFrameSelection.hX2,'XData');
            X2 = get(TimeFrameSelection.hX3,'XData');
            vecX = X1(1):X2(1);

            %Set selected time frame to NaN's
            vecArea(vecX) = NaN;
            vecPosX(vecX) = NaN;
            vecPosY(vecX) = NaN;
            updateUI; %Update plot window
        else
            warning('Cannot set entire recording to NaN, make a time selection first');
        end 
                
    end

    function doSetZeroToNaN(~,~)
        Undo([],[],'save'); %Create undo option
        vecX = vecArea < 0.1;
        vecArea(vecX) = NaN;
        vecPosX(vecX) = NaN;
        vecPosY(vecX) = NaN;
        updateUI; %Update plot window
    end

    function Process(~,~)
        %Create undo point
        Undo([],[],'save'); 
        
        %Set up Qcfg structure
        Qcfg = cfg;
        Qcfg.sOldEyeTracking = sEyeTracking;
        Qcfg.FileSavePath = cfg.FileSavePath;
        Qcfg.CroppedVideo = [Qcfg.FileSavePath sprintf('%s_%s%s','croppedvideo',Qcfg.strSes,Qcfg.strRec) '.mat'];
        Qcfg.PrePro = false;
        Qcfg.Eyetrack.CropFrame = sEyeTracking.Frame;
        Qcfg.Eyetrack.TimeFrame = Reprocess.TimeFrame;
        Qcfg.Eyetrack.useROImaskArea = false;

        %Use new ROI selection if required
        if strcmp(get(btnROIselectionswitch,'String'),'ROI selection ON')
            Qcfg.Eyetrack.ROImask = Reprocess.newROImask;
        else
            CroppedMovie = load(Qcfg.CroppedVideo);
            Qcfg.Eyetrack.ROImask = CroppedMovie.sVideoAll.ROImask;
            clear CroppedMovie
        end

        %Get pupil center
        waitstart;
%         [Qcfg.Eyetrack.vecBaseLocation, Qcfg.Eyetrack.intPupilLuminance] = getPupilcenter(matMovie,Qcfg);
        
        %Get values from UI Edits 
        raysString = get(raysStringEdit,'String');
        radiiStartString = get(radiiStartStringEdit,'String');
        radiiStepString = get(radiiStepStringEdit,'String');
        radiiStopString = get(radiiStopStringEdit,'String');
        oString = get(oStringEdit,'String');
        
        %Transform UI inputs into int 
        rays = str2double(raysString);
       	radiiStart = str2double(radiiStartString);
        radiiStep = str2double(radiiStepString);
        radiiStop = str2double(radiiStopString);
        o = str2double(oString);  
        %Perform eye-tracking on selected timeframe
        
        sEyeTracking = FramePupilDetectStarburstRedo(Qcfg,rays,radiiStart:radiiStep:radiiStop,o);

        %Update vectors and UI
        ROImask = Qcfg.Eyetrack.ROImask;
        
        updateVectors;
        frame = get(sldframe,'Value');
        updateUI(frame);
        waitstop;

    end

    function LoadEyetracking(~,~)
        [FileName, FilePath] = uigetfile( ...
            {  '*EyeTrackData*.*',  'Eye-tracking files (*.*)'; ...
            '*.avi;*.mp4;*.mpg','Raw video files (*.avi, *.mp4, *.mpg)'; ...
            '*.mat','MAT-files (*.mat)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Please select a valid source file to inspect', ...
            'MultiSelect', 'off', ...
            cropppedVideoPath);
        
        if isequal(FileName,0)
            disp('\User selected Cancel')
            return
        else
            fprintf('\nUser selected %s\n',fullfile(FilePath, FileName)); 
        end
        
        % set paths
        FileSourcePath = FilePath;
        
        %Load in eye tracking MAT file
        fLoad = load(fullfile(FilePath, FileName));
        disp(['Loaded Eyetracking file: ', fullfile(FilePath, FileName)]);
        if ~isfield(fLoad,'sEyeTracking')
            error('Please select a valid eye tracking MAT file')
        end
        sEyeTracking = fLoad.sEyeTracking;
        
        %Get info from sEyeTracking
        intStart = sEyeTracking.Frame(1); %Get starting frame for movie
        vecArea = sEyeTracking.vecArea;
        vecPosX = sEyeTracking.vecPosX;
        vecPosY = sEyeTracking.vecPosY;
        vecA = sEyeTracking.vecA;
        vecB = sEyeTracking.vecB;
        vecZ = sEyeTracking.vecZ;
        vecAlpha = sEyeTracking.vecAlpha;
        
        
        
        %set config structure for eye tracking
        cfg = [];
        cfg.FileSavePath = FileSourcePath;
        cfg.strSes = fLoad.sEyeTracking.strSes;
        cfg.strRec = fLoad.sEyeTracking.strRec;
        cfg.intRec = fLoad.sEyeTracking.intRec;
        
        % check for coupled croppedvideo, look in current same directory first, then in default video directory
        sameDirectory = sprintf('%scroppedvideo_%s%s.mat',FilePath,cfg.strSes,cfg.strRec);
        defaultDirectory = sprintf('%s%s%scroppedvideo_%s%s.mat',cropppedVideoPath,cfg.strSes,filesep,cfg.strSes,cfg.strRec);
        if numel(dir(sameDirectory)) > 0
            cfg.CroppedVideo = sameDirectory;
        elseif numel(dir(defaultDirectory)) > 0
            cfg.CroppedVideo = defaultDirectory;
        else
            warning(sprintf('\nUnfortunately the corresponding preprocessed eye-movie data for current session %s is not available in it''s expected source folder!:\n      ''%s''\n ...In order to reproces eyetracking the croppedvideo need to be created or placed in this location!\n',sprintf('%s%s',cfg.strSes,cfg.strRec),FileSourcePath));
            return
        end
        
        %Load in movie info
        sload = load(cfg.CroppedVideo,'sVideoAll');
        ROImask = sload.sVideoAll.ROImask;
        vecTimeStamps = sload.sVideoAll.times - sload.sVideoAll.times(sEyeTracking.Frame(1));
        
        %Get properties of movie file to load single frames
        cellCont = who('-file',cfg.CroppedVideo);
        if strfind([cellCont{:}],'matMovie') == 1
            sMovie = matfile(cfg.CroppedVideo);
        else
            warning('Cannot load in single frames from file, must load entire movie into memory');
        end
                
        %Load in movie info
        sload = load(cfg.CroppedVideo,'sVideoAll');
        ROImask = sload.sVideoAll.ROImask;
        vecTimeStamps = sload.sVideoAll.times - sload.sVideoAll.times(sEyeTracking.Frame(1));
        if isfield(sload.sVideoAll,'matMovie')
            sMovie.matMovie = sload.sVideoAll.matMovie;
        end 
        disp(['Loaded video file: ', cfg.CroppedVideo]);
        
        %If a figure window already exists, clear and update stuff
        if exist('f','var');
            if exist('TimeFrameSelection','var') 
                switchEyeTimeselection;
                TimeFrameSelection = [];
            end
            updateUI(1);
            updateVectors;
        end
    end

    function updateVectors %update vectors with sEyeTracking

        
        vecArea = sEyeTracking.vecArea;
        vecPosX = sEyeTracking.vecPosX;
        vecPosY = sEyeTracking.vecPosY;
        vecA = sEyeTracking.vecA;
        vecB = sEyeTracking.vecB;
        vecZ = sEyeTracking.vecZ;
        vecAlpha = sEyeTracking.vecAlpha;
    end

    function updateUI(intFrame)
        if nargin < 1 || isempty(intFrame)
            intFrame = get(sldframe,'Value');
        end
        
        % update plot
        figure(f);
        subplot(g);
        switch strProp
            case 'area'
                set(t,'YData',vecArea);
                ylim([min(vecArea)-100 max(vecArea)+100]);
            case 'xpos'
                set(t,'YData',vecPosX);
                ylim([min(vecPosX)-10 max(vecPosX)+10]);
            case 'ypos'
                set(t,'YData',vecPosY);
                ylim([min(vecPosY)-10 max(vecPosY)+10]);
        end
        xlim([-200 length(vecArea)+200]);
        
        % update eye tracking image
        subplot(s);
        h = imshow(mat2gray(sMovie.matMovie(:,:,intFrame+intStart-1)));
        hold on
        
        handle = plotellipse(vecZ(intFrame,:),vecA(intFrame),vecB(intFrame),vecAlpha(intFrame),'r');
        set(handle,'LineWidth',3)
        plot(vecPosX(intFrame),vecPosY(intFrame),'gx')
        
        
        
        hold off
        htitle = title(sprintf('frame %.0f Recording %s%s',intFrame,cfg.strSes,cfg.strRec));
        axis off;     
        if exist('gframeline')
            set(gframeline,'XData',[intFrame intFrame]);
        end
                        
        % update sliders
        set(sldframe,'Min',1,'Max',length(vecArea),'Value',intFrame,'SliderStep',smallstep);
        set(sldframe2,'Min',1,'Max',length(vecArea),'Value',intFrame,'SliderStep',bigstep);
    end

    function Undo(~,~,mode)
       switch mode
           case 'save'
               %Save temporary file
               sEyeTracking.vecArea = vecArea;
               sEyeTracking.vecPosX = vecPosX;
               sEyeTracking.vecPosY = vecPosY;
               sTempEyeTracking = sEyeTracking;
           case 'load'
               %Load temporary file
               if exist('sTempEyeTracking','var')
                   sEyeTracking = sTempEyeTracking;
                   updateVectors;
                   updateUI;
               else
                   warning('Cannot undo this action');
               end
       end
    end

    function SaveEyetracking(~,~)
        sEyeTracking.vecArea = vecArea;
        sEyeTracking.vecPosX = vecPosX;
        sEyeTracking.vecPosY = vecPosY;
        sEyeTracking.vecTimeStamps = vecTimeStamps(sEyeTracking.Frame(1):sEyeTracking.Frame(2));
        strFileEyeTracking = sprintf('CheckedEyeTrackData_%s%s',sEyeTracking.strSes,sEyeTracking.strRec);
        if exist(sprintf('%s%s%s',cfg.FileSavePath,strFileEyeTracking,'.mat'),'file')
            strAnswer = questdlg('File already exists, overwrite?','Overwrite');
        else
            strAnswer = 'Yes';
        end
        if strcmp(strAnswer,'Yes')
            %Save file
            save(sprintf('%s%s',cfg.FileSavePath,strFileEyeTracking),'sEyeTracking','-v7.3');
            fprintf('\nSaved checked eye-tracking data of %s%s to %s [%s]\n',sEyeTracking.strSes,sEyeTracking.strRec,cfg.FileSavePath,getTime);

            %check for and delete temporarily saved eyetracking
            if numel(dir(sprintf('%sTempEyeTrackData_%s%s.mat',cfg.FileSavePath,sEyeTracking.strSes,sEyeTracking.strRec))) > 0;
                delete(sprintf('%sTempEyeTrackData_%s%s.mat',cfg.FileSavePath,sEyeTracking.strSes,sEyeTracking.strRec));
            end
        elseif strcmp(strAnswer,'No') || strcmp(strAnswer,'Cancel')
            fprintf('\nDid NOT save checked eye-tracking data\n');
        end
        
    end

    function waitstart
        oldpointer = get(gcf, 'pointer');
        set(gcf, 'pointer', 'watch'); drawnow;
    end

    function waitstop
        if exist('oldpointer')
            set(gcf, 'pointer', oldpointer)
        end
    end

    function removeOutliers(~,~)
        lim = str2double(get(limit,'String'));
        vecArea(vecArea >= lim | vecArea <= 0) = NaN;
        vecPosX(vecArea >= lim | vecArea <= 0) = NaN;
        vecPosY(vecArea >= lim | vecArea <= 0) = NaN;
        vecA(vecArea >= lim | vecArea <= 0) = NaN; 
        vecB(vecArea >= lim | vecArea <= 0) = NaN; 
        vecAlpha(vecArea >= lim | vecArea <= 0) = NaN;
        vecZ(vecArea >= lim | vecArea <= 0) = NaN;
        updateUI(1);
        
    end
end