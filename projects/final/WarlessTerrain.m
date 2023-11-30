function WarlessTerrain(action)

global WrTr pmpthand turn Xcir Ycir Utimehand Ctimehand Utime Ctime BoxHand;
global win MultiP timelimit History Count UCoinHand CCoinHand PauseHand r2;
global XPos YPos FXPos FYPos FCen D2Hand D3Hand UCounter CCounter Ucol Ccol;
global Uback Cback Player1 Player2 Xcirt Ycirt tcolor3 tcolor2 D2 D3 fig;
global UTH CTH SelectHand P1Hand P2Hand P_1Hand P_2Hand UUUhand CPUhand;
global UCountHand CCountHand XcirC YcirC Counter Demo DemoHand;
clc
%--------------------------------------------------------------------------
if nargin < 1,
    %this is to initialize all the necessary variables
    %this if loop is not called again at any stage in the game
    action = 'initialize'; 
    
    turn=2; %0 for player 1 and 1 for player 2
    %since there is flexibility for the players to choose their chance
    %it is assigned 2 as a temporary store
    
    MultiP=0;%by default Play with CPU  
    %this variable is for multiplayers i.e., game between two players
    %0 is game with CPU and 1 for game between two players
    
    Uback=0; Cback=0; 
    %during pause of the game the time which is function of current time
    %should be reassigned

    D2=1;  D3=0;
    %this option is for coins/peg 2D/3D looks
    
    Ucol=1; Ccol=2;
    %selecting the color of coins/pegs
    
    r2=sqrt(2);  
    
    Demo=0;
    %there is option of viewing demo
    %1 for activating demo option
end
%--------------------------------------------------------------------------
if strcmp(action,'initialize')   
    UCounter=1; CCounter=1;
    %count for number of moves
    
    Count=1; win=0; History=[];
    %Count is counting history, containing the previous steps
    %win for deciding upon the status of game
    
    WrTr=[1 2 3 4 5 6 7 8 0 -1 -2 -3 -4 -5 -6 -7 -8];   
    
    %time
    Utime=10*60;    Ctime=10*60;
    %time limits for each player
%--------------------------------------------------------------------------   
    fig=figure( ...
                'Name','Warless Terrain', 'NumberTitle','off', ...
                'Visible','off', 'BackingStore','off');
    figure(fig); 
    hold on
    
    %Board Definitions/Boundaries       
    line([1 -1.5]*r2,[1.5 -1]*r2,'color','k','linewidth',4);
    line([1 -1.5]*r2,[-1.5 1]*r2,'color','k','linewidth',4);
    
    line([1.5 -1]*r2,[1 -1.5]*r2,'color','k','linewidth',4);
    line([1.5 -1]*r2,[-1 1.5]*r2,'color','k','linewidth',4);
    
    line([2.5 1]*r2,[0 1.5]*r2,'color','k','linewidth',4);
    line([2.5 1]*r2,[0 -1.5]*r2,'color','k','linewidth',4);
   
    line([-2.5 -1]*r2,[0 1.5]*r2,'color','k','linewidth',4);
    line([-2.5 -1]*r2,[0 -1.5]*r2,'color','k','linewidth',4);
    
    line([0.5 2]*r2,[1 -0.5]*r2,'color','k','linewidth',4);
    line([0.5 2]*r2,[-1 0.5]*r2,'color','k','linewidth',4);
    
    line([-0.5 -2]*r2,[1 -0.5]*r2,'color','k','linewidth',4);
    line([-0.5 -2]*r2,[-1 0.5]*r2,'color','k','linewidth',4);
    
    %Decoration
    line([0 0]*r2,[-0.5 -0.75]*r2,'color','k','linewidth',2);
    line([0 0]*r2,[0.5 0.25]*r2,'color','k','linewidth',2);
    line([1 1]*r2,[-1.5 -1.75]*r2,'color','k','linewidth',2);
    line([-1 -1]*r2,[-1.5 -1.75]*r2,'color','k','linewidth',2);
    line([1 1]*r2,[1.5 1.25]*r2,'color','k','linewidth',2);
    line([-1 -1]*r2,[1.5 1.25]*r2,'color','k','linewidth',2);
    line([2.5 2.5]*r2,[0 -0.25]*r2,'color','k','linewidth',2);
    line([-2.5 -2.5]*r2,[0 -0.25]*r2,'color','k','linewidth',2);   
    
    Xcir=0.05*cos(0:1/50:2*pi);
    Ycir=0.05*sin(0:1/50:2*pi);
    fill(0*r2+Xcir,-0.75*r2+Ycir,'k');
    fill(0*r2+Xcir,0.25*r2+Ycir,'k');
    fill(1*r2+Xcir,-1.75*r2+Ycir,'k');
    fill(-1*r2+Xcir,-1.75*r2+Ycir,'k');
    fill(1*r2+Xcir,1.25*r2+Ycir,'k');
    fill(-1*r2+Xcir,1.25*r2+Ycir,'k');
    fill(2.5*r2+Xcir,-0.25*r2+Ycir,'k');
    fill(-2.5*r2+Xcir,-0.25*r2+Ycir,'k');   
      
    %Collecting valid Central Positions
    XPos=[-2 -1.5 -1 -1.5 -1 -0.5 -1 -0.5 0 0.5 1  0.5 1 1.5  1  1.5 2]*r2;
    YPos=[ 0  0.5  1 -0.5  0  0.5 -1 -0.5 0 0.5 1 -0.5 0 0.5 -1 -0.5 0]*r2;
    
    %Collecting Click Positions
    FXPos=162.5:35:450;
    FYPos=156:35:330;
    FCen=[162.5 226;
          197.5 261;
          232.5 296;
          197.5 191;
          232.5 226;
          267.5 261;
          232.5 156;
          267.5 191;
          302.5 226;
          337.5 261;
          372.5 296;
          337.5 191;
          372.5 226;
          407.5 261;
          372.5 156;
          407.5 191;
          442.5 226];
    
    %X,YPos are theoritical (normalised positions in figure window)  
    %FX,YPos are the actual clicks during game play
    %both are correlated in the later steps
      
    %timers to capture the dynamic time spent during each move
    rectangle('Position', [-1*r2-0.55 1.6*r2 1 0.45],'linewidth',2,'edgecolor','w');
    rectangle('Position', [1*r2-0.55 1.6*r2 1 0.45],'linewidth',2,'edgecolor','k');
    Utimehand=text(-1*r2-0.5,1.75*r2,sprintf('%02.0f : %02.0f',floor(Utime/60),mod(Utime,60)),'color','k','fontweight','bold');
    Ctimehand=text(1*r2-0.5,1.75*r2,sprintf('%02.0f : %02.0f',floor(Ctime/60),mod(Ctime,60)),'color','w','fontweight','bold');    
    
    %Arrow Handles
    for ii=1:2,
        UTH(ii)=text(-0.25-ii/3,3.3,'\leftarrow','color','k','fontsize',15);
        CTH(ii)=text(-0.25+ii/3,3.3,'\rightarrow','color','k','fontsize',15);
    end
        
    %3D-Coins
    N=10;
    for ii=N:-1:1,
        Xcirt(ii,:)=(N-ii)*cos(0:1/10:2*pi)/N;
        Ycirt(ii,:)=(N-ii)*sin(0:1/10:2*pi)/N;
        tcolor3(1,ii,1:3)=[N*1 ii*1 N*1]/N;          %3D Magenta
        tcolor3(2,ii,1:3)=[ii*1 N*1 N*1]/N;          %3D Cyan
        tcolor3(3,ii,1:3)=[N*1 N*1 ii*1]/N;          %3D Yellow
        tcolor3(4,ii,1:3)=[ii*1 ii*1 N*1]/N;         %3D Blue
        tcolor3(5,ii,1:3)=[ii*1 N*1 ii*1]/N;         %3D Green
        tcolor3(6,ii,1:3)=[N*1 ii*1 ii*1]/N;         %3D Red
        tcolor3(7,ii,1:3)=ii*[1 1 1]/N;              %3D Black
        tcolor3(8,ii,1:3)=(N-ii/1.5)*[1 1 1]/N;      %3D White
        tcolor3(9,ii,1:3)=1.5*[N*1 ii*0.6 ii*0.3]/N; %3D Orange
    end
    
    UUUcolor=tcolor3(Ucol,:,1:3);
    CPUcolor=tcolor3(Ccol,:,1:3);
    
    %Handles-3D-Coins
    if D3==1,
        for ii=1:17,
            X=XPos(ii)+Xcirt*0.3;
            Y=YPos(ii)+Ycirt*0.3;
            if ii<9, 
                UCoinHand(ii)=patch(X',Y',UUUcolor); 
                set(UCoinHand(ii),'edgecolor','none'); 
            end  
            if ii>9,
                CCoinHand(ii-9)=patch(X',Y',CPUcolor); 
                set(CCoinHand(ii-9),'edgecolor','none'); 
            end
        end
    end
    
    tcolor2=[1 0 1;0 1 1;1 1 0;0 0 1;0 1 0;1 0 0;0 0 0;1 1 1;1 0.6 0.3];
    
    %2D-Coins
    if D2==1,
        for ii=1:17,
            if ii<9, UCoinHand(ii)=fill(XPos(ii)+Xcir*5,YPos(ii)+Ycir*5,tcolor2(Ucol,:));  end  
            if ii>9, CCoinHand(ii-9)=fill(XPos(ii)+Xcir*5,YPos(ii)+Ycir*5,tcolor2(Ccol,:));  end
        end
    end    
    
    %17 Boxes for highlighting each possible move
    for ii=1:17,
        BoxHand(ii)=line([XPos(ii) XPos(ii)+1/r2 XPos(ii) XPos(ii)-1/r2 XPos(ii)],[YPos(ii)-1/r2 YPos(ii) YPos(ii)+1/r2 YPos(ii) YPos(ii)-1/r2],'linewidth',1.5,'color','g'); 
        set(BoxHand(ii),'visible','off');
    end
%--------------------------------------------------------------------------   
    %Prompt Handles
    Num=9;
    SelectHand=line([XPos(Num) XPos(Num)+1/r2 XPos(Num) XPos(Num)-1/r2 XPos(Num)],[YPos(Num)-1/r2 YPos(Num) YPos(Num)+1/r2 YPos(Num) YPos(Num)-1/r2],'linewidth',2,'color','w','visible','off');
    
    %Turn Handles
    UUUhand=text(-1.75,3.25,'UUU','color','w');
    CPUhand=text(1.00,3.25,'CPU','color','k');
    pmpthand = text(-1.35,-2.25,'.............Start.............','color','m','fontsize',10,'fontweight','bold');
    
    %Counter Handles to count and display the number of movesthat were
    %lapsed
    Counter=[...
            -0.25 -0.75;-0.5	-1;-0.75	-1.25;-1 -1.5;-1.25 -1.25;
            -1.5 -1;-1.75 -0.75;-2 -0.5;-2.25 -0.25;-2.5 0;-2.25 0.25;
            -2 0.5;-1.75 0.75;-1.5 1;-1.25 1.25;-1 1.5;-0.75 1.25;
            -0.5 1;-0.25 0.75;0	0.5;0.25 0.75;0.5 1;0.75 1.25;1	1.5;
            1.25 1.25;1.5 1;1.75	0.75;2 0.5;2.25	0.25;2.5 0;2.25	-0.25;
            2 -0.5;1.75	-0.75;1.5 -1;1.25 -1.25;1 -1.5;0.75	-1.25;0.5 -1;
            0.25 -0.75;0 -0.5]*r2;

    XcirC=0.075*cos(0:1/50:2*pi);
    YcirC=0.075*sin(0:1/50:2*pi);
    UCountHand = fill(-0.1+Counter(40,1)+Xcir,Counter(40,2)+Ycir,'w');
    set(UCountHand,'facecolor',tcolor2(Ucol,:),'edgecolor',tcolor2(Ucol,:));
    CCountHand = fill(0.1+Counter(40,1)+Xcir,Counter(40,2)+Ycir,'w');
    set(CCountHand,'facecolor',tcolor2(Ccol,:),'edgecolor',tcolor2(Ccol,:));
    
    title('Warless Terrain','fontsize',18,'color','b');
    axis([-2.5*r2 2.5*r2 -2.5*r2 2.5*r2]);
    axis equal
    hold off
    axis off
    set(gcf,'Resize','off');
%--------------------------------------------------------------------------
% Handling the handles

axes( ...
        'Units','normalized',  ...
        'Visible','off', 'DrawMode','fast', ...
        'NextPlot','replace');

P1Hand=uicontrol('units','normalized',...
          'position', [.28 .12 .05 .06],'string','1P', ...
          'callback','WarlessTerrain(''1P'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',[1 0.6 0.3]+MultiP*[0 0.4 0.7]);

P2Hand=uicontrol('units','normalized',...
          'position', [.28 .04 .05 .06],'string','2P', ...
          'callback','WarlessTerrain(''2P'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]-MultiP*[0 0.4 0.7]);
      
D2Hand=uicontrol('units','normalized',...
          'position', [.35 .12 .05 .06],'string','2D', ...
          'callback','WarlessTerrain(''2D'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',D2*[1 0.6 0.3]+D3*[1 1 1]);

D3Hand=uicontrol('units','normalized',...
          'position', [.35 .04 .05 .06],'string','3D', ...
          'callback','WarlessTerrain(''3D'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',D3*[1 0.6 0.3]+D2*[1 1 1]);

uicontrol('units','normalized',...
          'position', [.42 .08 .07 .06],'string','Undo', ...
          'callback','WarlessTerrain(''Undo'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);
      
uicontrol('units','normalized',...
          'position',[.50 .12 .05 .06],'string','UUU', ...
	      'callback','WarlessTerrain(''UUUturn'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);

uicontrol('units','normalized',...
          'position',[.50 .04 .05 .06],'string','CPU', ...
	      'callback','WarlessTerrain(''CPUturn'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);
      
PauseHand=uicontrol('units','normalized',...
          'position',[.56 .08 .07 .06],'string','Pause', ...
	      'callback','WarlessTerrain(''Pause'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);
      
P_1Hand=uicontrol('units','normalized',...
          'position', [.64 .12 .05 .06],'string','P 1', ...
          'callback','WarlessTerrain(''P1'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',tcolor2(Ucol,:));

P_2Hand=uicontrol('units','normalized',...
          'position', [.64 .04 .05 .06],'string','P 2', ...
          'callback','WarlessTerrain(''P2'')', ...
          'interruptible','on','fontweight','bold','BackgroundColor',tcolor2(Ccol,:));
      
uicontrol('units','normalized',...
          'position',[.71 .12 .06 .06],'string','Help', ...
	      'callback','WarlessTerrain(''Help'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);

uicontrol('units','normalized',...
          'position',[.71 .04 .06 .06],'string','Exit', ...
	      'callback','WarlessTerrain(''Exit'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);
      
DemoHand=uicontrol('units','normalized',...
          'position',[.80 .07 .08 .08],'string','Demo', ...
	      'callback','WarlessTerrain(''Demo'')', ...
	      'interruptible','on','fontweight','bold','BackgroundColor',[1 1 1]);
%--------------------------------------------------------------------------      
    %Turn Handles
    if turn~=2,
        Player1 = 'UUU';
        Player1 = inputdlg({'Enter your name'},'Player',1,{Player1});
        set(UUUhand,'string',Player1);    
    
        if MultiP==1,
            Player2 = 'CPU';
            Player2 = inputdlg({'Enter 2nd Player name'},'Player',1,{Player2});
            set(CPUhand,'string',Player2);
        end
        
        %setting timelimits
        timelimit = Utime/60;
        timelimit = inputdlg({'Time limit [min]'},'Time Limit',1,{num2str(timelimit)});
        if isempty(timelimit)
            close(fig);
            return;
        end
    
        timelimit=str2double(timelimit);
        Utime=timelimit*60;
        Ctime=timelimit*60;
    end   
    
    if turn~=2 && MultiP==0,
        msg={'Select "2P" for Multi-Player (by default it is with CPU [1P]...'};
        [namastedata namastemap]=imread('namaste.jpg');
        msgbox(msg,'Number of Players!!!','custom',namastedata,namastemap);        
        pause(3);
    end   
    
    if turn~=2,
        if mod(turn,2)==0, WarlessTerrain('UUU');  end
        if mod(turn,2)==1, WarlessTerrain('CPU');  end
    end
end
%--------------------------------------------------------------------------
if strcmp(action,'UUU')     
    set(SelectHand,'visible','off');    
    
    for ii=1:2,
        set(UTH(ii),'color','w');
        set(CTH(ii),'color',[0.8 0.8 0.8]);
    end
    
    set(UUUhand,'fontsize',10);
    set(CPUhand,'fontsize',8);
    
  if Demo==0,
    t1=clock;
    %checking for possibilities of available moves
    pos=find(WrTr==0);
    count=1;Choice=[];
    for ii=1:17,
        validity=0;
        if (WrTr(ii)>0 && turn==0)
            validity=Check_Validity(ii,pos,FCen);
        end
        if validity==1,
            set(BoxHand(ii),'visible','on');        
            Choice(count)=ii;
            count=count+1;
        end
    end    
    
    %selection of coin/peg
    Button=1;
    if isempty(Choice), Button=0;  end
    while Button==1,  
          valid=[0 0];
          set(fig,'Currentpoint',[0 0]);
          set(pmpthand,'string','Select the Coin...','color',tcolor2(Ucol,:));
          while valid==zeros(1,2),
                valid = get(fig,'Currentpoint');
                t2=clock;
                set(Utimehand,'string',sprintf('%02.0f : %02.0f',floor((Utime+Uback-floor(etime(t2,t1)))/60),mod((Utime+Uback-floor(etime(t2,t1))),60)));
                pause(1);
                Xnew=valid(1); Ynew=valid(2);
                if floor((Utime+Uback-floor(etime(t2,t1)))/60)<0,  WarlessTerrain('win'); end
          end          
          
          if valid==zeros(1,2), Button=1;  continue;  end
          
          FDmin=10000;
          for ii=1:17,     
                if FDmin>=sqrt((Xnew-FCen(ii,1))^2+(Ynew-FCen(ii,2))^2),
                    FDmin=sqrt((Xnew-FCen(ii,1))^2+(Ynew-FCen(ii,2))^2);
                    Numi=ii;
                end
          end
   
       if (Numi~=0 && Button==1),           
           if (WrTr(Numi)>0 && ~isempty(find(WrTr==WrTr(Numi),1)) && ~isempty(find(Choice==Numi,1))),          
               Button=0;
               set(SelectHand,'xdata',[XPos(Numi) XPos(Numi)+1/r2 XPos(Numi) XPos(Numi)-1/r2 XPos(Numi)],'ydata',[YPos(Numi)-1/r2 YPos(Numi) YPos(Numi)+1/r2 YPos(Numi) YPos(Numi)-1/r2],'visible','on');
           else
               set(pmpthand,'string','Not a Valid Selection...','color','r');
               pause(1);
           end
       end
    end        
    
    %Refreshing all 17 Boxes Handles
    for ii=1:17, set(BoxHand(ii),'visible','off'); end
    
    if ~isempty(Choice),
    %selection of position
        Numf=find(WrTr==0);
        WrTr(Numf)=WrTr(Numi);             
        WrTr(Numi)=0;
        pause(1);
        set(SelectHand,'xdata',[XPos(Numf) XPos(Numf)+1/r2 XPos(Numf) XPos(Numf)-1/r2 XPos(Numf)],'ydata',[YPos(Numf)-1/r2 YPos(Numf) YPos(Numf)+1/r2 YPos(Numf) YPos(Numf)-1/r2],'visible','on');
        offset=(UCounter-20)/(0.001+abs(UCounter-20));
        set(UCountHand,'xdata',0.095*offset+Counter(UCounter,1)+XcirC,'ydata',0.095*offset+Counter(UCounter,2)+YcirC);
        UCounter=UCounter+1;
    end
  end
    
    if Demo==1,
        pos=find(WrTr==0);
        count=1;Choice=[];
        for ii=1:17,
            validity=0;
            if (WrTr(ii)>0)
                validity=Check_Validity(ii,pos,FCen);
            end
            if validity==1,
                set(BoxHand(ii),'visible','on');        
                Choice(count)=ii;
                count=count+1;
            end
        end        
        pause(2);
        
        %Selecting good move
        if count==2, Numi=Choice(1);  end% if one & only choice
        for ii=1:count-1,            
            tmpWrTr=WrTr;
            pos=find(tmpWrTr==0);            
            tmpWrTr(pos)=tmpWrTr(Choice(ii));
            tmpWrTr(Choice(ii))=0;
            for jj=1:17,%preference is for very isolated coin/peg
                if (tmpWrTr(jj)<0),
                    pos=find(tmpWrTr==0);
                    subvalidity=Check_Validity(jj,pos,FCen);
                    if subvalidity==1, Numi=Choice(ii); end
                end
            end
        end        
        
        set(SelectHand,'xdata',[XPos(Numi) XPos(Numi)+1/r2 XPos(Numi) XPos(Numi)-1/r2 XPos(Numi)],'ydata',[YPos(Numi)-1/r2 YPos(Numi) YPos(Numi)+1/r2 YPos(Numi) YPos(Numi)-1/r2],'visible','on');
        Numf=find(WrTr==0);
        WrTr(Numf)=WrTr(Numi);             
        WrTr(Numi)=0;
        pause(2);
        
        %Refreshing all 17 Boxes Handles
        for ii=1:17, set(BoxHand(ii),'visible','off'); end
        
        set(SelectHand,'xdata',[XPos(Numf) XPos(Numf)+1/r2 XPos(Numf) XPos(Numf)-1/r2 XPos(Numf)],'ydata',[YPos(Numf)-1/r2 YPos(Numf) YPos(Numf)+1/r2 YPos(Numf) YPos(Numf)-1/r2],'visible','on');
        offset=(UCounter-20)/(0.001+abs(UCounter-20));
        set(UCountHand,'xdata',0.095*offset+Counter(UCounter,1)+XcirC,'ydata',0.095*offset+Counter(UCounter,2)+YcirC);
        UCounter=UCounter+1;
        t1=clock; t2=clock;
    end
    
    if count~=1, 
        Utime=Utime+Uback-floor(etime(t2,t1));
        Uback=0;    
        if D2==1, set(UCoinHand(WrTr(Numf)),'Xdata',(XPos(Numf)+Xcir*5)','Ydata',(YPos(Numf)+Ycir*5)');  end 
        if D3==1, set(UCoinHand(WrTr(Numf)),'Xdata',(XPos(Numf)+Xcirt*0.3)','Ydata',(YPos(Numf)+Ycirt*0.3)');  end           
        History(Count,:)=[Numi Numf];
        Count=Count+1;
        wavplay(wavread('UUU.wav'));        
        pause(0.5);   
    end
    
    win=Check_Status(WrTr);
    if win==1 || UCounter>40, 
        WarlessTerrain('win');
    end

    turn=~turn;
    WarlessTerrain('CPU');
end
%--------------------------------------------------------------------------
if strcmp(action,'CPU')    
    set(SelectHand,'visible','off');    
    
    for ii=1:2,
        set(CTH(ii),'color','k');
        set(UTH(ii),'color',[0.8 0.8 0.8]);
    end
    
    set(UUUhand,'fontsize',8);
    set(CPUhand,'fontsize',10);
    
    t1=clock;
    %UUU
    if MultiP==1,              
        
        pos=find(WrTr==0);
        count=1;Choice=[];
        for ii=1:17,
            validity=0;
            if (WrTr(ii)<0 && turn==1)
                validity=Check_Validity(ii,pos,FCen);
            end
            if validity==1,
                set(BoxHand(ii),'visible','on');        
                Choice(count)=ii;
                count=count+1;
            end
        end          
        
        Button=1;
        if isempty(Choice), Button=0;  end
        while Button==1,
              valid=[0 0];
              set(fig,'Currentpoint',[0 0]);
              set(pmpthand,'string','Select the Coin...','color',tcolor2(Ccol,:));
              while valid==zeros(1,2),
                    valid = get(fig,'Currentpoint');
                    t2=clock;
                    set(Ctimehand,'string',sprintf('%02.0f : %02.0f',floor((Ctime+Cback-floor(etime(t2,t1)))/60),mod((Ctime+Cback-floor(etime(t2,t1))),60)));
                    pause(1);
                    Xnew=valid(1); Ynew=valid(2);
                    if floor((Ctime+Cback-floor(etime(t2,t1)))/60)<0,  WarlessTerrain('win');  end
              end
              
              FDmin=10000;
              for ii=1:17,     
                if FDmin>=sqrt((Xnew-FCen(ii,1))^2+(Ynew-FCen(ii,2))^2),
                    FDmin=sqrt((Xnew-FCen(ii,1))^2+(Ynew-FCen(ii,2))^2);
                    Numi=ii;
                end
              end
    
              if (Numi~=0 && Button==1),           
                if (WrTr(Numi)<0 && ~isempty(find(WrTr==WrTr(Numi),1)) && ~isempty(find(Choice==Numi,1))),          
                    Button=0;
                    set(SelectHand,'xdata',[XPos(Numi) XPos(Numi)+1/r2 XPos(Numi) XPos(Numi)-1/r2 XPos(Numi)],'ydata',[YPos(Numi)-1/r2 YPos(Numi) YPos(Numi)+1/r2 YPos(Numi) YPos(Numi)-1/r2],'visible','on');
                else
                    set(pmpthand,'string','Not a Valid Selection...','color','r');
                    pause(1);
                end
              end              
        end         
        
        %Refreshing all 17 Boxes Handles
        for ii=1:17, set(BoxHand(ii),'visible','off'); end
    
        if ~isempty(Choice),
        %selection of position
            Numf=find(WrTr==0);
            WrTr(Numf)=WrTr(Numi);             
            WrTr(Numi)=0;
            pause(1);
            set(SelectHand,'xdata',[XPos(Numf) XPos(Numf)+1/r2 XPos(Numf) XPos(Numf)-1/r2 XPos(Numf)],'ydata',[YPos(Numf)-1/r2 YPos(Numf) YPos(Numf)+1/r2 YPos(Numf) YPos(Numf)-1/r2],'visible','on');
            offset=(CCounter-20)/(0.001+abs(CCounter-20));
            set(CCountHand,'xdata',-0.095*offset+Counter(CCounter,1)+XcirC,'ydata',-0.095*offset+Counter(CCounter,2)+YcirC);
            CCounter=CCounter+1;   
        end
    end
    
    %CPU
    if MultiP==0,
        %"AI" will be any Valid Move
        set(pmpthand,'string','Please Wait...Thinking...','color',tcolor2(Ccol,:));
        pos=find(WrTr==0);
        count=1;Choice=[];
        for ii=1:17,
            validity=0;
            if (WrTr(ii)<0)
                validity=Check_Validity(ii,pos,FCen);
            end
            if validity==1,
                set(BoxHand(ii),'visible','on');        
                Choice(count)=ii;
                count=count+1;
            end
        end        
        pause(2);
        
        %Selecting good move
        if count==2, Numi=Choice(1);  end% if one & only choice
        for ii=1:count-1,            
            tmpWrTr=WrTr;
            pos=find(tmpWrTr==0);            
            tmpWrTr(pos)=tmpWrTr(Choice(ii));
            tmpWrTr(Choice(ii))=0;
            for jj=1:17,%preference is for very isolated coin/peg
                if (tmpWrTr(jj)>0),
                    pos=find(tmpWrTr==0);
                    subvalidity=Check_Validity(jj,pos,FCen);
                    if subvalidity==1, Numi=Choice(ii); end
                end
            end
        end        
        
        if ~isempty(Choice), 
            set(SelectHand,'xdata',[XPos(Numi) XPos(Numi)+1/r2 XPos(Numi) XPos(Numi)-1/r2 XPos(Numi)],'ydata',[YPos(Numi)-1/r2 YPos(Numi) YPos(Numi)+1/r2 YPos(Numi) YPos(Numi)-1/r2],'visible','on');
            Numf=find(WrTr==0);
            WrTr(Numf)=WrTr(Numi);             
            WrTr(Numi)=0;
            pause(2);
        
            %Refreshing all 17 Boxes Handles
            for ii=1:17, set(BoxHand(ii),'visible','off'); end
            set(SelectHand,'xdata',[XPos(Numf) XPos(Numf)+1/r2 XPos(Numf) XPos(Numf)-1/r2 XPos(Numf)],'ydata',[YPos(Numf)-1/r2 YPos(Numf) YPos(Numf)+1/r2 YPos(Numf) YPos(Numf)-1/r2],'visible','on');
            offset=(CCounter-20)/(0.001+abs(CCounter-20));
            set(CCountHand,'xdata',-0.095*offset+Counter(CCounter,1)+XcirC,'ydata',-0.095*offset+Counter(CCounter,2)+YcirC);
            CCounter=CCounter+1;
        end
    end    
    
    if count~=1,
        if MultiP==1, Ctime=Ctime+Cback-floor(etime(t2,t1));  end
        Cback=0;
        wavplay(wavread('CPU.wav'));
        if D2==1, set(CCoinHand(-WrTr(Numf)),'Xdata',(XPos(Numf)+Xcir*5)','Ydata',(YPos(Numf)+Ycir*5)');  end 
        if D3==1, set(CCoinHand(-WrTr(Numf)),'Xdata',(XPos(Numf)+Xcirt*0.3)','Ydata',(YPos(Numf)+Ycirt*0.3)');  end              
        History(Count,:)=[Numi Numf];
        Count=Count+1;
        if MultiP==0, Ctime=Utime; end
        set(Ctimehand,'string',sprintf('%02.0f : %02.0f',floor((Ctime+Cback)/60),mod((Ctime+Cback),60)));
        pause(0.5);  
    end
        
    win=Check_Status(WrTr);
    if win~=0 || CCounter>40, 
        WarlessTerrain('win');
    end
    
    turn=~turn;
    WarlessTerrain('UUU');
end
%--------------------------------------------------------------------------
if strcmp(action,'Undo')  
    Count=Count-1;
    turn=~turn;
    Numi=History(Count,1);
    Numf=History(Count,2);
    
    WrTr(Numi)=WrTr(Numf);
    WrTr(Numf)=0;    
    
    if mod(turn,2)==0,  
        if D2==1, set(UCoinHand(WrTr(Numi)),'Xdata',(XPos(Numi)+Xcir*5)','Ydata',(YPos(Numi)+Ycir*5)');  end 
        if D3==1, set(UCoinHand(WrTr(Numi)),'Xdata',(XPos(Numi)+Xcirt*0.3)','Ydata',(YPos(Numi)+Ycirt*0.3)');  end 
        for ii=1:17, set(BoxHand(ii),'visible','off'); end
        UCounter=UCounter-1;
        WarlessTerrain('UUU');  
    end
    
    if mod(turn,2)==1, 
        if D2==1, set(CCoinHand(-WrTr(Numi)),'Xdata',(XPos(Numi)+Xcir*5)','Ydata',(YPos(Numi)+Ycir*5)');  end 
        if D3==1, set(CCoinHand(-WrTr(Numi)),'Xdata',(XPos(Numi)+Xcirt*0.3)','Ydata',(YPos(Numi)+Ycirt*0.3)');  end 
        for ii=1:17, set(BoxHand(ii),'visible','off'); end
        CCounter=CCounter-1;
        WarlessTerrain('CPU');  
    end
end
%--------------------------------------------------------------------------
if strcmp(action,'Pause')
    set(PauseHand,'BackgroundColor',[1 0.6 0.3]);
    t1=clock;
    if ~waitforbuttonpress,  
        set(PauseHand,'BackgroundColor',[1 1 1]);        
    end        
    if mod(turn,2)==0, Uback=floor(etime(clock,t1));  end
    if mod(turn,2)==1, Cback=floor(etime(clock,t1));  end
end
%--------------------------------------------------------------------------
if strcmp(action,'Exit') 
    closereq;
end
%--------------------------------------------------------------------------
if strcmp(action,'1P'),     
    MultiP=0;
    set(P1Hand,'BackgroundColor',[1 0.6 0.3]);
    set(P2Hand,'BackgroundColor',[1 1 1]);
end
%--------------------------------------------------------------------------
if strcmp(action,'2P'),     
    MultiP=1;
    set(P2Hand,'BackgroundColor',[1 0.6 0.3]);
    set(P1Hand,'BackgroundColor',[1 1 1]);
end
%--------------------------------------------------------------------------
if strcmp(action,'UUUturn'),     
    turn=0;
    closereq;
    WarlessTerrain('initialize');
end
%--------------------------------------------------------------------------
if strcmp(action,'CPUturn'),     
    turn=1;
    closereq;
    WarlessTerrain('initialize');
end
%--------------------------------------------------------------------------
if strcmp(action,'2D'),   
    D2=1;
    D3=0;
    closereq;
    WarlessTerrain('initialize');
end
%--------------------------------------------------------------------------
if strcmp(action,'3D'),   
    D2=0;
    D3=1;
    closereq;
    WarlessTerrain('initialize');
end
%--------------------------------------------------------------------------
if strcmp(action,'P1'), 
    Ucol=Ucol+1;
    if Ucol>8, Ucol=1;  end
    if Ucol==Ccol, Ucol=Ucol+1; end
    for ii=1:8,
        if D3==1, set(UCoinHand(ii),'cdata',tcolor3(Ucol,:,1:3));  end
        if D2==1, set(UCoinHand(ii),'facecolor',tcolor2(Ucol,:));  end
    end    
    set(P_1Hand,'BackgroundColor',tcolor2(Ucol,:));
    set(UCountHand,'facecolor',tcolor2(Ucol,:),'edgecolor',tcolor2(Ucol,:));
    set(CCountHand,'facecolor',tcolor2(Ccol,:),'edgecolor',tcolor2(Ccol,:));
end
%--------------------------------------------------------------------------
if strcmp(action,'P2'),   
    Ccol=Ccol+1;
    if Ccol>8, Ccol=1;  end
    if Ucol==Ccol, Ccol=Ccol+1; end
    for ii=1:8,
        if D3==1, set(CCoinHand(ii),'cdata',tcolor3(Ccol,:,1:3));  end
        if D2==1, set(CCoinHand(ii),'facecolor',tcolor2(Ccol,:));  end        
    end
    set(P_2Hand,'BackgroundColor',tcolor2(Ccol,:));
    set(UCountHand,'facecolor',tcolor2(Ucol,:),'edgecolor',tcolor2(Ucol,:));
    set(CCountHand,'facecolor',tcolor2(Ccol,:),'edgecolor',tcolor2(Ccol,:));
end
%--------------------------------------------------------------------------
if strcmp(action,'Demo'), 
    Demo=~Demo;
    
    if Demo==0,  set(DemoHand,'BackgroundColor',[1 1 1]);  end
    if Demo==1,  set(DemoHand,'BackgroundColor',[1 0.6 0.3]);  end     
    
    if Demo==1,  
        set(pmpthand,'string','Click "Demo" again to play Game...','color','r');
        WarlessTerrain('UUU');  
    end
    
    if Demo==0,          
        if turn==2, turn=0; end 
        MultiP=0;%by default Play with CPU  
        Uback=0; Cback=0;
        closereq;
        WarlessTerrain('initialize');
    end
end
%--------------------------------------------------------------------------
if strcmp(action,'win') 
    if win>0,
        msg=sprintf('Nice Play...%s WON the Game...',char(Player1));  
        pause(0.5);
        TopScore(Player1,UCounter-1,Utime);
    end
    if win<0,
        msg=sprintf('Nice Play...%s WON the Game...',char(Player2));         
        if MultiP==1,
            pause(0.5);
            TopScore(Player2,CCounter-1,Ctime); 
        end 
    end
    if win==0,
        msg={'The Game is draw...'};
    end
    
    wavplay(wavread('Finish.wav'));
    
    [namastedata namastemap]=imread('namaste.jpg');
    msg_handle=msgbox(msg,'Nice Game...!','custom',namastedata,namastemap);        
    if ~waitforbuttonpress,  close(msg_handle);  end
    
    PlayAgain='y';
    PlayAgain = inputdlg({'Want to Play Again???'},'PlayAgain',1,{PlayAgain});
    if strcmp(PlayAgain,'y'),
        WarlessTerrain('initialize');
    else
        closereq;
    end    
end
%--------------------------------------------------------------------------
if strcmp(action,'Help')
    scrsz = get(0,'ScreenSize');
    Helpfig=figure( ...
                'Name','Help', 'NumberTitle','off', ...
                'Visible','off', 'BackingStore','off');
    figure(Helpfig);    
    image(imread('Help1.jpg'));
    set(Helpfig,'Position',[0.5 0.5 scrsz(3)/2.25 scrsz(4)/1.2]);  
    axis off
    msg=['DESCRIPTION of the GAME:                                                                        ';...
         '--> Inspired by Chinese puzzle.                                                                 ';...
         '--> The Name of Game is so as there is no war between two teams.                                ';...
         '--> Since there is no war, at any point of time all the coins/pegs are intact.                  ';...
         '--> The objective of game is to swap the coins/pegs to occupy opponents terrain.                ';...
         '--> The coins/pegs can be moved to adjacent vacant place (no diagonal move is allowed).         ';...
         '--> The coins/pegs can be jumped (only one step) to vacant palce (no diagonal jump is allowed). ';...
         '--> Jumping is allowed within both inter and intra coins/pegs (both Forward and Backward).      ';...
         '--> In any of players turn, if there exists any possible move then it has to be played.         ';...
         '--> In case of no possible move then player can pass his chance.                                ';...
         '--> The one who place all his coins/pegs in opponents terrain first will WIN the game.          ';...
         '                                                                                                ';...
         'GUI & MODULES:                                                                                  ';...
         '--> Choose "Demo" before starting the game for viewing the game demo and follow the instruction.';...
         '--> To start the GAME, select "UUU" or "CPU" in order to choose the turn.                       ';...
         '--> Select "UUU" or "CPU" button at any point in the game in order to start a NEW GAME.         ';...
         '--> By default (1P) the game is played by you and CPU unless 2P (two players game) is selected. ';...
         '--> By default (2D) the game coins/pegs are 2D unless 3D (3 dimensional look) is selected.      ';...
         '--> Players can choose their coin/peg colors other than the default.                            ';...
         '--> To change the colors click (P 1) or (P 2) continuosly which reflects on their buttons also. ';...
         '--> The possible moves for each player is highlighted with Green Box.                           ';...
         '--> The selected move is highlighted with White Box.                                            ';...
         '--> The Game is limited by Time(as specified by user) + # of Moves(maximum limit 40).           ';...
         '--> The Game cannot be "Draw" unless the above condition governs.                               ';...
         '--> # of Moves is shown on boundary of the board with small circles of chosen coin/peg color.   ';...
         '--> Each side of square(Board) is counted as 2 steps. Covering entire BOARD implies end of GAME.';...
         '--> At the end of game, the Winner Name, # of Moves and Time is updated in the Top Scores List. ';...
         '--> The buttons which are highlighted with Orange color indicates the selection/mode.           '];
   
    [helpdata helpmap]=imread('Help.jpg');
    MsgHand=msgbox(msg,'HELP','custom',helpdata,helpmap);
    set(MsgHand,'position',[scrsz(3)/4 scrsz(3)/5.5 scrsz(3)/2.5 scrsz(4)/2.1]);
    ChildHand= get(MsgHand,'children');
    set(findobj(ChildHand,'type','text'),'fontname','courier');
    set(ChildHand(3),'position',[225    7.0000   40.0000   17.0000]);
    HelpClose = waitforbuttonpress;
    if HelpClose==0,  close(Helpfig);  end
end
%--------------------------------------------------------------------------