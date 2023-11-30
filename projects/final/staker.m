function staker
%STAKER   Starts a game of Staker.
%   See file 'help.txt' for complete game information.

% FOR EDITING PURPOSES:
%   The nesting order of functions is as follows:
%
%   staker
%      initialize_intro
%         callback_intro
%      initialize_main
%         update_main
%         callback_main
%         initialize_profile
%            update_profile
%            callback_profile
%            create_profile
%               callback_create
%            shop_armory
%               callback_shop
%         edit_preferences
%            callback_edit
%      generate_terrain
%         add_terrain
%      initialize_game
%         update_game
%         callback_game
%            update_barrel
%         resize_game
%         mouse_game
%            activate_mouse
%            track_mouse
%            update_pointer
%         generate_terrain_edges
%         update_limits
%         update_controls
%         update_compass
%         post_message
%         render_bomb
%            render_explosion
%         end_game
%            callback_end
%         display_quit
%            callback_quit
%      display_help
%         callback_help
%      bomb_error
%         callback_error
%      add_game_data
%      update_game_data
%      reset_game_data
%      game2str
%      num2arsenal
%      make_axes
%      make_button
%      make_check
%      make_edit
%      make_figure
%      make_list
%      make_menu
%      make_panel
%      make_slider
%      make_text
%      plot_line
%      plot_patch
%      plot_surface
%      plot_text
%      default_preferences
%      default_player_data
%   initialize_bomb_data
%   staker_data
%   air_density
%   water_density
%   num2money
%   str2rgb
%   within_axes
%   normrand
%   unit
%   cross
%   rotation_matrix
%   make_filter
%   filter_image
%   resize_mask
%   dilate_mask
%
% Author: Ken Eaton
% Last modified: 12/22/08
%--------------------------------------------------------------------------

  % Make sure Staker hasn't been started yet:

  currentSetting = get(0,'ShowHiddenHandles');
  set(0,'ShowHiddenHandles','on');
  if (~isempty(findobj('Tag','STAKER_INTRO','-or','Tag','STAKER_MAIN'))),
    disp('Staker has already been started.');
    set(0,'ShowHiddenHandles',currentSetting);
    return;
  end
  set(0,'ShowHiddenHandles',currentSetting);

  % Initialize constants shared across nested functions:

  BOMB_VERSION = '0.6';
  MAX_CHARS = 23;
  MAX_PLAYERS = 2;
  BOMB_DATA = initialize_bomb_data;
  N_BOMBS = length(BOMB_DATA);
  MAX_BOMBS = 20;
  LOCATION_LIST = {'Highlands'};
  N_MAP = 101;
  MAP_LIMIT = 16000; % ft
  HORIZON_LIMIT = 10*MAP_LIMIT; % ft
  MAP_DELTA = 2*MAP_LIMIT/(N_MAP-1); % ft
  MIN_HEIGHT = -5000; % ft
  MAX_HEIGHT = 29000; % ft (above sea level)
  SLOPE_LIMIT = 1; % ft/ft
  TREE_LINE = 10000; % ft (above sea level)
  SNOW_LINE = 18000; % ft (above sea level)
  MIN_ORBIT_ANGLE = pi/40; % radians
  MAX_ORBIT_ANGLE = 19*pi/40; % radians
  MAX_ROTATION_ANGLE = atan(MAP_LIMIT/(sqrt(3)*(MAP_LIMIT+50))); % radians
  CAMERA_RADIUS = 2*MAP_LIMIT/sin(MAX_ROTATION_ANGLE); % ft
  MIN_VIEW_ANGLE = 1; % degrees
  MAX_VIEW_ANGLE = 30; % degrees
  CAMERA_DEFAULT = {CAMERA_RADIUS.*...
                    [sqrt(2).*cos(pi/12).*[-0.5 -0.5] sin(pi/12)],...
                    CAMERA_RADIUS.*sqrt(1-cos(0.1)).*...
                    [sin(pi/12-0.05).*[1 1] sqrt(2)*cos(pi/12-0.05)],...
                    [sqrt(2).*sin(pi/12-0.1).*[0.5 0.5] cos(pi/12-0.1)],...
                    MAX_VIEW_ANGLE};
  MAX_MUZZLE_VELOCITY = 3000; % ft/sec
  G = [0 0 -32.17405]; % ft/sec^2
  MAX_DELTA_T = 0.25*MAP_DELTA/MAX_MUZZLE_VELOCITY; % sec
  SCALE_DELTA_T = 0.25;
  N_BLAST = 50;
  N_IMAGE = 1000;
  N_PIXELS = N_IMAGE^2;
  SCREEN_SIZE = get(0,'ScreenSize');
  [stackTrace,stackIndex] = dbstack('-completenames');
  STAKER_PATH = fileparts(stackTrace(stackIndex).file);
  TEXTURE_PATH = fullfile(STAKER_PATH,'textures');
  STATUS_FILE = fullfile(STAKER_PATH,'status.stkr');
  STATUS_FIELDS = {'version'; 'preferences'; 'suspendedGames'; ...
                   'nGamesPlayed'};
  PROFILE_FIELDS = {'version'; 'ID'; 'file'; 'name'; 'earnings'; ...
                    'record'; 'class'; 'unlocked'; 'arsenal'; 'used'; ...
                    'isCurrent'; 'capacity'; 'position'; 'settings'; ...
                    'camera'};

  % Initialize variables shared across nested functions:

  currentGame = 0;
  profiles = cell(1,MAX_PLAYERS);
  players = [];
  nPlayers = 0;
  currentPlayer = 0;
  nMoves = 0;
  hMain = [];
  updateMainFcn = [];
  hGame = [];
  updateGameFcn = [];
  locationIndex = 1;
  locationValue = [];
  mapGenerationState = [];
  mapX = [];
  mapY = [];
  mapZ = [];
  mapC = [];
  horizonZ = [];
  edgeColor = [];
  isWater = false;
  waterLevel = [];
  windVector = [];
  timeOfDay = [];

  % Initialize game status and preferences:

  rand('twister',sum(100.*clock));
  if exist(STATUS_FILE,'file'),
    try
      status = load(STATUS_FILE,'-mat');
    catch
      bomb_error([],'corruptedFile','status.stkr');
      return;
    end
    if (~isequal(fieldnames(status),STATUS_FIELDS)),
      bomb_error([],'badFileContents','status.stkr','.stkr');
      return;
    end
  else
    status = struct('version',BOMB_VERSION,...
                    'preferences',default_preferences,...
                    'suspendedGames',[],'nGamesPlayed',0);
    save(STATUS_FILE,'-struct','status','-mat');
  end
  fontName = status.preferences.fontName;
  fontSize = status.preferences.fontSize;
  textColor = status.preferences.textColor;
  backColor = status.preferences.backColor;
  panelColor = status.preferences.panelColor;
  accentColor = status.preferences.accentColor;
  sliderColor = status.preferences.sliderColor;
  azimuthGain = status.preferences.azimuthGain;
  elevationGain = status.preferences.elevationGain;
  rotationGain = status.preferences.rotationGain;
  zoomGain = status.preferences.zoomGain;
  useLocalTime = status.preferences.useLocalTime;
  trajectoryStep = status.preferences.trajectoryStep;
  blastStep = status.preferences.blastStep;

  % Display game introduction:

  initialize_intro;

%~~~Begin nested functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  %------------------------------------------------------------------------
  function initialize_intro
  %
  %   Initializes the introduction figure window.
  %
  %------------------------------------------------------------------------

    % Create introduction text:

    introText = {'"A new start..."','',...
                 ['   In a not-too-distant, clich',char(233),' ',...
                  'future, the Earth becomes uninhabitable. Desperate ',...
                  'to survive, humans spread throughout the solar ',...
                  'system, forming colonies on Mars, Europa, and ',...
                  'numerous other worlds. With time, the Earth once ',...
                  'again becomes suitable for life, and so begins the ',...
                  'rush to recolonize! Numerous government, ',...
                  'corporate, and freelance organizations fight to ',...
                  'stake their claim, battling tooth and nail to ',...
                  'secure any and all plots of land they can.'],'',...
                 'Do you have the skill to win back the world?'};

    % Create introduction figure window:

    hFigure = make_figure([1+(SCREEN_SIZE(3:4)-[300 300])./2 300 300],...
                          'CloseRequestFcn',@callback_intro,...
                          'Name',['Staker v',BOMB_VERSION],...
                          'Tag','STAKER_INTRO');

    % Create uicontrol objects:

    make_panel(hFigure,[1 1 300 300]);
    make_panel(hFigure,[10 45 282 247],'BackgroundColor',backColor,...
               'BorderType','beveledin');
    hText = make_text(hFigure,[11 46 280 245],...
                      'BackgroundColor',backColor,'FontWeight','normal',...
                      'String','');
    introText = textwrap(hText,introText);
    introText = sprintf('%s\n',introText{:});
    make_button(hFigure,[216 11 75 25],'Callback',@callback_intro,...
                'String','Continue','Tag','CONTINUE');
    timerIntro = timer('BusyMode','queue','ExecutionMode','fixedRate',...
                       'ObjectVisibility','off','Period',0.05,...
                       'Tag','TIMER','TasksToExecute',length(introText),...
                       'TimerFcn',@callback_intro);

    % Start introduction:

    set(hFigure,'Visible','on');
    drawnow;
    start(timerIntro);

    %----------------------------------------------------------------------
    function callback_intro(source,event)
    %
    %   Callback function for introduction uicontrols.
    %
    %----------------------------------------------------------------------

      switch get(source,'Tag'),

        case {'CONTINUE','STAKER_INTRO'},

          stop(timerIntro);
          delete(timerIntro);
          delete(hFigure);
          drawnow;
          initialize_main;
          set(hMain,'Visible','on');
          drawnow;

        case 'TIMER',

          set(hText,'String',introText(1:get(timerIntro,'TasksExecuted')));
          drawnow;

      end

    end

  end

  %------------------------------------------------------------------------
  function initialize_main
  %
  %   Initializes the main menu figure window.
  %
  %------------------------------------------------------------------------

    % Create main menu figure window:

    updateMainFcn = @update_main;
    hMain = make_figure([1+(SCREEN_SIZE(3:4)-[390 445])./2 390 445],...
                        'CloseRequestFcn',@callback_main,...
                        'Name',['Staker v',BOMB_VERSION,' Main Menu'],...
                        'Tag','STAKER_MAIN');

    % Create suspended game panel:

    make_panel(hMain,[1 386 390 60]);
    make_text(hMain,[11 416 140 20],'String','Suspended games:');
    hSuspended = make_menu(hMain,[21 396 350 20],...
                           'Callback',@callback_main,...
                           'String',[{'none'}; game2str],...
                           'Tag','SUSPENDED');

    % Create location panel:

    make_panel(hMain,[1 326 390 60]);
    make_text(hMain,[11 356 140 20],'String','Location:');
    hLocation = make_menu(hMain,[21 336 100 20],...
                          'Callback',@callback_main,...
                          'String',[{'none'; 'random'}; LOCATION_LIST],...
                          'Tag','LOCATION');

    % Create profile panel:

    make_panel(hMain,[1 46 390 280]);
    make_text(hMain,[11 296 140 20],'String','Player profiles:');
    updateProfileFcns = cell(1,MAX_PLAYERS);
    initialize_profile(1);
    initialize_profile(2);

    % Create button panel:

    make_panel(hMain,[1 1 390 45]);
    make_button(hMain,[11 11 50 25],'Callback',@callback_main,...
                'String','Help','Tag','HELP');
    make_button(hMain,[71 11 95 25],'Callback',@callback_main,...
                'String','Preferences','Tag','PREFERENCES');
    make_button(hMain,[271 11 50 25],'Callback',@callback_main,...
                'String','Quit','Tag','QUIT');
    hStart = make_button(hMain,[331 11 50 25],'Callback',@callback_main,...
                         'Enable','off','String','Start','Tag','START');

    %----------------------------------------------------------------------
    function update_main
    %
    %   Update function for main menu.
    %
    %----------------------------------------------------------------------

      set(hSuspended,'String',[{'none'}; game2str],'Value',currentGame+1);
      if (currentGame == 0),
        set(hLocation,'Enable','on','Value',locationIndex);
        updateProfileFcns{1}(profiles{1});
        updateProfileFcns{2}(profiles{2});
        if ((locationIndex == 1) || any(cellfun('isempty',profiles))),
          set(hStart,'Enable','off');
        else
          set(hStart,'Enable','on');
        end
      else
        gameData = status.suspendedGames(currentGame);
        set(hLocation,'Enable','off','Value',gameData.locationIndex+2);
        updateProfileFcns{1}(gameData.players(1));
        updateProfileFcns{2}(gameData.players(2));
        set(hStart,'Enable','on');
      end

    end

    %----------------------------------------------------------------------
    function callback_main(source,event)
    %
    %   Callback function for main menu uicontrols.
    %
    %----------------------------------------------------------------------

      switch get(source,'Tag'),

        case 'HELP',

          display_help(hMain);

        case 'LOCATION',

          locationIndex = get(source,'Value');
          if ((locationIndex == 1) || any(cellfun('isempty',profiles))),
            set(hStart,'Enable','off');
          else
            set(hStart,'Enable','on');
          end
          drawnow;

        case 'PREFERENCES',

          edit_preferences;

        case {'QUIT','STAKER_MAIN'},

          delete(hMain);
          delete(hGame);
          drawnow;

        case 'START',

          set(hMain,'Pointer','watch');
          drawnow;
          if (currentGame == 0),
            players = [profiles{:}];
            nPlayers = length(players);
            players = players(randperm(nPlayers));
            currentPlayer = 1;
            players(1).isCurrent = true;
            nMoves = 0;
            generate_terrain;
            add_game_data;
            currentGame = length(status.suspendedGames);
            save(STATUS_FILE,'-struct','status','-mat');
            for i = 1:nPlayers,
              delete(players(i).file);
            end
          else
            gameData = status.suspendedGames(currentGame);
            players = gameData.players;
            nPlayers = length(players);
            currentPlayer = gameData.currentPlayer;
            nMoves = gameData.nMoves;
            locationIndex = gameData.locationIndex;
            locationValue = gameData.locationValue;
            mapGenerationState = gameData.mapGenerationState;
            mapZ = gameData.mapZ;
            mapC = gameData.mapC;
            horizonZ = gameData.horizonZ;
            edgeColor = gameData.edgeColor;
            isWater = gameData.isWater;
            waterLevel = gameData.waterLevel;
            windVector = gameData.windVector;
            timeOfDay = gameData.timeOfDay;
            generate_terrain;
            status.suspendedGames(currentGame).lastPlayed = clock;
          end
          if ishandle(hGame),
            updateGameFcn();
          else
            initialize_game;
          end
          set(hMain,'Pointer','arrow','Visible','off');
          set(hGame,'Visible','on');
          drawnow;

        case 'SUSPENDED',

          currentGame = get(source,'Value')-1;
          if (currentGame == 0),
            set(hLocation,'Enable','on','Value',locationIndex);
            updateProfileFcns{1}(profiles{1});
            updateProfileFcns{2}(profiles{2});
            if ((locationIndex == 1) || any(cellfun('isempty',profiles))),
              set(hStart,'Enable','off');
            else
              set(hStart,'Enable','on');
            end
          else
            gameData = status.suspendedGames(currentGame);
            set(hLocation,'Enable','off','Value',gameData.locationIndex+2);
            updateProfileFcns{1}(gameData.players(1));
            updateProfileFcns{2}(gameData.players(2));
            set(hStart,'Enable','on');
          end
          drawnow;

      end

    end

    %----------------------------------------------------------------------
    function initialize_profile(panelIndex)
    %
    %   Initializes a profile panel in the main menu figure window.
    %
    %----------------------------------------------------------------------

      % Create profile panel:

      updateProfileFcns{panelIndex} = @update_profile;
      hProfile = make_panel(hMain,[11+190*(panelIndex-1) 56 180 240],...
                            'BackgroundColor',accentColor);
      position = [5 215 170 20];
      hFile = make_text(hProfile,position,'BackgroundColor',accentColor,...
                        'FontWeight','normal',...
                        'HorizontalAlignment','center',...
                        'String','no profile');
      extent = get(hFile,'Extent');
      set(hFile,'Position',...
          [position(1:2)+(position(3:4)-extent(3:4))./2 extent(3:4)]);
      make_panel(hProfile,[5 228 170 1],'BorderType','line',...
                 'HighlightColor',textColor);

      % Create uicontrols for empty panel:

      hCreate = make_button(hProfile,[5 190 120 25],...
                            'Callback',@callback_profile,...
                            'String','Create Profile','Tag','CREATE');
      hSelect = make_button(hProfile,[5 160 120 25],...
                            'Callback',@callback_profile,...
                            'String','Select Profile','Tag','SELECT');
      hComputer = make_button(hProfile,[5 130 80 25],...
                              'Callback',@callback_profile,...
                              'Enable','off','String','Computer',...
                              'Tag','COMPUTER');

      % Create uicontrols for panel containing a profile:

      hAxes = make_axes(hProfile,[5 205 30 10]);
      hPointer = plot_patch(hAxes,[0 0.5 1],[1 0 1],[1 0 0],...
                            'Visible','off');
      hPlayer = make_text(hProfile,[5 185 170 20],...
                          'BackgroundColor',accentColor,...
                          'FontSize',2*fontSize,'FontWeight','normal',...
                          'Visible','off');
      hAxes = make_axes(hProfile,[5 165 170 15]);
      xData = [0 1 2 3; 1 2 3 4; 1 2 3 4; 0 1 2 3]./4;
      hCapacity = [plot_patch(hAxes,[0 1 1 0],[0 0 1 1],[0 1 0],...
                              'Visible','off') ...
                   plot_patch(hAxes,xData,[zeros(2,4); ones(2,4)],...
                              'none','EdgeColor',[0 0 0],'Visible','off')];
      hData = make_text(hProfile,[5 105 170 50],...
                        'BackgroundColor',accentColor,...
                        'FontWeight','normal','Visible','off');
      hPanel = make_panel(hProfile,[19 34 142 67],...
                          'BackgroundColor',backColor,...
                          'BorderType','beveledin','Visible','off');
      hArsenal = make_text(hProfile,[20 35 130 65],...
                           'BackgroundColor',backColor,...
                           'FontWeight','normal','Visible','off');
      hSlider = make_slider(hProfile,[150 35 10 65],...
                            'Callback',@callback_profile,'Enable','off',...
                            'Tag','SLIDER','Value',1,'Visible','off');
      hShop = make_button(hProfile,[30 5 50 25],...
                          'Callback',@callback_profile,'String','Shop',...
                          'Tag','SHOP','Visible','off');
      hRemove = make_button(hProfile,[90 5 60 25],...
                            'Callback',@callback_profile,...
                            'String','Remove','Tag','REMOVE',...
                            'Visible','off');

      %--------------------------------------------------------------------
      function update_profile(newProfile)
      %
      %   Update function for profile panel.
      %
      %--------------------------------------------------------------------

        if isempty(newProfile),

          % Clear profile panel:

          set(hFile,'String','no profile');
          position = get(hFile,'Position');
          extent = get(hFile,'Extent');
          set(hFile,'Position',...
              [position(1:2)+(position(3:4)-extent(3:4))./2 extent(3:4)]);
          set([hPointer hPlayer hCapacity hData hPanel hArsenal hSlider ...
               hShop hRemove],'Visible','off');
          set([hCreate hSelect hComputer],'Visible','on');

        else

          % Update profile panel:

          [filePath,fileName,fileExt] = fileparts(newProfile.file);
          set(hFile,'String',[fileName,fileExt]);
          position = get(hFile,'Position');
          extent = get(hFile,'Extent');
          set(hFile,'Position',...
              [position(1:2)+(position(3:4)-extent(3:4))./2 extent(3:4)]);
          if (newProfile.isCurrent),
            set(hPointer,'Visible','on');
          else
            set(hPointer,'Visible','off');
          end
          set(hPlayer,'String',newProfile.name);
          capacity = newProfile.capacity;
          set(hCapacity(1),...
              'FaceColor',min([2-(capacity/50) (capacity/50) 0],1),...
              'XData',[0 0.01 0.01 0].*capacity);
          earnings = num2money(newProfile.earnings);
          stats = sprintf('%i%c',[newProfile.record; 45 45 32]);
          set(hData,'String',{['Earnings: ',earnings]; ...
                              ['Record: ',stats]; ...
                              ['Staker class: ',newProfile.class]; ...
                              'Arsenal:'});
          arsenal = num2arsenal(newProfile.arsenal);
          set(hArsenal,'String',arsenal,'UserData',arsenal);
          if (length(arsenal) > 1),
            nBombs = length(arsenal)-1;
            set(hSlider,'Enable','on','Max',nBombs,...
                'SliderStep',[1 3]./nBombs,'Value',nBombs);
          else
            set(hSlider,'Enable','off','Max',1,'SliderStep',[1 3],...
                'Value',1);
          end
          set([hCreate hSelect hComputer],'Visible','off');
          set([hPlayer hCapacity hData hPanel hArsenal hSlider],...
              'Visible','on');
          if (currentGame == 0),
            set([hShop hRemove],'Visible','on');
          else
            set([hShop hRemove],'Visible','off');
          end

        end

      end

      %--------------------------------------------------------------------
      function callback_profile(source,event)
      %
      %   Callback function for profile panel uicontrols.
      %
      %--------------------------------------------------------------------

        % Make new profile:

        switch get(source,'Tag'),

          case 'CREATE',

            newProfile = create_profile;

          case 'REMOVE',

            newProfile = [];

          case 'SELECT',

            filePath = fullfile(STAKER_PATH,filesep);
            [fileName,filePath,fileIndex] = uigetfile('*.prof',...
                                                      'Select profile',...
                                                      filePath);
            if (isequal(fileName,0) || isequal(filePath,0)),
              return;
            end
            if (fileIndex > 1),
              bomb_error(hMain,'wrongExtension','Load','.prof');
              return;
            end
            filePath = fullfile(filePath,fileName);
            try
              newProfile = load(filePath,'-mat');
            catch
              bomb_error(hMain,'corruptedFile',fileName);
              return;
            end
            if (~isequal(fieldnames(newProfile),PROFILE_FIELDS)),
              bomb_error(hMain,'badFileContents',fileName,'.prof');
              return;
            end
            if any(~cellfun('isempty',profiles)),
              loaded = [profiles{:}];
              if ismember(newProfile.ID,[loaded.ID]),
                bomb_error(hMain,'duplicateProfile',fileName);
                return;
              end
            end
            if (~isempty(status.suspendedGames)),
              loaded = [status.suspendedGames.players];
              if ismember(newProfile.ID,[loaded.ID]),
                bomb_error(hMain,'duplicateProfile',fileName);
                return;
              end
            end
            newProfile.file = filePath;

          case 'SHOP',

            newProfile = shop_armory(profiles{panelIndex});

          case 'SLIDER',

            arsenal = get(hArsenal,'UserData');
            nBombs = length(arsenal);
            arsenalIndex = nBombs-round(get(source,'Value'));
            set(hArsenal,'String',arsenal(arsenalIndex:nBombs));
            drawnow;
            return;

        end

        % Update profile panel:

        profiles{panelIndex} = newProfile;
        update_profile(newProfile);
        if ((locationIndex == 1) || any(cellfun('isempty',profiles))),
          set(hStart,'Enable','off');
        else
          set(hStart,'Enable','on');
        end
        drawnow;

      end

      %--------------------------------------------------------------------
      function newProfile = create_profile
      %
      %   Opens a modal window for creating a new profile.
      %
      %--------------------------------------------------------------------

        % Initialize profile information:

        newProfile = default_player_data;

        % Create modal figure window:

        position = get(hMain,'Position');
        position = [position(1:2)+(position(3:4)-[200 95])./2 200 95];
        hModal = make_figure(position,...
                             'CloseRequestFcn',@callback_create,...
                             'Name','Create Profile','Tag','FIGURE',...
                             'WindowStyle','modal');

        % Create uicontrol objects:

        make_panel(hModal,[1 1 200 95]);
        make_text(hModal,[11 66 180 20],'String','Player name:');
        hName = make_edit(hModal,[21 46 170 20],...
                          'HorizontalAlignment','left','String','');
        make_button(hModal,[71 11 50 25],'Callback',@callback_create,...
                    'String','Save','Tag','SAVE');
        make_button(hModal,[131 11 60 25],'Callback',@callback_create,...
                    'String','Cancel','Tag','CANCEL');

        % Wait for window to be closed:

        set(hModal,'Visible','on');
        drawnow;
        waitfor(hModal);

        %------------------------------------------------------------------
        function callback_create(source,event)
        %
        %   Callback function for profile creation uicontrols.
        %
        %------------------------------------------------------------------

          switch get(source,'Tag'),

            case {'CANCEL','FIGURE'},

              newProfile = [];

            case 'SAVE',

              name = get(hName,'String');
              if isempty(name),
                bomb_error(hMain,'emptyString','Player name');
                return;
              elseif (length(name) > MAX_CHARS),
                bomb_error(hMain,'oversizedString','Player name');
                return;
              end
              filePath = fullfile(STAKER_PATH,[name,'.prof']);
              [fileName,filePath,fileIndex] = uiputfile('*.prof',...
                                                        'Save profile',...
                                                        filePath);
              if (isequal(fileName,0) || isequal(filePath,0)),
                return;
              end
              if (fileIndex > 1),
                bomb_error(hMain,'wrongExtension','Save','.prof');
                return;
              end
              newProfile.file = fullfile(filePath,fileName);
              newProfile.name = name;
              save(newProfile.file,'-struct','newProfile','-mat');

          end
          delete(hModal);
          drawnow;

        end

      end

      %--------------------------------------------------------------------
      function customer = shop_armory(customer)
      %
      %   Opens a modal window for shopping at the armory.
      %
      %--------------------------------------------------------------------

        % Initialize variables:

        shopLogo = flipdim(imread(fullfile(TEXTURE_PATH,...
                                           'shoplogo.bmp')),1);
        bombIndex = ~(customer.unlocked);
        inventory = {BOMB_DATA.name};
        inventory(bombIndex) = {'???'};
        inventory = reshape(sprintf('%11.10s',inventory{:}),11,N_BOMBS).';
        bombCosts = cellfun(@num2money,{BOMB_DATA.cost}.',...
                            'UniformOutput',false);
        bombCosts(bombIndex) = {'$???'};
        inventory = strcat(inventory,{' = '},bombCosts);
        isBuying = true;
        price = 0;

        % Create modal figure window:

        position = get(hMain,'Position');
        position = [position(1:2)+(position(3:4)-[530 350])./2 530 350];
        hModal = make_figure(position,'CloseRequestFcn',@callback_shop,...
                             'Name','Armory','Tag','STAKER_SHOP',...
                             'WindowStyle','modal');

        % Create logo panel:

        make_panel(hModal,[1 251 190 100]);
        hAxes = make_axes(hModal,[6 255 180 90],'XLim',[0 180],...
                          'YLim',[0 90]);
        plot_surface(hAxes,[0 180; 0 180],[0 0; 90 90],zeros(2),shopLogo);

        % Create customer panel:

        make_panel(hModal,[1 46 190 205]);
        make_text(hModal,[11 226 170 15],'String','Customer:');
        make_text(hModal,[11 206 170 20],'FontSize',2*fontSize,...
                  'FontWeight','normal','String',customer.name);
        make_text(hModal,[16 176 160 23],'FontWeight','normal',...
                  'String',{['Staker class: ',customer.class]; ...
                            'Current arsenal:'});
        hCurrent = make_list(hModal,[16 101 160 70],...
                             'Callback',@callback_shop,...
                             'String',num2arsenal(customer.arsenal),...
                             'Tag','CURRENT');
        make_text(hModal,[11 76 170 15],'String','Available funds:');
        make_panel(hModal,[61 56 120 20],'BackgroundColor',backColor,...
                   'BorderType','beveledin');
        hFunds = make_text(hModal,[62 57 113 14],...
                           'BackgroundColor',backColor,...
                           'FontWeight','normal',...
                           'HorizontalAlignment','right',...
                           'String',num2money(customer.earnings),...
                           'Value',customer.earnings);
        if (customer.earnings <= 0),
          set(hFunds,'ForegroundColor',[0.7 0 0]);
        end

        % Create description panel:

        make_panel(hModal,[191 181 340 170]);
        make_text(hModal,[201 325 200 15],'String','Weapon description:');
        make_panel(hModal,[200 190 322 135],'BackgroundColor',backColor,...
                   'BorderType','beveledin');
        hDescription = make_text(hModal,[201 191 320 133],...
                                 'BackgroundColor',backColor,...
                                 'FontWeight','normal',...
                                 'String','(select munition below)');

        % Create weapon inventory panel:

        make_panel(hModal,[311 46 220 135]);
        make_text(hModal,[321 156 200 15],'String','Available weapons:');
        hAvailable = make_list(hModal,[321 56 200 100],...
                               'Callback',@callback_shop,...
                               'String',inventory,'Tag','AVAILABLE');

        % Create total panel:

        make_panel(hModal,[191 46 120 135]);
        make_text(hModal,[201 156 100 15],'String','Price:');
        hPrice = make_text(hModal,[201 141 100 15],...
                           'HorizontalAlignment','right','String','$0');
        make_text(hModal,[231 121 20 15],'FontSize',2*fontSize,...
                  'FontWeight','normal','String',char(215));
        hMultiplier = make_edit(hModal,[251 111 30 28],...
                                'Callback',@callback_shop,...
                                'Enable','off','Min',MAX_BOMBS,...
                                'String','1','Tag','MULTIPLIER');
        hUp = make_button(hModal,[281 125 20 14],...
                          'Callback',@callback_shop,'Enable','off',...
                          'FontWeight','bold','String','+','Tag','UP');
        hDown = make_button(hModal,[281 111 20 14],...
                            'Callback',@callback_shop,'Enable','off',...
                            'FontWeight','bold','String','-','Tag','DOWN');
        make_panel(hModal,[201 106 100 1],'BorderType','line',...
                   'HighlightColor',textColor);
        hTotal = make_text(hModal,[201 86 100 15],...
                           'HorizontalAlignment','right','String','$0');
        hBuyOrSell = make_button(hModal,[226 56 50 25],...
                                 'Callback',@callback_shop,...
                                 'Enable','off','String','Buy',...
                                 'Tag','BUYORSELL');

        % Create button panel:

        make_panel(hModal,[1 1 530 45]);
        make_button(hModal,[11 11 50 25],'Callback',@callback_shop,...
                    'String','Help','Tag','HELP');
        make_button(hModal,[470 11 50 25],'Callback',@callback_shop,...
                    'String','Exit','Tag','EXIT');

        % Wait for window to be closed:

        set(hModal,'Visible','on');
        drawnow;
        waitfor(hModal);

        %------------------------------------------------------------------
        function callback_shop(source,event)
        %
        %   Callback function for armory uicontrols.
        %
        %------------------------------------------------------------------

          switch get(source,'Tag'),

            case 'AVAILABLE',

              isBuying = true;
              value = get(hAvailable,'Value');
              bombList = get(hAvailable,'String');
              bombName = strtrim(strtok(bombList{value},'='));
              if strcmp(bombName,'???'),
                set(hDescription,'String','???: (unavailable)');
                set([hPrice hTotal],'String','$0');
                set(hMultiplier,'Enable','off','String','1');
                set([hUp hDown],'Enable','off');
                set(hBuyOrSell,'Enable','off','String','Buy');
              else
                bombIndex = find(strcmp({BOMB_DATA.name},bombName));
                bombText = {[bombName,':'],...
                            ['   ',BOMB_DATA(bombIndex).description]};
                set(hDescription,'String',textwrap(hDescription,bombText));
                price = BOMB_DATA(bombIndex).cost;
                set([hPrice hTotal],'String',num2money(price));
                if (value == 1),
                  maxValue = 0;
                else
                  maxValue = min(MAX_BOMBS-customer.arsenal(bombIndex),...
                                 floor(get(hFunds,'Value')/price));
                end
                if (maxValue <= 0),
                  set(hMultiplier,'Enable','off','String','1');
                  set([hUp hDown],'Enable','off');
                  set(hBuyOrSell,'Enable','off','String','Buy');
                else
                  set(hMultiplier,'Max',maxValue,'String','1','Value',1);
                  if (maxValue > 1),
                    set([hMultiplier hUp],'Enable','on');
                  else
                    set([hMultiplier hUp],'Enable','off');
                  end
                  set(hDown,'Enable','off');
                  set(hBuyOrSell,'Enable','on','String','Buy');
                end
              end
              drawnow;

            case 'BUYORSELL',

              value = get(hMultiplier,'Value');
              if isBuying,
                customer.arsenal(bombIndex) = ...
                  customer.arsenal(bombIndex)+value;
                funds = customer.earnings-value*price;
                if (funds <= 0),
                  set(hFunds,'ForegroundColor',[0.7 0 0]);
                end
              else
                customer.arsenal(bombIndex) = ...
                  customer.arsenal(bombIndex)-value;
                funds = customer.earnings+value*price;
                if (funds > 0),
                  set(hFunds,'ForegroundColor',textColor);
                end
              end
              customer.earnings = funds;
              set(hFunds,'String',num2money(funds),'Value',funds);
              maxValue = get(hMultiplier,'Max')-value;
              if (maxValue > 0),
                value = min(value,maxValue);
                set(hMultiplier,'Max',maxValue,'String',num2str(value),...
                    'Value',value);
                if (value == maxValue),
                  set(hUp,'Enable','off');
                end
                if (value == 1),
                  set(hDown,'Enable','off');
                end
                set(hTotal,'String',num2money(value*price));
              else
                if isBuying,
                  set(hTotal,'String',num2money(price));
                else
                  if (sum(customer.arsenal > 0) < get(hCurrent,'Value')),
                    set(hCurrent,'Value',1);
                  end
                  set(hDescription,'String','(select munition below)');
                  set([hPrice hTotal],'String','$0');
                end
                set(hMultiplier,'Enable','off','String','1');
                set([hUp hDown],'Enable','off');
                set(hBuyOrSell,'Enable','off');
              end
              set(hCurrent,'String',num2arsenal(customer.arsenal));
              drawnow;

            case 'CURRENT',

              isBuying = false;
              value = get(hCurrent,'Value');
              bombList = get(hCurrent,'String');
              bombName = strtrim(strtok(bombList{value},'-'));
              bombIndex = find(strcmp({BOMB_DATA.name},bombName));
              bombText = {[bombName,':'],...
                          ['   ',BOMB_DATA(bombIndex).description]};
              set(hDescription,'String',textwrap(hDescription,bombText));
              price = (BOMB_DATA(bombIndex).cost)/2;
              set([hPrice hTotal],'String',num2money(price));
              value = customer.arsenal(bombIndex);
              if isfinite(value),
                set(hMultiplier,'Max',value,'String','1','Value',1);
                if (value > 1),
                  set([hMultiplier hUp],'Enable','on');
                else
                  set([hMultiplier hUp],'Enable','off');
                end
                set(hDown,'Enable','off');
                set(hBuyOrSell,'Enable','on','String','Sell');
              else
                set(hMultiplier,'Enable','off','String','1');
                set([hUp hDown],'Enable','off');
                set(hBuyOrSell,'Enable','off','String','Sell');
              end
              drawnow;

            case 'DOWN',

              value = get(hMultiplier,'Value')-1;
              set(hMultiplier,'String',num2str(value),'Value',value);
              set(hUp,'Enable','on');
              if (value == 1),
                set(hDown,'Enable','off');
              end
              set(hTotal,'String',num2money(value*price));
              drawnow;

            case {'EXIT','STAKER_SHOP'},

              save(customer.file,'-struct','customer','-mat');
              delete(hModal);
              drawnow;

            case 'HELP',

              display_help(hModal);

            case 'MULTIPLIER',

              value = str2double(get(hMultiplier,'String'));
              if isnan(value),
                value = get(hMultiplier,'Value');
                bomb_error(hModal,'invalidValue','multiplier');
              else
                maxValue = get(hMultiplier,'Max');
                value = max(min(round(value),maxValue),1);
                if (value == maxValue),
                  set(hUp,'Enable','off');
                end
                if (value == 1),
                  set(hDown,'Enable','off');
                end
              end
              set(hMultiplier,'String',num2str(value),'Value',value);
              set(hTotal,'String',num2money(value*price));
              drawnow;

            case 'UP',

              value = get(hMultiplier,'Value')+1;
              set(hMultiplier,'String',num2str(value),'Value',value);
              if (value == get(hMultiplier,'Max')),
                set(hUp,'Enable','off');
              end
              set(hDown,'Enable','on');
              set(hTotal,'String',num2money(value*price));
              drawnow;

          end

        end

      end

    end

    %----------------------------------------------------------------------
    function edit_preferences
    %
    %   Opens a modal window for editing preferences.
    %
    %----------------------------------------------------------------------

      % Initialize variables:

      oldPreferences = status.preferences;
      newPreferences = oldPreferences;

      % Create modal figure window:

      position = get(hMain,'Position');
      position = [position(1:2)+(position(3:4)-[450 445])./2 450 445];
      hModal = make_figure(position,'CloseRequestFcn',@callback_edit,...
                           'Name','Preferences',...
                           'Tag','STAKER_PREFERENCES',...
                           'WindowStyle','modal');

      % Create font preferences panel:

      make_panel(hModal,[1 361 450 85]);
      make_text(hModal,[11 421 100 15],'String','Font:');
      make_text(hModal,[11 401 130 15],'HorizontalAlignment','right',...
                'String','Font name =');
      hFontName = make_edit(hModal,[151 401 130 20],...
                            'Callback',@callback_edit,'String',fontName,...
                            'Tag','FONT_NAME');
      make_text(hModal,[11 371 130 15],'HorizontalAlignment','right',...
                'String','Font size =');
      hFontSize = make_edit(hModal,[151 371 50 20],...
                            'Callback',@callback_edit,...
                            'String',num2str(fontSize),'Tag','FONT_SIZE');
      make_text(hModal,[301 406 130 15],'String','sample:');
      hFont = make_text(hModal,[301 371 130 30],'FontWeight','normal',...
                        'String','Can you read this?');

      % Create color preferences panel:

      make_panel(hModal,[1 186 450 175]);
      make_text(hModal,[11 336 100 15],'String','Colors:');
      make_text(hModal,[11 316 130 15],'HorizontalAlignment','right',...
                'String','Text color =');
      hTextColor = make_edit(hModal,[151 316 130 20],...
                             'Callback',@callback_edit,...
                             'String',mat2str(textColor,2),...
                             'Tag','COLOR','UserData','textColor');
      make_text(hModal,[11 286 130 15],'HorizontalAlignment','right',...
                'String','Background color =');
      hBackColor = make_edit(hModal,[151 286 130 20],...
                             'Callback',@callback_edit,...
                             'String',mat2str(backColor,2),...
                             'Tag','COLOR','UserData','backColor');
      make_text(hModal,[11 256 130 15],'HorizontalAlignment','right',...
                'String','Panel color =');
      hPanelColor = make_edit(hModal,[151 256 130 20],...
                              'Callback',@callback_edit,...
                              'String',mat2str(panelColor,2),...
                              'Tag','COLOR','UserData','panelColor');
      make_text(hModal,[11 226 130 15],'HorizontalAlignment','right',...
                'String','Accent color =');
      hAccentColor = make_edit(hModal,[151 226 130 20],...
                               'Callback',@callback_edit,...
                               'String',mat2str(accentColor,2),...
                               'Tag','COLOR','UserData','accentColor');
      make_text(hModal,[11 196 130 15],'HorizontalAlignment','right',...
                'String','Slider color =');
      hSliderColor = make_edit(hModal,[151 196 130 20],...
                               'Callback',@callback_edit,...
                               'String',mat2str(sliderColor,2),...
                               'Tag','COLOR','UserData','sliderColor');
      make_text(hModal,[301 316 130 15],'String','sample:');
      hPanel = make_panel(hModal,[296 216 140 100]);
      hAccent = make_panel(hModal,[311 251 110 50],...
                           'BackgroundColor',accentColor);
      hText = make_text(hModal,[321 261 90 30],...
                        'BackgroundColor',backColor,...
                        'FontWeight','normal','String','Your text here');
      hSlider = make_slider(hModal,[306 226 120 10],'Max',10,...
                            'SliderStep',[0.1 0.3]);

      % Create camera preferences panel:

      make_panel(hModal,[1 101 450 85]);
      make_text(hModal,[11 161 100 15],'String','Camera:');
      make_text(hModal,[11 141 160 15],'HorizontalAlignment','right',...
                'String','Azimuth gain =');
      hAzimuth = make_edit(hModal,[181 141 60 20],...
                           'Callback',@callback_edit,...
                           'String',num2str(azimuthGain,'%0.4f'),...
                           'Tag','NUMERIC',...
                           'UserData',{'azimuthGain',0.0005,0.01});
      make_text(hModal,[11 111 160 15],'HorizontalAlignment','right',...
                'String','Elevation gain =');
      hElevation = make_edit(hModal,[181 111 60 20],...
                             'Callback',@callback_edit,...
                             'String',num2str(elevationGain,'%0.4f'),...
                             'Tag','NUMERIC',...
                             'UserData',{'elevationGain',0.0005,0.01});
      make_text(hModal,[251 141 120 15],'HorizontalAlignment','right',...
                'String','Rotation gain =');
      hRotation = make_edit(hModal,[381 141 60 20],...
                            'Callback',@callback_edit,...
                            'String',num2str(rotationGain,'%0.4f'),...
                            'Tag','NUMERIC',...
                            'UserData',{'rotationGain',0.0001,0.005});
      make_text(hModal,[251 111 120 15],'HorizontalAlignment','right',...
                'String','Zoom gain =');
      hZoom = make_edit(hModal,[381 111 60 20],...
                        'Callback',@callback_edit,...
                        'String',num2str(zoomGain,'%0.4f'),...
                        'Tag','NUMERIC',...
                        'UserData',{'zoomGain',0.001,0.01});

      % Create animation preferences panel:

      make_panel(hModal,[1 46 450 55]);
      make_text(hModal,[11 76 100 15],'String','Animation:');
      make_text(hModal,[11 56 160 15],'HorizontalAlignment','right',...
                'String','Trajectory step =');
      hTrajectory = make_edit(hModal,[181 56 60 20],...
                              'Callback',@callback_edit,...
                              'String',num2str(trajectoryStep,'%0.4f'),...
                              'Tag','NUMERIC',...
                              'UserData',{'trajectoryStep',0.001,2});
      make_text(hModal,[251 56 120 15],'HorizontalAlignment','right',...
                'String','Blast step =');
      hBlastStep = make_edit(hModal,[381 56 60 20],...
                             'Callback',@callback_edit,...
                             'String',num2str(blastStep,'%0.4f'),...
                             'Tag','NUMERIC',...
                             'UserData',{'blastStep',0.05,0.5});

      % Create button panel:

      make_panel(hModal,[1 1 450 45]);
      make_button(hModal,[11 11 50 25],'Callback',@callback_edit,...
                  'String','Help','Tag','HELP');
      make_button(hModal,[301 11 80 25],'Callback',@callback_edit,...
                  'String','Defaults','Tag','DEFAULTS');
      make_button(hModal,[391 11 50 25],'Callback',@callback_edit,...
                  'String','Done','Tag','DONE');

      % Wait for window to be closed:

      set(hModal,'Visible','on');
      drawnow;
      waitfor(hModal);

      %--------------------------------------------------------------------
      function callback_edit(source,event)
      %
      %   Callback function for preference editing uicontrols.
      %
      %--------------------------------------------------------------------

        switch get(source,'Tag'),

          case 'COLOR',

            value = str2rgb(get(source,'String'));
            fieldName = get(source,'UserData');
            switch fieldName,
              case 'textColor',
                sourceObject = {hText,'ForegroundColor'};
                sourceText = 'text color';
              case 'backColor',
                sourceObject = {hText,'BackgroundColor'};
                sourceText = 'background color';
              case 'panelColor',
                sourceObject = {hPanel,'BackgroundColor'};
                sourceText = 'panel color';
              case 'accentColor',
                sourceObject = {hAccent,'BackgroundColor'};
                sourceText = 'accent color';
              case 'sliderColor',
                sourceObject = {hSlider,'BackgroundColor'};
                sourceText = 'slider color';
            end
            if isnan(value),
              set(source,'String',mat2str(newPreferences.(fieldName),2));
              bomb_error(hModal,'invalidValue',sourceText);
            else
              set(source,'String',mat2str(value,2));
              set(sourceObject{:},value);
              newPreferences.(fieldName) = value;
              drawnow;
            end

          case 'DEFAULTS',

            newPreferences = default_preferences;
            set(hFontName,'String',newPreferences.fontName);
            set(hFontSize,'String',num2str(newPreferences.fontSize));
            set(hFont,'FontName',newPreferences.fontName,...
                'FontSize',newPreferences.fontSize);
            set(hTextColor,'String',mat2str(newPreferences.textColor,2));
            set(hBackColor,'String',mat2str(newPreferences.backColor,2));
            set(hPanelColor,'String',mat2str(newPreferences.panelColor,2));
            set(hAccentColor,...
                'String',mat2str(newPreferences.accentColor,2));
            set(hSliderColor,...
                'String',mat2str(newPreferences.sliderColor,2));
            set(hPanel,'BackgroundColor',newPreferences.panelColor);
            set(hAccent,'BackgroundColor',newPreferences.accentColor);
            set(hText,'ForegroundColor',newPreferences.textColor,...
                'BackgroundColor',newPreferences.backColor);
            set(hSlider,'BackgroundColor',newPreferences.sliderColor);
            set(hAzimuth,...
                'String',num2str(newPreferences.azimuthGain,'%0.4f'));
            set(hElevation,...
                'String',num2str(newPreferences.elevationGain,'%0.4f'));
            set(hRotation,...
                'String',num2str(newPreferences.rotationGain,'%0.4f'));
            set(hZoom,'String',num2str(newPreferences.zoomGain,'%0.4f'));
            set(hTrajectory,...
                'String',num2str(newPreferences.trajectoryStep,'%0.4f'));
            set(hBlastStep,...
                'String',num2str(newPreferences.blastStep,'%0.4f'));

          case {'DONE','STAKER_PREFERENCES'},

            delete(hModal);
            if (~isequal(oldPreferences,newPreferences)),
              delete(hGame);
              hGame = [];
              delete(hMain);
              drawnow;
              fontName = newPreferences.fontName;
              fontSize = newPreferences.fontSize;
              textColor = newPreferences.textColor;
              backColor = newPreferences.backColor;
              panelColor = newPreferences.panelColor;
              accentColor = newPreferences.accentColor;
              sliderColor = newPreferences.sliderColor;
              azimuthGain = newPreferences.azimuthGain;
              elevationGain = newPreferences.elevationGain;
              rotationGain = newPreferences.rotationGain;
              zoomGain = newPreferences.zoomGain;
              useLocalTime = newPreferences.useLocalTime;
              trajectoryStep = newPreferences.trajectoryStep;
              blastStep = newPreferences.blastStep;
              status.preferences = newPreferences;
              save(STATUS_FILE,'-struct','status','-mat');
              initialize_main;
              updateMainFcn();
              set(hMain,'Visible','on');
            end
            drawnow;

          case 'FONT_NAME',

            value = get(source,'String');
            set(hFont,'FontName',value);
            newPreferences.fontName = value;
            drawnow;

          case 'FONT_SIZE',

            value = round(str2double(get(source,'String')));
            if (isfinite(value) && (value > 0)),
              set(source,'String',num2str(value));
              set(hFont,'FontSize',value);
              newPreferences.fontSize = value;
              drawnow;
            else
              set(source,'String',num2str(newPreferences.fontSize));
              bomb_error(hModal,'invalidValue','font size');
            end

          case 'HELP',

            display_help(hModal);

          case 'NUMERIC',

            value = str2double(get(source,'String'));
            fieldData = get(source,'UserData');
            fieldName = fieldData{1};
            if isnan(value),
              set(source,'String',...
                  num2str(newPreferences.(fieldName),'%0.4f'));
              switch fieldName,
                case 'azimuthGain',
                  bomb_error(hModal,'invalidValue','azimuth gain');
                case 'elevationGain',
                  bomb_error(hModal,'invalidValue','elevation gain');
                case 'rotationGain',
                  bomb_error(hModal,'invalidValue','rotation gain');
                case 'zoomGain',
                  bomb_error(hModal,'invalidValue','zoom gain');
                case 'trajectoryStep',
                  bomb_error(hModal,'invalidValue','trajectory step');
                case 'blastStep',
                  bomb_error(hModal,'invalidValue','blast step');
              end
            else
              value = max(min(value,fieldData{3}),fieldData{2});
              set(source,'String',num2str(value,'%0.4f'));
              newPreferences.(fieldName) = value;
              drawnow;
            end

        end

      end

    end

  end

  %------------------------------------------------------------------------
  function generate_terrain
  %
  %   Generates a game terrain.
  %
  %------------------------------------------------------------------------

    if (isempty(mapX) || isempty(mapY)),
      [mapX,mapY] = meshgrid(MAP_LIMIT.*linspace(-1,1,N_MAP));
    end
    if isempty(mapZ),

      % Initialize terrain and environment variables:

      if (locationIndex == 2),
        locationIndex = round(rand*(length(LOCATION_LIST)-1))+1;
      else
        locationIndex = locationIndex-2;
      end
      mapGenerationState = rand('twister');
      switch LOCATION_LIST{locationIndex},

        case 'Highlands',

          scale = [2000 4000 400]; % Height, expanse, and steepness, in ft
          mapFill = 50*(MAP_LIMIT/(16000*N_MAP))^2;
          index = find(rand(N_MAP) < mapFill); % Obstacle positions
          nSolids = length(index);
          solidObstacles = [index ones(nSolids,1)*scale];
          nGhosts = 0;
          ghostObstacles = [];
          mapFilter = [];
          mapNoise = 200; % ft
          waterLevel = 1000; % ft
          horizonFill = 0.07;
          edgeColor = [0.45 0.45 0.5; 0.5 0.54 0.48];
          locationValue = 1.5; % dollars per billion cubic ft
          windSpeed = 30*normrand(1,-1,5)+30; % 0-180 mph
          if useLocalTime,
            timeOfDay = clock;
            timeOfDay = timeOfDay(4:6);
          else
            timeOfDay = round([23 59 59].*rand(1,3));
          end

      end
      windTheta = 2*pi*rand;
      windVector = windSpeed.*[cos(windTheta) -sin(windTheta) 0];

      % Generate terrain mesh:

      mapZ = zeros(N_MAP);
      for i = 1:nSolids,
        index = solidObstacles(i,1);
        temp = solidObstacles(i,2:4);
        distance = sqrt((mapX-mapX(index)).^2+(mapY-mapY(index)).^2);
        mapZ = mapZ+temp(1)./(1+exp((distance-temp(2))./temp(3)));
      end
      for i = 1:nGhosts,
        index = ghostObstacles(i,1);
        temp = ghostObstacles(i,2:4);
        distance = sqrt((mapX-mapX(index)).^2+(mapY-mapY(index)).^2);
        mapZ = max(mapZ,temp(1)./(1+exp((distance-temp(2))./temp(3))));
      end
      if (~isempty(mapFilter)),
        mapZ = filter_image(mapZ,mapFilter);
      end
      mapZ = mapZ+mapNoise.*rand(N_MAP);
      if any(mapZ(:) > (MAX_HEIGHT+waterLevel)),
        mapZ = mapZ.*((MAX_HEIGHT+waterLevel)/max(mapZ(:)));
      end
      if (waterLevel > 0),
        isWater = true;
        mapZ = mapZ-waterLevel;
      end
      mapZ(mapZ < MIN_HEIGHT) = MIN_HEIGHT;

      % Generate horizon:

      nHorizon = ceil(2*pi*HORIZON_LIMIT/MAP_DELTA);
      horizonZ = zeros(1,nHorizon);
      index = find(rand(1,nHorizon) < horizonFill);
      for i = 1:length(index),
        distance = MAP_DELTA.*abs((1:nHorizon)-index(i));
        horizonZ = horizonZ+...
                   scale(1)./(1+exp((distance-scale(2))./scale(3)));
      end
      if (waterLevel > 0),
        horizonZ = horizonZ-waterLevel;
      end
      horizonZ(horizonZ < 0) = 0;
      temp = max(mapZ(:));
      if any(horizonZ > temp),
        horizonZ = horizonZ.*temp./max(horizonZ);
      end
      index = [1:10 (nHorizon-9):nHorizon];
      temp = [linspace(0.5,1,10) linspace(1,0.5,10)];
      horizonZ(index) = temp.*horizonZ(index)+...
                        (1-temp).*fliplr(horizonZ(index));

      % Generate terrain texture map:

      delta = (N_MAP-1)/(2*N_IMAGE);
      index = (1+delta):(2*delta):(N_MAP-delta);
      mapHeight = interp2(mapZ,index,index.');
      if (waterLevel > 0),
        waterLevel = 0;
        nearWater = dilate_mask((mapHeight < 0),make_filter(10));
      else
        mapHeight = mapHeight-waterLevel;
      end
      [mapGradientX,mapGradientY] = gradient(mapZ,MAP_DELTA);
      mapGradient = sqrt(mapGradientX.^2+mapGradientY.^2);
      notSteep = (interp2(mapGradient,index,index.') <= SLOPE_LIMIT);
      switch LOCATION_LIST{locationIndex},

        case 'Highlands',

          terrainFile = fullfile(TEXTURE_PATH,'dirt.jpg');
          mapC = double(reshape(imread(terrainFile),N_PIXELS,3));
          index = ~notSteep;
          add_terrain('stone',3);
          index = (mapHeight > SNOW_LINE);
          add_terrain('snow',10);
          tempIndex = notSteep & (mapHeight < 50);
          index = tempIndex & (~nearWater);
          add_terrain('silt',3);
          index = tempIndex & nearWater;
          add_terrain('beach',3);
          tempIndex = notSteep & (mapHeight > 50) & ...
                      (mapHeight < TREE_LINE);
          index = tempIndex;
          index(index) = (rand(sum(index(:)),1) > 0.996);
          index = (filter_image(double(index),...
                                make_filter(20)) > 0.001) & tempIndex;
          add_terrain('grass',5);
          index = tempIndex;
          index(index) = (rand(sum(index(:)),1) > 0.999);
          index = (filter_image(double(index),...
                                make_filter(20)) > 0.001) & tempIndex;
          add_terrain('forest',3);

      end
      mapC = reshape(uint8(mapC),N_IMAGE,N_IMAGE,3);

      % Initialize staker positions and settings:

      mapIndex = [2 floor((N_MAP-1)/2) ceil((N_MAP+1)/2)+1 N_MAP-1;...
                  ceil((N_MAP+1)/2)+1 N_MAP-1 2 floor((N_MAP-1)/2);...
                  2 floor((N_MAP-1)/2) 2 floor((N_MAP-1)/2);...
                  ceil((N_MAP+1)/2)+1 N_MAP-1 ceil((N_MAP+1)/2)+1 N_MAP-1];
      muX = 0.625.*MAP_LIMIT.*[1 -1 -1 1];
      muY = 0.625.*MAP_LIMIT.*[-1 1 -1 1];
      sigma = 0.125*MAP_LIMIT^2;
      for i = 1:nPlayers,
        rIndex = mapIndex(i,1):mapIndex(i,2);
        cIndex = mapIndex(i,3):mapIndex(i,4);
        x = mapX(rIndex,cIndex);
        y = mapY(rIndex,cIndex);
        z = mapZ(rIndex,cIndex);
        slope = mapGradient(rIndex,cIndex);
        temp = exp(-((x-muX(i)).^2+(y-muY(i)).^2)./sigma).*...
               rand(size(z)).*((z > 0) & (slope < SLOPE_LIMIT));
        [temp,index] = max(temp(:));
        players(i).position = [x(index) y(index) z(index)];
        players(i).settings = [0 0 100 0];
        players(i).camera = CAMERA_DEFAULT;
      end

    end

    %----------------------------------------------------------------------
    function add_terrain(terrainFile,radius)
    %
    %   Add a terrain pattern to the texture map.
    %
    %----------------------------------------------------------------------

      if any(index(:)),
        terrainFile = fullfile(TEXTURE_PATH,[terrainFile,'.jpg']);
        terrain = reshape(imread(terrainFile),N_PIXELS,3);
        b = filter_image(double(index),make_filter(radius));
        mask = (b(:) > 0);
        b = b(mask)*ones(1,3);
        mapC(mask,:) = (1-b).*mapC(mask,:)+b.*double(terrain(mask,:));
      end

    end

  end

  %------------------------------------------------------------------------
  function initialize_game
  %
  %   Initializes the game figure window and uicontrol interface.
  %
  %------------------------------------------------------------------------

    % Initialize variables:

    updateGameFcn = @update_game;
    axesPosition = [1 126 600 410];
    playerData = players(currentPlayer);
    capacity = playerData.capacity;
    settings = playerData.settings;
    cameraProperties = {'CameraPosition','CameraTarget',...
                        'CameraUpVector','CameraViewAngle'};
    cameraData = playerData.camera;
    startMessage = 'Status -';
    for i = 1:nPlayers,
      startMessage = [startMessage '   ' players(i).name ' = ' ...
                      num2str(players(i).capacity,'%6.2f') '%'];
    end
    startTime = datestr(status.suspendedGames(currentGame).lastPlayed);
    startMessage = {startMessage; ['Starting game - ',startTime]};
    windSpeed = [num2str(sqrt(sum(windVector.^2)),'%10.2f'),' mph'];
    windTheta = atan2(windVector(2),windVector(1))-pi/4;
    windData = [cos(windTheta) -sin(windTheta); ...
                sin(windTheta) cos(windTheta)]*...
               [0   0.2 0.1  0.1 -0.1 -0.1 -0.2; ...
                0.4 0.2 0.2 -0.4 -0.4  0.2  0.2];
    blastC = imread(fullfile(TEXTURE_PATH,'fire.jpg'));
    rubbleFile = fullfile(TEXTURE_PATH,'rubble.jpg');
    rubbleC = double(reshape(imread(rubbleFile),N_PIXELS,3));
    isActive = false;
    selection = 'none';
    cameraPoint = [];
    targetPoint = [];
    upVector = [];
    viewAngle = [];
    sightVector = [];
    crossVector = [];
    rotationVector = [];
    currentTheta = [];
    origin = [];

    % Create game figure window:

    hGame = make_figure([1+(SCREEN_SIZE(3:4)-[600 600])./2 600 600],...
                        'CloseRequestFcn',@callback_game,...
                        'Color',edgeColor(2,:),...
                        'Name',['Staker v',BOMB_VERSION],...
                        'Renderer','OpenGL','Resize','on',...
                        'ResizeFcn',@resize_game,'Tag','STAKER_GAME',...
                        'WindowButtonDownFcn',{@mouse_game;'down'},...
                        'WindowButtonMotionFcn',{@mouse_game;'standby'},...
                        'WindowButtonUpFcn',{@mouse_game;'up'});

    % Create axes:

    hMap = make_axes(hGame,axesPosition,cameraProperties,cameraData,...
                     'DataAspectRatio',[1 1 1],...
                     'PlotBoxAspectRatioMode','manual',...
                     'Projection','perspective',...
                     'XLim',MAP_LIMIT.*[-2 2],'YLim',MAP_LIMIT.*[-2 2],...
                     'ZLim',[MIN_HEIGHT 2*MAP_LIMIT]);
    update_limits(cameraData{2}-cameraData{1});

    % Plot terrain:

    hTerrain = plot_surface(hMap,mapX,mapY,mapZ,mapC);

    % Plot terrain edges:

    nAngular = 4*N_MAP-3;
    nRadial = 10;
    theta = linspace(5*pi/4,-3*pi/4,nAngular).';
    meshIndex = [1:(N_MAP-1) N_MAP:N_MAP:(N_MAP^2) ...
                 (N_MAP^2-1):-1:(N_MAP*(N_MAP-1)+1) ...
                 (N_MAP*(N_MAP-2)+1):-N_MAP:1].';
    meshMatrix = [1 1 linspace(1,0,nRadial) 0; ...
                  0 0 linspace(0,1,nRadial) 1];
    edgeX = [mapX(meshIndex) 2*MAP_LIMIT.*cos(theta)]*meshMatrix;
    edgeY = [mapY(meshIndex) 2*MAP_LIMIT.*sin(theta)]*meshMatrix;
    meshMatrix = 1./(1+exp(10.*(0.5-linspace(1,0,nRadial))));
    meshMatrix = meshMatrix-min(meshMatrix);
    meshMatrix = ones(nAngular,1)*[1 meshMatrix./max(meshMatrix)];
    imageIndex = round(linspace(1,N_IMAGE,N_MAP)).';
    imageIndex = [imageIndex; N_IMAGE.*imageIndex(2:(N_MAP-1)); ...
                  N_PIXELS-imageIndex+1; ...
                  1-N_IMAGE.*(imageIndex(2:N_MAP)-N_IMAGE)];
    imageIndex = [imageIndex imageIndex+N_PIXELS imageIndex+2*N_PIXELS];
    generate_terrain_edges;
    hEdge = plot_surface(hMap,edgeX,edgeY,edgeZ,edgeC,...
                         'FaceColor','interp','FaceLighting','none');

    % Plot water:

    [waterX,waterY] = meshgrid([-MAP_LIMIT MAP_LIMIT]);
    waterC = imread(fullfile(TEXTURE_PATH,'water.jpg'));
    hWater = plot_surface(hMap,waterX,waterY,zeros(2),waterC,...
                          'FaceAlpha',0.5,'SpecularColorReflectance',1,...
                          'SpecularExponent',5,'SpecularStrength',2);
    if (~isWater),
      set(hWater,'Visible','off');
    end

    % Plot stakers:

    stakerC = imread(fullfile(TEXTURE_PATH,'metal.jpg'));
    stakerData = cell(1,nPlayers);
    hStaker = zeros(1,nPlayers);
    hBarrel = zeros(1,nPlayers);
    hReference = cell(1,nPlayers);
    for i = 1:nPlayers,
      stakerData{i} = staker_data(players(i).class);
      turretXYZ = stakerData{i}.turretXYZ;
      barrelXYZ = stakerData{i}.barrelXYZ;
      position = players(i).position;
      theta = (45-players(i).settings(1))*pi/180;
      phi = (players(i).settings(2))*pi/180;
      barrelXYZ = barrelXYZ*rotation_matrix((pi/2)-phi,[0 1 0])*...
                  rotation_matrix(theta,[0 0 1]);
      barrelX = reshape(barrelXYZ(:,1),2,9)+turretXYZ(1);
      barrelY = reshape(barrelXYZ(:,2),2,9)+turretXYZ(2);
      barrelZ = reshape(barrelXYZ(:,3),2,9)+turretXYZ(3);
      hStaker(i) = plot_surface(hMap,stakerData{i}.X+position(1),...
                                stakerData{i}.Y+position(2),...
                                stakerData{i}.Z+position(3),stakerC,...
                                'FaceLighting','flat',...
                                'SpecularColorReflectance',0.5,...
                                'SpecularExponent',25,...
                                'SpecularStrength',1);
      hBarrel(i) = plot_surface(hMap,barrelX+position(1),...
                                barrelY+position(2),barrelZ+position(3),...
                                stakerC,'BackFaceLighting','reverselit',...
                                'FaceLighting','flat',...
                                'SpecularColorReflectance',0.5,...
                                'SpecularExponent',25,...
                                'SpecularStrength',1);
      hText = plot_text(hMap,position(1),position(2),position(3)+5000,...
                        players(i).name,'Color',[0.7 0 0],...
                        'EdgeColor',[0.7 0 0],...
                        'HorizontalAlignment','left',...
                        'VerticalAlignment','bottom','Visible','off');
      hLine = plot_line(hMap,position([1 1]),position([2 2]),...
                        [MIN_HEIGHT position(3)+5000],'Color',[0.7 0 0],...
                        'LineStyle',':','Visible','off');
      hReference{i} = [hText hLine];
    end

    % Plot horizon:

    theta = linspace(0,2*pi,length(horizonZ));
    horizonX = sqrt(HORIZON_LIMIT^2-MAX_HEIGHT^2).*cos(theta);
    horizonX = [horizonX; horizonX];
    horizonY = sqrt(HORIZON_LIMIT^2-MAX_HEIGHT^2).*sin(theta);
    horizonY = [horizonY; horizonY];
    horizonC = zeros(2,length(horizonZ),3);
    horizonC(1,:,1) = edgeColor(2,1);
    horizonC(1,:,2) = edgeColor(2,2);
    horizonC(1,:,3) = edgeColor(2,3);
    horizonC(2,:,1) = edgeColor(2,1)/2;
    horizonC(2,:,2) = edgeColor(2,2)/2;
    horizonC(2,:,3) = edgeColor(2,3)/2;
    hHorizon = plot_surface(hMap,horizonX,horizonY,...
                            [zeros(size(horizonZ)); horizonZ],horizonC,...
                            'FaceColor','interp','FaceLighting','none');

    % Plot sky:

    [skyX,skyY,skyZ] = sphere(20);
    skyX = skyX(11:21,:).*HORIZON_LIMIT;
    skyY = skyY(11:21,:).*HORIZON_LIMIT;
    skyZ = skyZ(11:21,:).*HORIZON_LIMIT;
    skyC = flipdim(imread(fullfile(TEXTURE_PATH,'sky.jpg')),1);
    plot_surface(hMap,skyX,skyY,skyZ,skyC,'FaceLighting','none');
    light('Parent',hMap,'Color',[1 1 1],'HandleVisibility','off',...
          'Position',[-cos(pi/3) 0 sin(pi/3)],'Style','infinite');

    % Create uicontrols for top left panel:

    hTopLeft = make_panel(hGame,[1 536 540 65]);
    make_panel(hTopLeft,[10 15 35 35],'BackgroundColor',accentColor);
    hMessageLight = make_panel(hTopLeft,[13 18 29 29],...
                               'BackgroundColor',[0.4 0 0]);
    hMessagePanel = make_panel(hTopLeft,[50 5 485 55],...
                               'BackgroundColor',backColor,...
                               'BorderType','beveledin');
    hMessageText = make_text(hTopLeft,[51 5 473 53],...
                             'BackgroundColor',backColor,...
                             'FontWeight','normal',...
                             'String',startMessage,...
                             'UserData',startMessage);
    hMessageSlider = make_slider(hTopLeft,[524 5 10 53],...
                                 'Callback',@callback_game,...
                                 'Enable','off','Tag','MESSAGE_SLIDER',...
                                 'Value',1);

    % Create uicontrols for top right panel:

    hTopRight = make_panel(hGame,[541 536 60 65]);
    make_button(hTopRight,[5 5 50 25],'Callback',@callback_game,...
                'String','Help','Tag','HELP');
    make_button(hTopRight,[5 35 50 25],'Callback',@callback_game,...
                'String','Quit','Tag','QUIT');

    % Create uicontrols for main control panel (left):

    hBottom = make_panel(hGame,[1 2 600 125]);
    hControls = make_panel(hGame,[2 3 598 123],'BorderType','none');
    make_text(hControls,[5 95 135 15],'String','Azimuth (degrees)');
    hAzimuthEdit = make_edit(hControls,[145 100 65 15],...
                             'Callback',@callback_game,...
                             'String',num2str(settings(1),'%10.2f'),...
                             'Tag','AZIMUTH_EDIT');
    hAzimuthSlider = make_slider(hControls,[5 85 205 10],...
                                 'Callback',@callback_game,'Max',180,...
                                 'Min',-180,'SliderStep',[1 10]./360,...
                                 'Tag','AZIMUTH_SLIDER',...
                                 'Value',settings(1));
    make_text(hControls,[5 55 135 15],'String','Elevation (degrees)');
    hElevationEdit = make_edit(hControls,[145 60 65 15],...
                               'Callback',@callback_game,...
                               'String',num2str(settings(2),'%10.2f'),...
                               'Tag','ELEVATION_EDIT');
    hElevationSlider = make_slider(hControls,[5 45 205 10],...
                                   'Callback',@callback_game,'Max',90,...
                                   'SliderStep',[1 10]./90,...
                                   'Tag','ELEVATION_SLIDER',...
                                   'Value',settings(2));
    make_text(hControls,[5 15 135 15],'String','Velocity (ft/sec)');
    hVelocityEdit = make_edit(hControls,[145 20 65 15],...
                              'Callback',@callback_game,...
                              'String',num2str(settings(3),'%10.2f'),...
                              'Tag','VELOCITY_EDIT');
    hVelocitySlider = make_slider(hControls,[5 5 205 10],...
                                  'Callback',@callback_game,...
                                  'Max',MAX_MUZZLE_VELOCITY,'Min',100,...
                                  'SliderStep',...
                                  [1 100]./(MAX_MUZZLE_VELOCITY-100),...
                                  'Tag','VELOCITY_SLIDER',...
                                  'Value',settings(3));

    % Create uicontrols for main control panel (center):

    make_panel(hControls,[215 98 170 22],'BackgroundColor',backColor,...
               'BorderType','beveledin');
    hPlayer = make_text(hControls,[216 98 168 21],...
                        'BackgroundColor',backColor,...
                        'FontSize',2*fontSize,'FontWeight','normal',...
                        'String',playerData.name);
    make_text(hControls,[215 70 170 15],'String','Selected munition:');
    hArsenal = make_menu(hControls,[225 50 150 20],...
                         'String',num2arsenal(playerData.arsenal));
    make_button(hControls,[250 5 100 40],'BackgroundColor',[1 0 0],...
                'Callback',@callback_game,'FontSize',2.5*fontSize,...
                'FontWeight','bold','ForegroundColor',[0 0 0],...
                'String','Fire!','Tag','FIRE');
    hAxes = make_axes(hControls,[390 5 15 115],'XLim',[0 1.01],...
                      'YLim',[0 1.01]);
    hCapacity = plot_patch(hAxes,[0 1 1 0],[0 0 0.01 0.01].*capacity,...
                           min([2-(capacity/50) (capacity/50) 0],1));
    plot_patch(hAxes,[zeros(2,4); ones(2,4)],...
               [0 1 2 3; 1 2 3 4; 1 2 3 4; 0 1 2 3]./4,'none',...
               'EdgeColor',[0 0 0]);

    % Create uicontrols for main control panel (right):

    hCompass = make_axes(hControls,[415 35 80 80],...
                         'CameraPosition',[0 0 18.5],...
                         'CameraTarget',[0 0 0],...
                         'CameraUpVector',[0 1 0],'CameraViewAngle',6.8,...
                         'DataAspectRatio',[1 1 1],...
                         'PlotBoxAspectRatioMode','manual',...
                         'XLim',[-1.1 1.1],'YLim',[-1.1 1.1]);
    theta = 0:(pi/20):(2*pi);
    plot_patch(hCompass,cos(theta),sin(theta),[1 1 1],...
               'EdgeColor',[0 0 0],'LineWidth',1.5,...
               'ZData',-0.1.*ones(1,41));
    plot_text(hCompass,0,0.8,0,'N');
    plot_text(hCompass,-0.8,0,0,'W');
    plot_text(hCompass,0,-0.8,0,'S');
    plot_text(hCompass,0.8,0,0,'E');
    theta = (pi/4):(pi/2):(7*pi/4);
    plot_line(hCompass,[1; 0.7]*cos(theta),[1; 0.7]*sin(theta),zeros(2,4));
    theta = (pi/8):(pi/4):(15*pi/8);
    plot_line(hCompass,[1; 0.85]*cos(theta),[1; 0.85]*sin(theta),...
              zeros(2,8));
    hDirection = plot_patch(hCompass,[0 0.2 -0.2],[0.9 1.1 1.1],[1 0 0],...
                            'EdgeColor',[0.5 0 0],'ZData',[0.1 0.1 0.1]);
    hWindDirection = plot_patch(hCompass,windData(1,:),windData(2,:),...
                                [0.5 0.5 1],'EdgeColor',[0 0 1]);
    update_compass(unit(cameraData{2}-cameraData{1})+cameraData{3});
    make_text(hControls,[505 90 80 15],'String','Wind speed:');
    hWindVelocity = make_text(hControls,[510 75 80 15],...
                              'String',windSpeed);
    hMarkers = make_check(hControls,[510 45 70 15],...
                          'Callback',@callback_game,'String','Markers',...
                          'Tag','MARKERS','Value',settings(4));
    if settings(4),
      set([hReference{:}],'Visible','on');
    end
    make_text(hControls,[455 15 95 15],'HorizontalAlignment','center',...
              'String','Sound level');
    make_text(hControls,[410 5 40 15],'HorizontalAlignment','center',...
              'String','off');
    make_text(hControls,[555 5 40 15],'HorizontalAlignment','center',...
              'String','high');
    make_slider(hControls,[450 5 105 10],'Enable','off');

    %----------------------------------------------------------------------
    function update_game
    %
    %   Update function for game uicontrols.
    %
    %----------------------------------------------------------------------

      % Initialize variables:

      startMessage = 'Status -';
      for i = 1:nPlayers,
        startMessage = [startMessage '   ' players(i).name ' = ' ...
                        num2str(players(i).capacity,'%6.2f') '%'];
      end
      startTime = datestr(status.suspendedGames(currentGame).lastPlayed);
      startMessage = {startMessage; ['Starting game - ',startTime]};
      windSpeed = [num2str(sqrt(sum(windVector.^2)),'%10.2f'),' mph'];
      windTheta = atan2(windVector(2),windVector(1))-pi/4;
      windData = [cos(windTheta) -sin(windTheta); ...
                  sin(windTheta) cos(windTheta)]*...
                 [0   0.2 0.1  0.1 -0.1 -0.1 -0.2; ...
                  0.4 0.2 0.2 -0.4 -0.4  0.2  0.2];

      % Update graphics and controls:

      set(hGame,'Color',edgeColor(2,:));
      set(hTerrain,'XData',mapX,'YData',mapY,'ZData',mapZ,'CData',mapC);
      generate_terrain_edges;
      set(hEdge,'ZData',edgeZ,'CData',edgeC);
      if isWater,
        set(hWater,'Visible','on');
      else
        set(hWater,'Visible','off');
      end
      delete([hStaker hBarrel hReference{:}]);
      stakerData = cell(1,nPlayers);
      hStaker = zeros(1,nPlayers);
      hBarrel = zeros(1,nPlayers);
      hReference = cell(1,nPlayers);
      for i = 1:nPlayers,
        stakerData{i} = staker_data(players(i).class);
        turretXYZ = stakerData{i}.turretXYZ;
        barrelXYZ = stakerData{i}.barrelXYZ;
        position = players(i).position;
        theta = (45-players(i).settings(1))*pi/180;
        phi = (players(i).settings(2))*pi/180;
        barrelXYZ = barrelXYZ*rotation_matrix((pi/2)-phi,[0 1 0])*...
                    rotation_matrix(theta,[0 0 1]);
        barrelX = reshape(barrelXYZ(:,1),2,9)+turretXYZ(1);
        barrelY = reshape(barrelXYZ(:,2),2,9)+turretXYZ(2);
        barrelZ = reshape(barrelXYZ(:,3),2,9)+turretXYZ(3);
        hStaker(i) = plot_surface(hMap,stakerData{i}.X+position(1),...
                                  stakerData{i}.Y+position(2),...
                                  stakerData{i}.Z+position(3),stakerC,...
                                  'FaceLighting','flat',...
                                  'SpecularColorReflectance',0.5,...
                                  'SpecularExponent',25,...
                                  'SpecularStrength',1);
        hBarrel(i) = plot_surface(hMap,barrelX+position(1),...
                                  barrelY+position(2),...
                                  barrelZ+position(3),stakerC,...
                                  'BackFaceLighting','reverselit',...
                                  'FaceLighting','flat',...
                                  'SpecularColorReflectance',0.5,...
                                  'SpecularExponent',25,...
                                  'SpecularStrength',1);
        hText = plot_text(hMap,position(1),position(2),position(3)+5000,...
                          players(i).name,'Color',[0.7 0 0],...
                          'EdgeColor',[0.7 0 0],...
                          'HorizontalAlignment','left',...
                          'VerticalAlignment','bottom','Visible','off');
        hLine = plot_line(hMap,position([1 1]),position([2 2]),...
                          [MIN_HEIGHT position(3)+5000],...
                          'Color',[0.7 0 0],'LineStyle',':',...
                          'Visible','off');
        hReference{i} = [hText hLine];
      end
      horizonC(1,:,1) = edgeColor(2,1);
      horizonC(1,:,2) = edgeColor(2,2);
      horizonC(1,:,3) = edgeColor(2,3);
      horizonC(2,:,1) = edgeColor(2,1)/2;
      horizonC(2,:,2) = edgeColor(2,2)/2;
      horizonC(2,:,3) = edgeColor(2,3)/2;
      set(hHorizon,'ZData',[zeros(size(horizonZ)); horizonZ],...
          'CData',horizonC);
      set(hMessageText,'String',startMessage,'UserData',startMessage);
      set(hMessageSlider,'Enable','off','Max',1,'SliderStep',[1 3],...
          'Value',1);
      set(hWindDirection,'XData',windData(1,:),'YData',windData(2,:));
      set(hWindVelocity,'String',windSpeed);
      update_controls;

    end

    %----------------------------------------------------------------------
    function callback_game(source,event)
    %
    %   Callback function for game uicontrols.
    %
    %----------------------------------------------------------------------

      switch get(source,'Tag'),

        case 'AZIMUTH_EDIT',

          value = str2double(get(source,'String'));
          if isnan(value),
            set(source,'String',...
                num2str(players(currentPlayer).settings(1),'%10.2f'));
            bomb_error(hGame,'invalidValue','azimuth');
          else
            value = max(min(value,180),-180);
            set(source,'String',num2str(value,'%10.2f'));
            set(hAzimuthSlider,'Value',value);
            players(currentPlayer).settings(1) = value;
            update_barrel;
            drawnow;
          end

        case 'AZIMUTH_SLIDER',

          value = get(source,'Value');
          set(hAzimuthEdit,'String',num2str(value,'%10.2f'));
          players(currentPlayer).settings(1) = value;
          update_barrel;
          drawnow;

        case 'ELEVATION_EDIT',

          value = str2double(get(source,'String'));
          if isnan(value),
            set(source,'String',...
                num2str(players(currentPlayer).settings(2),'%10.2f'));
            bomb_error(hGame,'invalidValue','elevation');
          else
            value = max(min(value,90),0);
            set(source,'String',num2str(value,'%10.2f'));
            set(hElevationSlider,'Value',value);
            players(currentPlayer).settings(2) = value;
            update_barrel;
            drawnow;
          end

        case 'ELEVATION_SLIDER',

          value = get(source,'Value');
          set(hElevationEdit,'String',num2str(value,'%10.2f'));
          players(currentPlayer).settings(2) = value;
          update_barrel;
          drawnow;

        case 'FIRE',

          render_bomb;
          nMoves = nMoves+1;
          if any([players.capacity] == 0),
            post_message('Game over, man! Game over!');
            end_game;
          else
            players(currentPlayer).isCurrent = false;
            if (currentPlayer == nPlayers),
              currentPlayer = 1;
            else
              currentPlayer = currentPlayer+1;
            end
            players(currentPlayer).isCurrent = true;
            update_game_data;
            update_controls;
            drawnow;
          end

        case 'HELP',

          display_help(hGame);

        case 'MARKERS',

          value = get(source,'Value');
          players(currentPlayer).settings(4) = value;
          if value,
            set([hReference{:}],'Visible','on');
          else
            set([hReference{:}],'Visible','off');
          end
          drawnow;

        case 'MESSAGE_SLIDER',

          messageString = get(hMessageText,'UserData');
          nRows = numel(messageString);
          value = nRows-round(get(source,'Value'));
          set(hMessageText,'String',messageString(value:nRows));
          drawnow;

        case {'QUIT','STAKER_GAME'},

          display_quit;

        case 'VELOCITY_EDIT',

          value = str2double(get(source,'String'));
          if isnan(value),
            set(source,'String',...
                num2str(players(currentPlayer).settings(3),'%10.2f'));
            bomb_error(hGame,'invalidValue','velocity');
          else
            value = max(min(value,MAX_MUZZLE_VELOCITY),100);
            set(source,'String',num2str(value,'%10.2f'));
            set(hVelocitySlider,'Value',value);
            players(currentPlayer).settings(3) = value;
            drawnow;
          end

        case 'VELOCITY_SLIDER',

          value = get(source,'Value');
          set(hVelocityEdit,'String',num2str(value,'%10.2f'));
          players(currentPlayer).settings(3) = value;
          drawnow;

      end

      %--------------------------------------------------------------------
      function update_barrel
      %
      %   Updates barrel position.
      %
      %--------------------------------------------------------------------

        turretXYZ = stakerData{currentPlayer}.turretXYZ;
        barrelXYZ = stakerData{currentPlayer}.barrelXYZ;
        position = players(currentPlayer).position;
        theta = (45-players(currentPlayer).settings(1))*pi/180;
        phi = (players(currentPlayer).settings(2))*pi/180;
        barrelXYZ = barrelXYZ*rotation_matrix((pi/2)-phi,[0 1 0])*...
                    rotation_matrix(theta,[0 0 1]);
        barrelX = reshape(barrelXYZ(:,1),2,9)+turretXYZ(1);
        barrelY = reshape(barrelXYZ(:,2),2,9)+turretXYZ(2);
        barrelZ = reshape(barrelXYZ(:,3),2,9)+turretXYZ(3);
        set(hBarrel(currentPlayer),'XData',barrelX+position(1),...
            'YData',barrelY+position(2),'ZData',barrelZ+position(3));

      end

    end

    %----------------------------------------------------------------------
    function resize_game(source,event)
    %
    %   Resize function for game figure window.
    %
    %----------------------------------------------------------------------

      position = get(source,'Position');
      position(3) = max(position(3),600);
      position(4) = max(position(4),300);
      axesPosition = [1 126 position(3) position(4)-190];
      set(source,'Position',position);
      set(hMap,'Position',axesPosition);
      set(hTopLeft,'Position',[1 position(4)-64 position(3)-60 65]);
      set(hMessagePanel,'Position',[50 5 position(3)-115 55]);
      set(hMessageText,'Position',[51 5 position(3)-127 53]);
      set(hMessageSlider,'Position',[position(3)-76 5 10 53]);
      set(hTopRight,'Position',[position(3)-59 position(4)-64 60 65]);
      set(hBottom,'Position',[1 2 position(3) 125]);
      set(hControls,'Position',[ceil((position(3)-596)/2) 3 598 123]);

    end

    %----------------------------------------------------------------------
    function mouse_game(source,event,mouseOperation)
    %
    %   Mouse button function for game figure window.
    %
    %----------------------------------------------------------------------

      switch mouseOperation,

        case 'standby',

          currentPoint = get(source,'CurrentPoint');
          update_pointer;
          drawnow;

        case 'down',

          if (~isActive),
            isActive = true;
            currentPoint = get(source,'CurrentPoint');
            if within_axes(currentPoint,axesPosition),
              selection = get(source,'SelectionType');
              activate_mouse;
              set(source,'WindowButtonMotionFcn',{@mouse_game;'motion'});
              update_pointer;
              drawnow;
            else
              isActive = false;
            end
          end

        case 'motion',

          currentPoint = get(source,'CurrentPoint');
          track_mouse;
          drawnow;

        case 'up',

          if isActive,
            currentPoint = get(source,'CurrentPoint');
            track_mouse;
            set(source,'WindowButtonMotionFcn',{@mouse_game;'standby'});
            selection = 'none';
            update_pointer;
            isActive = false;
            drawnow;
          end

      end

      %--------------------------------------------------------------------
      function activate_mouse
      %
      %   Initialization function for mouse camera controls.
      %
      %--------------------------------------------------------------------

        switch selection,

          case 'normal',  % Left button: orbit operation

            cameraData = players(currentPlayer).camera;
            [cameraPoint,targetPoint,upVector] = deal(cameraData{1:3});
            crossVector = unit(cross([0 0 1],-cameraPoint));
            currentTheta = acos(cameraPoint(3)/CAMERA_RADIUS);
            origin = currentPoint;

          case 'alt',  % Right button: rotation operation

            cameraData = players(currentPlayer).camera;
            [cameraPoint,targetPoint,upVector] = deal(cameraData{1:3});
            sightVector = targetPoint-cameraPoint;
            crossVector = unit(cross(sightVector,upVector));
            rotationVector = unit([0 0 CAMERA_RADIUS^2/cameraPoint(3)]-...
                                  cameraPoint);
            temp = sum(sightVector.*rotationVector);
            currentTheta(2) = pi/2-acos(temp/norm(sightVector));
            temp = unit(sightVector-temp.*rotationVector);
            currentTheta(1) = real(acos(-sum(temp.*cameraPoint)/...
                                        CAMERA_RADIUS));
            if isequal(sign(cross(cameraPoint,temp)),sign(rotationVector)),
              currentTheta(1) = -currentTheta(1);
            end
            origin = currentPoint;

          case 'extend',  % Middle button: zoom operation

            viewAngle = players(currentPlayer).camera{4};
            origin = currentPoint(2);

          case 'open',  % Double-click any button: reset operation

            cameraData = CAMERA_DEFAULT;
            set(hMap,cameraProperties,cameraData);
            update_limits([1 1 -1]);
            update_compass([1 1 0]);
            players(currentPlayer).camera = cameraData;

        end

      end

      %--------------------------------------------------------------------
      function track_mouse
      %
      %   Tracking function for mouse camera controls.
      %
      %--------------------------------------------------------------------

        switch selection,

          case 'normal',  % Left button: orbit operation

            offset = [azimuthGain elevationGain].*(currentPoint-origin);
            offset(2) = currentTheta-...
                        min(max(currentTheta-offset(2),MIN_ORBIT_ANGLE),...
                            MAX_ORBIT_ANGLE);
            R = rotation_matrix(offset(2),crossVector)*...
                rotation_matrix(offset(1),[0 0 1]);
            newCameraData = {cameraPoint*R,targetPoint*R,upVector*R};
            temp = newCameraData{2}-newCameraData{1};
            set(hMap,cameraProperties(1:3),newCameraData);
            update_limits(temp);
            update_compass(unit(temp)+newCameraData{3});
            players(currentPlayer).camera(1:3) = newCameraData;

          case 'alt',  % Right button: rotation operation

            offset = rotationGain.*[-1 1].*(currentPoint-origin);
            temp = acos(prod(cos(currentTheta+offset)));
            if (temp > MAX_ROTATION_ANGLE),
              offset = (currentTheta+offset).*(MAX_ROTATION_ANGLE/temp)-...
                       currentTheta;
            end
            R = rotation_matrix(offset(2),crossVector)*...
                rotation_matrix(offset(1),rotationVector);
            temp = sightVector*R;
            newCameraData = {cameraPoint+temp,upVector*R};
            set(hMap,cameraProperties(2:3),newCameraData);
            update_limits(temp);
            update_compass(unit(temp)+newCameraData{2});
            players(currentPlayer).camera(2:3) = newCameraData;

          case 'extend',  % Middle button: zoom operation

            newViewAngle = viewAngle*2^(zoomGain*(origin-currentPoint(2)));
            newViewAngle = min(max(newViewAngle,MIN_VIEW_ANGLE),...
                               MAX_VIEW_ANGLE);
            set(hMap,cameraProperties{4},newViewAngle);
            players(currentPlayer).camera{4} = newViewAngle;

        end

      end

      %--------------------------------------------------------------------
      function update_pointer
      %
      %   Updates the pointer to match the current selection.
      %
      %--------------------------------------------------------------------

        o = nan;
        switch selection,

          case 'normal',  % Left button: orbit operation

            set(hGame,'Pointer','custom','PointerShapeHotSpot',[8 8],...
                'PointerShapeCData',...
                [o o o o o o o o 2 2 2 2 2 2 o o;...
                 o o o o o o o o 2 1 1 1 1 2 o o;...
                 o o o 2 o o o o 2 1 1 1 2 o o o;...
                 o o 2 1 2 o o o 2 1 1 1 1 2 o o;...
                 o 2 1 1 1 2 o o 2 1 2 1 1 1 2 o;...
                 o 2 1 1 2 o o o 2 2 o 2 1 1 2 o;...
                 2 1 1 1 2 o o 2 2 o o 2 1 1 1 2;...
                 2 1 1 2 o o 2 1 1 2 o o 2 1 1 2;...
                 2 1 1 2 o o 2 1 1 2 o o 2 1 1 2;...
                 2 1 1 1 2 o o 2 2 o o 2 1 1 1 2;...
                 o 2 1 1 2 o o o o o o 2 1 1 2 o;...
                 o 2 1 1 1 2 2 o o 2 2 1 1 1 2 o;...
                 o o 2 1 1 1 1 2 2 1 1 1 1 2 o o;...
                 o o o 2 1 1 1 1 1 1 1 1 2 o o o;...
                 o o o o 2 2 1 1 1 1 2 2 o o o o;...
                 o o o o o o 2 2 2 2 o o o o o o]);

          case 'alt',  % Right button: rotation operation

            set(hGame,'Pointer','custom','PointerShapeHotSpot',[8 8],...
                'PointerShapeCData',...
                [o o o o o o o 2 2 o o o o o o o;...
                 o o o o o o 2 1 1 2 o o o o o o;...
                 o o o o o 2 1 1 1 1 2 o o o o o;...
                 o o o o 2 1 1 1 1 1 1 2 o o o o;...
                 o o o 2 2 2 2 1 1 2 2 2 2 o o o;...
                 o o 2 1 2 o 2 1 1 2 o 2 1 2 o o;...
                 o 2 1 1 2 2 2 1 1 2 2 2 1 1 2 o;...
                 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2;...
                 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2;...
                 o 2 1 1 2 2 2 1 1 2 2 2 1 1 2 o;...
                 o o 2 1 2 o 2 1 1 2 o 2 1 2 o o;...
                 o o o 2 2 2 2 1 1 2 2 2 2 o o o;...
                 o o o o 2 1 1 1 1 1 1 2 o o o o;...
                 o o o o o 2 1 1 1 1 2 o o o o o;...
                 o o o o o o 2 1 1 2 o o o o o o;...
                 o o o o o o o 2 2 o o o o o o o]);

          case 'extend',  % Middle button: zoom operation

            set(hGame,'Pointer','custom','PointerShapeHotSpot',[8 8],...
                'PointerShapeCData',...
                [o o o o o o o 2 2 o o o o o o o;...
                 o o o o o 2 2 1 1 2 2 o o o o o;...
                 o o o 2 2 1 1 1 1 1 1 2 2 o o o;...
                 o o 2 1 1 1 1 1 1 1 1 1 1 2 o o;...
                 o o 2 2 2 2 1 1 1 1 2 2 2 2 o o;...
                 o o o o o 2 1 1 1 1 2 o o o o o;...
                 o o o o o 2 1 1 1 1 2 o o o o o;...
                 o o o o o 2 1 1 1 1 2 o o o o o;...
                 o o o o 2 1 1 1 1 1 1 2 o o o o;...
                 o o o o 2 1 1 1 1 1 1 2 o o o o;...
                 2 2 2 2 2 1 1 1 1 1 1 2 2 2 2 2;...
                 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2;...
                 o 2 2 1 1 1 1 1 1 1 1 1 1 2 2 o;...
                 o o o 2 2 1 1 1 1 1 1 2 2 o o o;...
                 o o o o o 2 2 1 1 2 2 o o o o o;...
                 o o o o o o o 2 2 o o o o o o o]);

          case 'none',  % No current selection

            if within_axes(currentPoint,axesPosition),
              set(hGame,'Pointer','custom','PointerShapeHotSpot',[8 8],...
                  'PointerShapeCData',...
                  [o o o 2 2 2 o o o o 2 2 2 o o o;...
                   o o o 2 1 2 o o o o 2 1 2 o o o;...
                   o o o 2 1 2 o o o o 2 1 2 o o o;...
                   2 2 2 2 1 2 o o o o 2 1 2 2 2 2;...
                   2 1 1 1 1 2 o o o o 2 1 1 1 1 2;...
                   2 2 2 2 2 2 o o o o 2 2 2 2 2 2;...
                   o o o o o o o 2 2 o o o o o o o;...
                   o o o o o o 2 1 1 2 o o o o o o;...
                   o o o o o o 2 1 1 2 o o o o o o;...
                   o o o o o o o 2 2 o o o o o o o;...
                   2 2 2 2 2 2 o o o o 2 2 2 2 2 2;...
                   2 1 1 1 1 2 o o o o 2 1 1 1 1 2;...
                   2 2 2 2 1 2 o o o o 2 1 2 2 2 2;...
                   o o o 2 1 2 o o o o 2 1 2 o o o;...
                   o o o 2 1 2 o o o o 2 1 2 o o o;...
                   o o o 2 2 2 o o o o 2 2 2 o o o]);
            else
              set(hGame,'Pointer','default',...
                  'PointerShapeHotSpot','default',...
                  'PointerShapeCData','default');
            end

        end

      end

    end

    %----------------------------------------------------------------------
    function generate_terrain_edges
    %
    %   Generates height and color data for terrain edges.
    %
    %----------------------------------------------------------------------

      edgeHeight = mapZ(meshIndex);
      edgeZ = [edgeHeight ...
               meshMatrix.*(min(edgeHeight,0)*ones(1,nRadial+1)) ...
               MIN_HEIGHT.*ones(nAngular,1)];
      mapEdge = double(mapC(imageIndex))./255;
      edgeC = zeros(nAngular,nRadial+3,3);
      edgeC(:,:,1) = edgeColor(2,1);
      edgeC(:,:,2) = edgeColor(2,2);
      edgeC(:,:,3) = edgeColor(2,3);
      edgeC(:,1,:) = mapEdge;
      edgeC(:,2,:) = mapEdge;
      edgeC(:,3,:) = mapEdge;
      index = (edgeHeight > 0);
      nIndex = sum(index);
      edgeC(index,1:3,1) = ones(nIndex,1)*...
                           ([1 0.6 1].*edgeColor([1 1 2],1).');
      edgeC(index,1:3,2) = ones(nIndex,1)*...
                           ([1 0.6 1].*edgeColor([1 1 2],2).');
      edgeC(index,1:3,3) = ones(nIndex,1)*...
                           ([1 0.6 1].*edgeColor([1 1 2],3).');
      edgeC = filter_image(edgeC,make_filter(2));
      edgeC(index,1:2,1) = ones(nIndex,1)*([1 0.6].*edgeColor(1,1));
      edgeC(index,1:2,2) = ones(nIndex,1)*([1 0.6].*edgeColor(1,2));
      edgeC(index,1:2,3) = ones(nIndex,1)*([1 0.6].*edgeColor(1,3));

    end

    %----------------------------------------------------------------------
    function update_limits(directionVector)
    %
    %   Updates axes limits (extends limits in front of camera plane).
    %
    %----------------------------------------------------------------------

      viewTheta = atan2(directionVector(2),directionVector(1));
      limitX = MAP_LIMIT.*[-2 2];
      if (viewTheta >= -pi/2) && (viewTheta <= pi/2),
        limitX(2) = HORIZON_LIMIT;
      else
        limitX(1) = -HORIZON_LIMIT;
      end
      limitY = MAP_LIMIT.*[-2 2];
      if (viewTheta >= 0),
        limitY(2) = HORIZON_LIMIT;
      else
        limitY(1) = -HORIZON_LIMIT;
      end
      if (directionVector(3) >= 0),
        limitZ = [MIN_HEIGHT HORIZON_LIMIT];
      else
        limitZ = [MIN_HEIGHT 2*MAP_LIMIT];
      end
      set(hMap,'XLim',limitX,'YLim',limitY,'ZLim',limitZ);

    end

    %----------------------------------------------------------------------
    function update_controls
    %
    %   Updates the camera and controls for the current player.
    %
    %----------------------------------------------------------------------

      playerData = players(currentPlayer);
      capacity = playerData.capacity;
      settings = playerData.settings;
      cameraData = playerData.camera;
      set(hMap,cameraProperties,cameraData);
      update_limits(cameraData{2}-cameraData{1});
      set(hAzimuthEdit,'String',num2str(settings(1),'%10.2f'));
      set(hAzimuthSlider,'Value',settings(1));
      set(hElevationEdit,'String',num2str(settings(2),'%10.2f'));
      set(hElevationSlider,'Value',settings(2));
      set(hVelocityEdit,'String',num2str(settings(3),'%10.2f'));
      set(hVelocitySlider,'Value',settings(3));
      set(hPlayer,'String',playerData.name);
      set(hArsenal,'String',num2arsenal(playerData.arsenal),'Value',1);
      set(hCapacity,...
          'FaceColor',min([2-(capacity/50) (capacity/50) 0],1),...
          'YData',[0 0 0.01 0.01].*capacity);
      update_compass(unit(cameraData{2}-cameraData{1})+cameraData{3});
      set(hMarkers,'Value',settings(4));
      if settings(4),
        set([hReference{:}],'Visible','on');
      else
        set([hReference{:}],'Visible','off');
      end

    end

    %----------------------------------------------------------------------
    function update_compass(directionVector)
    %
    %   Updates compass direction to match camera view.
    %
    %----------------------------------------------------------------------

      compassTheta = atan2(directionVector(2),directionVector(1))-pi/4;
      S = sin(compassTheta);
      C = cos(compassTheta);
      pointerData = [C -S; S C]*[0 0.2 -0.2; 0.9 1.1 1.1];
      set(hCompass,'CameraUpVector',[-S C 0]);
      set(hDirection,'XData',pointerData(1,:),'YData',pointerData(2,:));

    end

    %----------------------------------------------------------------------
    function post_message(messageString)
    %
    %   Posts a message to the game message display.
    %
    %----------------------------------------------------------------------

      messageString = [{messageString}; get(hMessageText,'UserData')];
      nRows = numel(messageString)-1;
      set(hMessageText,'String',messageString,'UserData',messageString);
      set(hMessageSlider,'Enable','on','Max',nRows,...
          'SliderStep',[1 3]./nRows,'Value',nRows);
      for i = 1:3,
        set(hMessageLight,'BackgroundColor',[1 0 0]);
        pause(0.25);
        set(hMessageLight,'BackgroundColor',[0.4 0 0]);
        pause(0.25);
      end

    end

    %----------------------------------------------------------------------
    function render_bomb
    %
    %   Renders animation for the bomb trajectory.
    %
    %----------------------------------------------------------------------

      % Get bomb properties:

      playerData = players(currentPlayer);
      bombList = get(hArsenal,'String');
      bombName = strtrim(strtok(bombList{get(hArsenal,'Value')},'-'));
      bombIndex = find(strcmp({BOMB_DATA.name},bombName));
      if isempty(bombIndex),
        post_message([playerData.name,' misfired!']);
        return;
      end
      bombRadius = BOMB_DATA(bombIndex).radius;
      bombLength = BOMB_DATA(bombIndex).length;
      bombWeight = BOMB_DATA(bombIndex).weight;
      bombDrag = BOMB_DATA(bombIndex).drag;
      bombBlast = BOMB_DATA(bombIndex).blastRadius;
      bombDamage = BOMB_DATA(bombIndex).blastDamage;
      bombBoost = BOMB_DATA(bombIndex).boosterForce/bombWeight;
      ignoreWater = BOMB_DATA(bombIndex).ignoreWater;

      % Initialize variables:

      axialArea = (pi/2)*bombRadius^2;
      transverseArea = 2*bombRadius*bombLength;
      scaledWindVector = (5280/3600).*windVector;
      dragScale = 0.5*bombDrag/bombWeight;
      minHeight = min(mapZ(:));
      turretXYZ = stakerData{currentPlayer}.turretXYZ;
      barrelLength = max(stakerData{currentPlayer}.barrelXYZ(:,3));
      settings = playerData.settings;
      theta = (45-settings(1))*pi/180;
      phi = settings(2)*pi/180;
      flightVector = [cos(phi)*cos(theta) cos(phi)*sin(theta) sin(phi)];
      position = playerData.position+turretXYZ+barrelLength.*flightVector;
      velocity = settings(3).*flightVector;
      speed = norm(velocity);
      if ((~isWater) || (position(3) >= 0)),
        bombBoost = 0;
      end

      % Initialize plot of trajectory:

      mapHeight = interp2(mapX,mapY,mapZ,position(1),position(2));
      if (position(3) > mapHeight),
        inFlight = true;
        flightSegment = zeros(10000*trajectoryStep,3);
        allBombX = position(1);
        allBombY = position(2);
        allBombZ = position(3);
        blastXYZ = [];
        hBomb = plot_line(hMap,allBombX,allBombY,allBombZ,'Color',[1 1 1]);
        drawnow;
      else
        inFlight = false;
        blastXYZ = position;
        hBomb = [];
      end

      % Calculate and render bomb trajectory:

      while inFlight,

        % Initialize variables:

        flightTime = 0;
        counter = 1;
        flightSegment(1,:) = position;

        % Compute segment of the bomb trajectory:

        while (flightTime < trajectoryStep),
          if (isWater && (position(3) < 0)),
            dragVector = -velocity;
            densityFcn = @water_density;
          else
            dragVector = scaledWindVector-velocity;
            densityFcn = @air_density;
          end
          drag = norm(dragVector);
          if (drag > 0),
            density = densityFcn(position(3));
            theta = real(acos(sum(flightVector.*dragVector)/drag));
            A = axialArea*(1+abs(cos(theta)))+transverseArea*sin(theta);
            dragVector = dragScale*density*A*drag.*dragVector;
            timeStep = min(MAX_DELTA_T,2*SCALE_DELTA_T/norm(dragVector));
          else
            dragVector = [0 0 0];
            timeStep = MAX_DELTA_T;
          end
          if (isWater && (bombBoost > 0)),
            if ((position(3) < 0) || (speed < settings(3))),
              rocketVector = bombBoost.*flightVector;
            else
              rocketVector = [0 0 0];
              bombBoost = 0;
            end
          else
            rocketVector = [0 0 0];
          end
          position = position+velocity.*timeStep;
          velocity = velocity+(G+rocketVector+dragVector).*timeStep;
          speed = norm(velocity);
          if (speed > 0),
            flightVector = velocity./speed;
          end
          flightTime = flightTime+timeStep;
          counter = counter+1;
          flightSegment(counter,:) = position;
        end

        % Check for impacts:

        bombX = flightSegment(1:counter,1);
        bombY = flightSegment(1:counter,2);
        bombZ = flightSegment(1:counter,3);
        mapHeight = interp2(mapX,mapY,mapZ,bombX,bombY);
        impactIndex = (bombZ <= mapHeight);
        if (isWater && ~ignoreWater),
          impactIndex = (impactIndex | [false; (diff(bombZ <= 0) > 0)]);
        else
          impactIndex = (impactIndex | (bombZ <= minHeight));
        end
        impactIndex = find(impactIndex,1);
        if isempty(impactIndex),
          impactIndex = counter;
        else
          inFlight = false;
          if all(isfinite(mapHeight([impactIndex max(impactIndex-1,1)]))),
            blastXYZ = [bombX(impactIndex) bombY(impactIndex) ...
                        bombZ(impactIndex)];
          else
            blastXYZ = [];
          end
        end

        % Update plot of trajectory:

        allBombX = [allBombX; bombX(2:impactIndex)];
        allBombY = [allBombY; bombY(2:impactIndex)];
        allBombZ = [allBombZ; bombZ(2:impactIndex)];
        set(hBomb,'XData',allBombX,'YData',allBombY,'ZData',allBombZ);
        drawnow;

      end

      % Render explosion:

      delete(hBomb);
      if (~isempty(blastXYZ)),
        render_explosion;
      end

      % Update player information:

      players(currentPlayer).arsenal(bombIndex) = ...
        playerData.arsenal(bombIndex)-1;
      players(currentPlayer).used(bombIndex) = ...
        playerData.used(bombIndex)+1;

      %--------------------------------------------------------------------
      function render_explosion
      %
      %   Renders animation for the bomb explosion.
      %
      %--------------------------------------------------------------------

        % Initialize map alterations:

        mapIndex = (((mapX-blastXYZ(1)).^2+(mapY-blastXYZ(2)).^2) <= ...
                    bombBlast^2);
        oldZ = mapZ(mapIndex);
        newZ = sqrt(bombBlast^2-(mapX(mapIndex)-blastXYZ(1)).^2-...
                    (mapY(mapIndex)-blastXYZ(2)).^2);
        newZ = max(min(oldZ,blastXYZ(3)-newZ),MIN_HEIGHT)+...
               max(oldZ-newZ-blastXYZ(3),0);
        mapZ(mapIndex) = newZ;
        stakerZ = nan(1,nPlayers);
        barrelZ = cell(1,nPlayers);
        for i = 1:nPlayers,
          position = players(i).position;
          positionZ = interp2(mapX,mapY,mapZ,position(1),position(2));
          if (positionZ ~= position(3)),
            stakerZ(i) = positionZ;
            barrelZ{i} = get(hBarrel(i),'ZData')-position(3);
          end
        end
        index = (newZ < oldZ);
        if any(index),
          b = mapIndex;
          b(mapIndex) = index;
          b = resize_mask(b,N_IMAGE/N_MAP);
          b = dilate_mask(b,make_filter(5));
          b = filter_image(double(b),make_filter(5));
          mask = (b(:) > 0);
          b = b(mask)*ones(1,3);
          mapC = reshape(mapC,N_PIXELS,3);
          mapC(mask,:) = uint8((1-b).*double(mapC(mask,:))+...
                               b.*rubbleC(mask,:));
          mapC = reshape(mapC,N_IMAGE,N_IMAGE,3);
        end

        % Initialize explosion variables:

        nSteps = round(10/blastStep);
        nTheta = N_BLAST;
        nPhi = 3*N_BLAST;
        theta = ones(nPhi,1)*linspace(-pi,pi,nTheta);
        scaleX = bombBlast.*cos(theta);
        scaleY = bombBlast.*sin(theta);
        phi = linspace(-(pi/2),(pi/2),nPhi).';
        nTop = sum(phi > (pi/4));
        fixedR = 1/sqrt(2);
        blastR = cos(phi)*ones(1,nTheta);
        blastZ = sin(phi)*ones(1,nTheta);
        shiftZ = min((interp2(mapX,mapY,mapZ,scaleX.*blastR+blastXYZ(1),...
                              scaleY.*blastR+blastXYZ(2))-...
                              blastXYZ(3))./bombBlast,-fixedR);
        blastIndex = (blastZ > shiftZ);
        if all(blastIndex(1,:)),
          renderAll = true;
          shiftZ = [-ones(nPhi-nTop,nTheta); zeros(nTop,nTheta)];
          scaleZ = fixedR./(fixedR-shiftZ);
          stretchZ = [(linspace(3,1,nPhi-nTop).')*ones(1,nTheta); ...
                      ones(nTop,nTheta)];
        else
          renderAll = false;
          shiftZ = shiftZ(logical([diff(cumsum(blastIndex) > 1); ...
                                   zeros(1,nTheta)])).';
          shiftZ = [ones(nPhi-nTop,1)*shiftZ; zeros(nTop,nTheta)];
          scaleZ = fixedR./(fixedR-shiftZ);
          blastIndex = (blastZ > shiftZ);
          shiftZ = shiftZ(blastIndex);
          scaleZ = scaleZ(blastIndex);
          stretchZ = zeros(nPhi,nTheta);
          stretchZ(blastIndex) = 1;
          stretchZ = cumsum(stretchZ);
          stretchZ = stretchZ./(ones(nPhi,1)*stretchZ(nPhi-nTop+1,:));
          stretchZ(nPhi+((1-nTop):0),:) = 1;
        end

        % Render explosion:

        hBlast = plot_surface(hMap,blastXYZ(1).*ones(nPhi,nTheta),...
                              blastXYZ(2).*ones(nPhi,nTheta),...
                              blastXYZ(3).*ones(nPhi,nTheta),blastC,...
                              'AmbientStrength',1,'DiffuseStrength',0);
        drawnow;
        for i = 1:ceil(nSteps/10),
          scale = 1-exp(-30*i/nSteps);
          set(hBlast,'XData',scale.*scaleX.*blastR+blastXYZ(1),...
              'YData',scale.*scaleY.*blastR+blastXYZ(2),...
              'ZData',scale.*bombBlast.*blastZ+blastXYZ(3));
          drawnow;
        end
        if any(index),
          set(hTerrain,'CData',mapC);
        end
        for i = 1:nSteps,
          scale = 1-exp(-3*i/nSteps);
          mapZ(mapIndex) = (1-scale).*oldZ+scale.*newZ;
          generate_terrain_edges;
          if renderAll,
            temp = scaleZ.*(blastZ-shiftZ);
            temp = blastStep.*temp.*exp(-1.5.*temp);
            blastR = blastR+temp.*blastR.*(blastZ-fixedR);
            blastZ = blastZ+temp.*((2./(1+exp(5.*(blastR-fixedR))))-1);
          else
            tempR = blastR(blastIndex);
            tempZ = blastZ(blastIndex);
            temp = scaleZ.*(tempZ-shiftZ);
            temp = blastStep.*temp.*exp(-1.5.*temp);
            blastR(blastIndex) = tempR+temp.*tempR.*(tempZ-fixedR);
            blastZ(blastIndex) = tempZ+temp.*...
                                       ((2./(1+exp(5.*(tempR-fixedR))))-1);
          end
          set(hTerrain,'ZData',mapZ);
          set(hEdge,'ZData',edgeZ,'CData',edgeC);
          for j = 1:nPlayers,
            if (~isnan(stakerZ(j))),
              positionZ = (1-scale)*(players(j).position(3))+...
                          scale*stakerZ(j);
              set(hStaker(j),'ZData',stakerData{j}.Z+positionZ);
              set(hBarrel(j),'ZData',barrelZ{j}+positionZ);
            end
          end
          set(hBlast,'AmbientStrength',1-0.7*i/nSteps,...
              'DiffuseStrength',i/nSteps,...
              'XData',scaleX.*blastR+blastXYZ(1),...
              'YData',scaleY.*blastR+blastXYZ(2),...
              'ZData',bombBlast.*(blastZ+i.*stretchZ./nSteps)+blastXYZ(3));
          drawnow;
        end

        % Perform final map update and deal damage:

        mapZ(mapIndex) = newZ;
        generate_terrain_edges;
        set(hTerrain,'ZData',mapZ);
        set(hEdge,'ZData',edgeZ,'CData',edgeC);
        damageTaken = false;
        messageString = 'Status -';
        for i = 1:nPlayers,
          position = players(i).position;
          blastDistance = norm(position-blastXYZ);
          if (blastDistance < bombBlast),
            damageTaken = true;
            damage = bombDamage*(1-blastDistance/bombBlast);
            players(i).capacity = max(players(i).capacity-damage,0);
          end
          if (~isnan(stakerZ(i))),
            damageTaken = true;
            damage = (position(3)-stakerZ(i))/132;
            players(i).capacity = max(players(i).capacity-damage,0);
            players(i).position(3) = stakerZ(i);
            set(hStaker(i),'ZData',stakerData{i}.Z+stakerZ(i));
            set(hBarrel(i),'ZData',barrelZ{i}+stakerZ(i));
          end
          messageString = [messageString '   ' players(i).name ' = ' ...
                           num2str(players(i).capacity,'%6.2f') '%'];
        end
        delete(hBlast);
        drawnow;
        if (damageTaken && all([players.capacity] > 0)),
          post_message(messageString);
        end

      end

    end

    %----------------------------------------------------------------------
    function end_game
    %
    %   Ends a game and displays the results.
    %
    %----------------------------------------------------------------------

      % Initialize variables:

      recordIndex = ([players.capacity] == 0);
      if all(recordIndex),
        recordIndex = recordIndex+1;
      elseif (sum(~recordIndex) > 1),
        recordIndex(currentPlayer) = true;
      end
      recordIndex = recordIndex+1;
      oldEarnings = zeros(1,nPlayers);
      damageCharge = zeros(1,nPlayers);
      commission = zeros(1,nPlayers);
      unlockedUpdate = false(1,nPlayers);

      % Update player data and status:

      for i = 1:nPlayers,
        newProfile = players(i);
        index = recordIndex(i);
        oldEarnings(i) = newProfile.earnings;
        earnings = -round(50*(100-newProfile.capacity));
        damageCharge(i) = earnings;
        if (index == 1),
          commission(i) = round(locationValue*(1e-9)*(MAP_DELTA^2)*...
                                trapz(trapz(mapZ-MIN_HEIGHT)));
          earnings = earnings+commission(i);
        end
        newProfile.earnings = oldEarnings(i)+earnings;
        newProfile.record(index) = newProfile.record(index)+1;
        index = newProfile.record;
        index = ones(N_BOMBS,1)*[newProfile.used index sum(index)];
        index = any((index >= cat(1,BOMB_DATA.unlockCondition)),2).';
        unlockedUpdate(i) = any(index & (~newProfile.unlocked));
        newProfile.unlocked = index;
        newProfile.isCurrent = false;
        newProfile.capacity = 100;
        newProfile.position = [];
        newProfile.settings = [];
        newProfile.camera = {};
        players(i) = newProfile;
        save(newProfile.file,'-struct','newProfile','-mat');
      end
      status.suspendedGames(currentGame) = [];
      status.nGamesPlayed = status.nGamesPlayed+1;
      save(STATUS_FILE,'-struct','status','-mat');

      % Create modal figure window:

      position = get(hGame,'Position');
      position = [position(1:2)+(position(3:4)-[380 220])./2 380 220];
      hModal = make_figure(position,'CloseRequestFcn',@callback_end,...
                           'Name','Results','WindowStyle','modal');

      % Create uicontrol objects:

      make_panel(hModal,[1 1 380 220]);
      make_panel(hModal,[11 46 360 165],'BackgroundColor',backColor,...
                 'BorderType','beveledin');
      for i = 1:nPlayers,
        offset = 16+180*(i-1);
        newProfile = players(i);
        if (recordIndex(i) == 1),
          make_text(hModal,[offset 186 170 15],...
                    'BackgroundColor',backColor,...
                    'ForegroundColor',[1 0 0],...
                    'HorizontalAlignment','center','String','*WINNER*');
        end
        make_text(hModal,[offset 166 170 20],...
                  'BackgroundColor',backColor,'FontSize',2*fontSize,...
                  'FontWeight','normal','String',newProfile.name);
        stats = sprintf('%i%c',[newProfile.record; 45 45 32]);
        make_text(hModal,[offset 146 170 15],...
                  'BackgroundColor',backColor,'FontWeight','normal',...
                  'String',['Record: ',stats]);
        make_text(hModal,[offset 96 80 45],'BackgroundColor',backColor,...
                  'FontWeight','normal','HorizontalAlignment','right',...
                  'String',{'Earnings:'; 'Repairs:'; 'Commission:'});
        make_text(hModal,[offset+80 96 90 45],...
                  'BackgroundColor',backColor,'FontWeight','normal',...
                  'HorizontalAlignment','right',...
                  'String',{num2money(oldEarnings(i)); ...
                            num2money(damageCharge(i)); ...
                            num2money(commission(i))});
        make_panel(hModal,[offset 91 170 1],'BorderType','line',...
                   'HighlightColor',textColor);
        make_text(hModal,[offset 71 80 15],'BackgroundColor',backColor,...
                  'FontWeight','normal','HorizontalAlignment','right',...
                  'String','Total:');
        earnings = num2money(newProfile.earnings);
        hText = make_text(hModal,[offset+80 71 90 15],...
                          'BackgroundColor',backColor,...
                          'FontWeight','normal',...
                          'HorizontalAlignment','right','String',earnings);
        if (earnings <= 0),
          set(hText,'ForegroundColor',[0.7 0 0]);
        end
        if unlockedUpdate(i),
          make_text(hModal,[offset 51 170 15],...
                    'BackgroundColor',backColor,...
                    'ForegroundColor',[1 0 0],...
                    'HorizontalAlignment','center',...
                    'String','*NEW WEAPONS AVAILABLE*');
        end
        if (i < nPlayers),
          make_panel(hModal,[offset+175 51 1 155],'BorderType','line',...
                     'HighlightColor',textColor);
        end
      end
      make_button(hModal,[311 11 60 25],'Callback',@callback_end,...
                  'String','Close');

      % Wait for window to be closed:

      set(hModal,'Visible','on');
      drawnow;
      waitfor(hModal);

      %--------------------------------------------------------------------
      function callback_end(source,event)
      %
      %   Callback function for end game uicontrols.
      %
      %--------------------------------------------------------------------

        delete(hModal);
        reset_game_data;
        updateMainFcn();
        set(hGame,'Visible','off');
        set(hMain,'Visible','on');
        drawnow;

      end

    end

    %----------------------------------------------------------------------
    function display_quit
    %
    %   Opens a modal window for quiting the game.
    %
    %----------------------------------------------------------------------

      % Create modal figure window:

      position = get(hGame,'Position');
      position = [position(1:2)+(position(3:4)-[260 200])./2 260 200];
      hModal = make_figure(position,'CloseRequestFcn',@callback_quit,...
                           'Name','End Game','Tag','FIGURE',...
                           'WindowStyle','modal');

      % Create uicontrol objects:

      make_panel(hModal,[1 1 260 200]);
      make_text(hModal,[11 171 160 20],'String','Do you want to...');
      make_text(hModal,[11 136 160 20],'HorizontalAlignment','right',...
                'String','...return to game?');
      make_button(hModal,[181 136 60 25],'Callback',@callback_quit,...
                  'String','Cancel','Tag','CANCEL');
      make_text(hModal,[11 96 160 20],'HorizontalAlignment','right',...
                'String','...forfeit game?');
      make_button(hModal,[181 96 70 25],'Callback',@callback_quit,...
                  'String','Forfeit','Tag','FORFEIT');
      make_text(hModal,[11 51 160 30],'HorizontalAlignment','right',...
                'String',{'...suspend game and','return to main menu?'});
      make_button(hModal,[181 56 60 25],'Callback',@callback_quit,...
                  'String','Return','Tag','RETURN');
      make_text(hModal,[11 11 160 30],'HorizontalAlignment','right',...
                'String',{'...suspend game and','quit Staker?'});
      make_button(hModal,[181 16 50 25],'Callback',@callback_quit,...
                  'String','Quit','Tag','QUIT');

      % Wait for window to be closed:

      set(hModal,'Visible','on');
      drawnow;
      waitfor(hModal);

      %--------------------------------------------------------------------
      function callback_quit(source,event)
      %
      %   Callback function for quit game uicontrols.
      %
      %--------------------------------------------------------------------

        switch get(source,'Tag'),

          case {'CANCEL','FIGURE'},

            delete(hModal);
            drawnow;

          case 'FORFEIT',

            delete(hModal);
            end_game;

          case 'QUIT',

            save(STATUS_FILE,'-struct','status','-mat');
            delete(hModal);
            delete(hMain);
            delete(hGame);
            drawnow;

          case 'RETURN',

            save(STATUS_FILE,'-struct','status','-mat');
            delete(hModal);
            reset_game_data;
            updateMainFcn();
            set(hGame,'Visible','off');
            set(hMain,'Visible','on');
            drawnow;

        end

      end

    end

  end

  %------------------------------------------------------------------------
  function display_help(hWindow)
  %
  %   Opens a modal window of help topics.
  %
  %------------------------------------------------------------------------

    % Initialize variables:

    helpFile = fopen(fullfile(STAKER_PATH,'help.txt'));
    helpText = {fgetl(helpFile)};
    while true,
      nextLine = fgetl(helpFile);
      if ischar(nextLine),
        helpText = [helpText; {nextLine}];
      else
        break;
      end
    end
    fclose(helpFile);

    % Create modal figure window:

    position = get(hWindow,'Position');
    position = [position(1:2)+(position(3:4)-[460 400])./2 460 400];
    hModal = make_figure(position,'CloseRequestFcn',@callback_help,...
                         'Name','Help','Tag','FIGURE',...
                         'WindowStyle','modal');

    % Create uicontrol objects:

    make_panel(hModal,[1 1 460 400]);
    make_panel(hModal,[10 45 442 347],'BackgroundColor',backColor,...
               'BorderType','beveledin');
    hText = make_text(hModal,[11 46 430 345],...
                      'BackgroundColor',backColor,'FontWeight','normal',...
                      'String','');
    helpText = textwrap(hText,helpText);
    switch get(hWindow,'Tag'),
      case 'STAKER_MAIN',
        helpIndex = strmatch('MAIN MENU:',helpText);
      case 'STAKER_PREFERENCES',
        helpIndex = strmatch('PREFERENCES:',helpText);
      case 'STAKER_SHOP',
        helpIndex = strmatch('ARMORY:',helpText);
      case 'STAKER_GAME',
        helpIndex = strmatch('GAME WINDOW:',helpText);
      otherwise,
        helpIndex = 1;
    end
    nRows = length(helpText);
    set(hText,'String',helpText(helpIndex:nRows));
    make_slider(hModal,[441 46 10 345],'Callback',@callback_help,...
                'Max',nRows-1,'SliderStep',[1 10]./(nRows-1),...
                'Tag','SLIDER','Value',nRows-helpIndex);
    make_button(hModal,[391 11 60 25],'Callback',@callback_help,...
                'String','Close','Tag','CLOSE');

    % Wait for window to be closed:

    set(hModal,'Visible','on');
    drawnow;
    waitfor(hModal);

    %----------------------------------------------------------------------
    function callback_help(source,event)
    %
    %   Callback function for help uicontrols.
    %
    %----------------------------------------------------------------------

      switch get(source,'Tag'),

        case {'CLOSE','FIGURE'},

          delete(hModal);

        case 'SLIDER',

          value = nRows-round(get(source,'Value'));
          set(hText,'String',helpText(value:nRows));

      end
      drawnow;

    end

  end

  %------------------------------------------------------------------------
  function bomb_error(hWindow,errorCode,varargin)
  %
  %   Display error message window.
  %
  %------------------------------------------------------------------------

    % Initialize text of error message:

    switch errorCode,
      case 'badFileContents',
        errorText = {['Contents of file ''',varargin{1},''' do not ',...
                      'match the required format for a ',varargin{2},...
                      ' file.']};
      case 'corruptedFile',
        errorText = {['Unable to load ''',varargin{1},''':']; ...
                     'File may be corrupted.'};
      case 'duplicateProfile',
        errorText = {['Profile ''',varargin{1},''' already loaded or ',...
                      'involved in a game.']};
      case 'emptyString',
        errorText = {['''',varargin{1},''' field cannot be empty.']};
      case 'invalidValue',
        errorText = {['Invalid value for ',varargin{1},' input.']};
      case 'oversizedString',
        errorText = {['''',varargin{1},''' field cannot have more ',...
                      'than ',num2str(MAX_CHARS),' characters.']};
      case 'wrongExtension',
        errorText = {[varargin{1},' operation failed:']; ...
                     ['File extension should be ''',varargin{2},'''.']};
    end

    % Create modal figure window:

    if ishandle(hWindow),
      position = get(hWindow,'Position');
    else
      position = [1 1 SCREEN_SIZE(3:4)];
      fontName = 'FixedWidth';
      fontSize = 10;
      textColor = [0.2 1 0.3];
      panelColor = [0.4 0.4 0.4];
      accentColor = [0.3 0.3 0.3];
    end
    position = [position(1:2)+(position(3:4)-[240 115])./2 240 115];
    hModal = make_figure(position,'CloseRequestFcn',@callback_error,...
                         'Name','Error','WindowStyle','modal');

    % Create uicontrol objects:

    make_panel(hModal,[1 1 240 115]);
    hAxes = make_axes(hModal,[11 66 30 30],'XLim',[-1 1],'YLim',[-1 1]);
    theta = 0:(pi/20):(2*pi);
    plot_patch(hAxes,cos(theta),sin(theta),[1 0 0]);
    plot_patch(hAxes,[0.3 0.6 0.3 0 -0.3 -0.6 -0.3 -0.6 -0.3 0 0.3 0.6],...
               [0 0.3 0.6 0.3 0.6 0.3 0 -0.3 -0.6 -0.3 -0.6 -0.3],...
               [1 1 1],'ZData',0.1.*ones(1,12));
    hText = make_text(hModal,[51 46 180 50]);
    set(hText,'String',textwrap(hText,errorText));
    make_button(hModal,[171 11 60 25],'Callback',@callback_error,...
                'String','Close');

    % Wait for window to be closed:

    set(hModal,'Visible','on');
    drawnow;
    waitfor(hModal);

    %----------------------------------------------------------------------
    function callback_error(source,event)
    %
    %   Callback function for error message uicontrols.
    %
    %----------------------------------------------------------------------

      delete(hModal);
      drawnow;

    end

  end

  %------------------------------------------------------------------------
  function add_game_data
  %
  %   Adds new structure of game data to current status.
  %
  %------------------------------------------------------------------------

    creationTime = clock;
    gameData = struct('startTime',creationTime,...
                      'lastPlayed',creationTime,'players',players,...
                      'currentPlayer',currentPlayer,'nMoves',nMoves,...
                      'locationIndex',locationIndex,...
                      'locationValue',locationValue,...
                      'mapGenerationState',mapGenerationState,...
                      'mapZ',mapZ,'mapC',mapC,'horizonZ',horizonZ,...
                      'edgeColor',edgeColor,'isWater',isWater,...
                      'waterLevel',waterLevel,'windVector',windVector,...
                      'timeOfDay',timeOfDay);
    status.suspendedGames = [status.suspendedGames gameData];

  end

  %------------------------------------------------------------------------
  function update_game_data
  %
  %   Updates current game data.
  %
  %------------------------------------------------------------------------

    status.suspendedGames(currentGame).lastPlayed = clock;
    status.suspendedGames(currentGame).players = players;
    status.suspendedGames(currentGame).currentPlayer = currentPlayer;
    status.suspendedGames(currentGame).nMoves = nMoves;
    status.suspendedGames(currentGame).mapZ = mapZ;
    status.suspendedGames(currentGame).mapC = mapC;

  end

  %------------------------------------------------------------------------
  function reset_game_data
  %
  %   Resets game data variables.
  %
  %------------------------------------------------------------------------

    currentGame = 0;
    profiles = cell(1,MAX_PLAYERS);
    players = [];
    nPlayers = 0;
    currentPlayer = 0;
    nMoves = 0;
    locationIndex = 1;
    locationValue = [];
    mapGenerationState = [];
    mapX = [];
    mapY = [];
    mapZ = [];
    mapC = [];
    horizonZ = [];
    edgeColor = [];
    isWater = false;
    waterLevel = [];
    windVector = [];
    timeOfDay = [];

  end

  %------------------------------------------------------------------------
  function gameString = game2str
  %
  %   Creates a cell array of strings from suspended game information.
  %
  %------------------------------------------------------------------------

    nGames = length(status.suspendedGames);
    gameString = cell(nGames,1);
    for i = 1:nGames,
      gameData = status.suspendedGames(i);
      names = {gameData.players.name};
      names = [names; repmat({'-vs-'},1,length(names)-1) {' '}];
      gameString{i} = [names{:},datestr(gameData.lastPlayed)];
    end

  end

  %------------------------------------------------------------------------
  function arsenal = num2arsenal(array)
  %
  %   Converts a vector of bomb quantities to an arsenal list.
  %
  %------------------------------------------------------------------------

    index = (array > 0);
    N = sum(index);
    bombs = reshape(sprintf('%11.10s',BOMB_DATA(index).name),11,N).';
    quantities = cellstr(reshape(sprintf(' %-4i',array(index)),5,N).');
    arsenal = strcat(bombs,' -',quantities);

  end

  %------------------------------------------------------------------------
  function hObject = make_axes(hParent,position,varargin)
  %
  %   Make an axes object.
  %
  %------------------------------------------------------------------------

    hObject = axes('Parent',hParent,'Units','pixels',...
                   'Position',position,'HandleVisibility','off',...
                   'Visible','off','XLim',[0 1],'XTick',[],'YLim',[0 1],...
                   'YTick',[],'ZLim',[-1 1],'ZTick',[],varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_button(hParent,position,varargin)
  %
  %   Make a uicontrol button object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','pushbutton','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',accentColor,...
                        'BusyAction','cancel','FontAngle','normal',...
                        'FontName',fontName,'FontUnits','pixels',...
                        'FontSize',fontSize,'FontWeight','normal',...
                        'ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','center',...
                        'Interruptible','off',varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_check(hParent,position,varargin)
  %
  %   Make a uicontrol checkbox object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','checkbox','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',panelColor,...
                        'BusyAction','cancel','FontAngle','normal',...
                        'FontName',fontName,'FontUnits','pixels',...
                        'FontSize',fontSize,'FontWeight','bold',...
                        'ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','center',...
                        'Interruptible','off','Max',1,'Min',0,'Value',0,...
                        varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_edit(hParent,position,varargin)
  %
  %   Make a uicontrol editable text object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','edit','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',backColor,...
                        'BusyAction','cancel','FontAngle','normal',...
                        'FontName',fontName,'FontUnits','pixels',...
                        'FontSize',fontSize,'FontWeight','normal',...
                        'ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','center',...
                        'Interruptible','off','Max',1,'Min',0,varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_figure(position,varargin)
  %
  %   Make a figure object.
  %
  %------------------------------------------------------------------------

    hObject = figure('Units','pixels','Position',position,...
                     'BusyAction','cancel','Color',panelColor,...
                     'DockControls','off','HandleVisibility','off',...
                     'IntegerHandle','off','Interruptible','on',... 
                     'MenuBar','none','NumberTitle','off',...
                     'Resize','off','Toolbar','none','Visible','off',...
                     varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_list(hParent,position,varargin)
  %
  %   Make a uicontrol listbox object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','listbox','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',backColor,...
                        'FontAngle','normal','FontName',fontName,...
                        'FontUnits','pixels','FontSize',fontSize,...
                        'FontWeight','normal',...
                        'ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','center','ListboxTop',1,...
                        'Max',1,'Min',0,'SliderStep',[1 3],'Value',1,...
                        varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_menu(hParent,position,varargin)
  %
  %   Make a uicontrol popup menu object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','popupmenu','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',backColor,...
                        'BusyAction','cancel','FontAngle','normal',...
                        'FontName',fontName,'FontUnits','pixels',...
                        'FontSize',fontSize,'FontWeight','normal',...
                        'ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','center',...
                        'Interruptible','off','Value',1,varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_panel(hParent,position,varargin)
  %
  %   Make a uipanel object.
  %
  %------------------------------------------------------------------------

    hObject = uipanel('Parent',hParent,'Units','pixels',...
                      'Position',position,'BackgroundColor',panelColor,...
                      'BorderType','beveledout','BorderWidth',1,...
                      'ForegroundColor',textColor,...
                      'HandleVisibility','off',...
                      'HighlightColor',[1 1 1],'ShadowColor',[0 0 0],...
                      varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_slider(hParent,position,varargin)
  %
  %   Make a uicontrol slider object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','slider','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',sliderColor,...
                        'BusyAction','cancel','HandleVisibility','off',...
                        'Interruptible','off','Max',1,'Min',0,...
                        'SliderStep',[1 3],'Value',0,varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = make_text(hParent,position,varargin)
  %
  %   Make a uicontrol text object.
  %
  %------------------------------------------------------------------------

    hObject = uicontrol('Style','text','Parent',hParent,...
                        'Units','pixels','Position',position,...
                        'BackgroundColor',panelColor,...
                        'FontAngle','normal','FontName',fontName,...
                        'FontUnits','pixels','FontSize',fontSize,...
                        'FontWeight','bold','ForegroundColor',textColor,...
                        'HandleVisibility','off',...
                        'HorizontalAlignment','left',varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = plot_line(hParent,xData,yData,zData,varargin)
  %
  %   Plot a line object.
  %
  %------------------------------------------------------------------------

    hObject = line(xData,yData,zData,'Parent',hParent,'Clipping','off',...
                   'Color',[0 0 0],'HandleVisibility','off',...
                   'LineStyle','-','LineWidth',1.5,'Marker','none',...
                   varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = plot_patch(hParent,xData,yData,cData,varargin)
  %
  %   Plot a patch object.
  %
  %------------------------------------------------------------------------

    hObject = patch('XData',xData,'YData',yData,'Parent',hParent,...
                    'EdgeColor','none','FaceColor',cData,...
                    'HandleVisibility','off','LineStyle','-',...
                    'LineWidth',1,varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = plot_surface(hParent,xData,yData,zData,cData,varargin)
  %
  %   Plot a surface object.
  %
  %------------------------------------------------------------------------

    hObject = surface(xData,yData,zData,cData,'Parent',hParent,...
                      'AmbientStrength',0.3,'BackFaceLighting','lit',...
                      'Clipping','off','DiffuseStrength',1,...
                      'EdgeColor','none','FaceColor','texturemap',...
                      'FaceLighting','gouraud','HandleVisibility','off',...
                      'SpecularStrength',0,varargin{:});

  end

  %------------------------------------------------------------------------
  function hObject = plot_text(hParent,xData,yData,zData,textData,varargin)
  %
  %   Plot a text object.
  %
  %------------------------------------------------------------------------

    hObject = text(xData,yData,zData,textData,'Parent',hParent,...
                   'BackgroundColor','none','Clipping','off',...
                   'Color',[0 0 0],'EdgeColor','none',...
                   'FontAngle','normal','FontName','FixedWidth',...
                   'FontUnits','pixels','FontSize',10,...
                   'FontWeight','bold','HandleVisibility','off',...
                   'HorizontalAlignment','center','Interpreter','none',...
                   'Rotation',0,'Units','data',...
                   'VerticalAlignment','middle',varargin{:});

  end

  %------------------------------------------------------------------------
  function data = default_preferences
  %
  %   Returns a structure of default preferences.
  %
  %------------------------------------------------------------------------

    data = struct('fontName','FixedWidth','fontSize',10,...
                  'textColor',[0.2 1 0.3],'backColor',[0 0 0],...
                  'panelColor',[0.4 0.4 0.4],...
                  'accentColor',[0.3 0.3 0.3],...
                  'sliderColor',[0.1 0.5 0.15],'azimuthGain',pi/400,...
                  'elevationGain',pi/800,...
                  'rotationGain',MAX_ROTATION_ANGLE/400,...
                  'zoomGain',1/200,'useLocalTime',false,...
                  'trajectoryStep',0.1,'blastStep',0.05);

  end

  %------------------------------------------------------------------------
  function data = default_player_data
  %
  %   Returns a structure of default player data.
  %
  %------------------------------------------------------------------------

    data = struct('version',BOMB_VERSION,'ID',round(rand*1e+16),...
                  'file','','name','','earnings',10000,'record',[0 0 0],...
                  'class','Dalek','unlocked',logical([1 1 1 0 0 0 0 0]),...
                  'arsenal',[inf zeros(1,7)],'used',zeros(1,8),...
                  'isCurrent',false,'capacity',100,'position',[],...
                  'settings',[],'camera',{{}});

  end

%~~~End nested functions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

end

%~~~Begin subfunctions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%--------------------------------------------------------------------------
function data = initialize_bomb_data
%
%   Returns a structure of bomb data.
%
%--------------------------------------------------------------------------

  data = struct('name',{'Vanilla'; 'Orca'; 'Sulidae'; 'Enhanced'; ...
                        'Leviathan'; 'Nemo'; 'Scythe'; 'ACoLYT'},...
                'radius',{0.5; 0.5; 0.5; 0.5; ...
                          0.5; 0.5; 0.5; 0.5},...
                'length',{10; 10; 10; 10; ...
                          10; 10; 10; 10},...
                'weight',{500; 500; 500; 500; ...
                          500; 500; 500; 500},...
                'drag',{0.25; 0.25; 0.25; 0.25; ...
                        0.25; 0.25; 0.05; 0.25},...
                'blastRadius',{400; 400; 400; 1000; ...
                               1000; 1000; 800; 3000},...
                'blastDamage',{20; 20; 20; 30; ...
                               30; 30; 30; 70},...
                'boosterForce',{0; 1500000; 0; 0; ...
                                1500000; 0; 0; 0},...
                'ignoreWater',{false; false; true; false; ...
                               false; true; false; false},...
                'cost',{0; 500; 500; 2000; ...
                        2500; 2500; 4000; 40000},...
                'unlockCondition',{zeros(1,12); ...
                                   zeros(1,12); ...
                                   zeros(1,12); ...
                                   [20 10 10 inf(1,9)]; ...
                                   [inf 10 inf(1,10)]; ...
                                   [inf inf 10 inf(1,9)]; ...
                                   [inf(1,11) 10]; ...
                                   [inf(1,11) 15]},...
                'description',{['Cheap and ubiquitous,... the ',...
                                '99-cent-store version of military ',...
                                'ordinance. Your employers are happy ',...
                                'to give you an endless supply of the ',...
                                'no-frills stuff. If you want ',...
                                'something better, you gotta buy it ',...
                                'yourself. If you got no money, you ',...
                                'better be a damn good shot!']; ...
                               ['Blasting missiles upwards through ',...
                                'hundreds of feet of water is not an ',...
                                'ideal situation, but you''ll surely ',...
                                'find yourself having to do it ',...
                                'sometime. This bomb has special ',...
                                'propulsion for giving you a top ',...
                                'speed under water of about 485 feet ',...
                                'per second, and can accelerate after ',...
                                'leaving the water to whatever ',...
                                'velocity you select.']; ...
                               ['Lovingly referred to as the "Booby ',...
                                'bomb", so named for the Blue-footed ',...
                                'Booby, a bird of the Eastern Pacific ',...
                                'that hunts for fish by dive-bombing ',...
                                'into the water from great heights. ',...
                                'If you''ve inadvertently submerged ',...
                                'your target by blowing a big crater ',...
                                'underneath him, you can reach him ',...
                                'with one of these projectiles, which ',...
                                'doesn''t blow up until it hits ',...
                                'bottom.']; ...
                               ['The good stuff, made with enhanced ',...
                                'high-yield explosives. That extra ',...
                                'punch gives you a little bit of ',...
                                'wiggle room in how close you have to ',...
                                'drop it near your enemy.']; ...
                               ['Stab at them from your watery grave! ',...
                                'This Orca with enhanced explosives ',...
                                'gives you a fighting chance to take ',...
                                'out your enemy, even when you''re ',...
                                'visiting Davy Jones'' locker.']; ...
                               ['An enhanced depth charge that lets ',...
                                'you reach further into the briny ',...
                                'deep. That''ll show those stupid ',...
                                'giant squids who''s boss!']; ...
                               ['The earth is a pretty harsh place ',...
                                'these days... habitable, but harsh. ',...
                                'Sometimes you have to launch ',...
                                'projectiles in a category 5 ',...
                                'hurricane. That''s when you need a ',...
                                'streamlined bomb with a reduced drag ',...
                                'coefficient.']; ...
                               ['Antimatter Core Low-Yield Tactical ',...
                                'nuclear weapon. Although "low-yield" ',...
                                'might be a misnomer... perhaps ',...
                                '"lowER-yield", since this weapon ',...
                                'contains a smaller serving of ',...
                                'antimatter than the full-scale ',...
                                'version.']});

end

%--------------------------------------------------------------------------
function data = staker_data(stakerClass)
%
%   Returns a structure of staker data for a given staker class.
%
%--------------------------------------------------------------------------

  switch stakerClass,
    case 'Dalek',
      theta = (pi/8).*(1:2:17);
      phi = (pi/8).*(0:4).';
      temp = 140.*cos(phi);
      [X,Y,Z] = cylinder([1 1],8);
      data = struct('X',[zeros(1,9); ...
                         200  160 -160 -200 -200 -160  160  200  200; ...
                         160  120 -120 -160 -160 -120  120  160  160; ...
                         temp*cos(theta)],...
                    'Y',[zeros(1,9); ...
                         160  200  200  160 -160 -200 -200 -160  160; ...
                         120  160  160  120 -120 -160 -160 -120  120; ...
                         temp*sin(theta)],...
                    'Z',[zeros(2,9); 240.*ones(1,9); ...
                         (140.*sin(phi)+260)*ones(1,9)],...
                    'turretXYZ',[0 0 270],...
                    'barrelXYZ',[10.*X(:) 10.*Y(:) 300.*Z(:)]);
  end

end

%--------------------------------------------------------------------------
function rho = air_density(altitude)
%
%   Computes air density at a given altitude (lb/ft^3).
%
%--------------------------------------------------------------------------

  layerHeights = [0 36089.24 65616.79 104986.87 154199.48 167322.83 ...
                  232939.63 inf];
  switch (find((layerHeights >= altitude),1)-1),
    case {0,1},
      rho = 0.076474*(1-altitude/145442.16)^4.255876;
    case 2,
      rho = 0.0227186*exp(0.00004806343*(36089.24-altitude));
    case 3,
      rho = 0.0054958*(710793.96/(645177.17+altitude))^35.163195;
    case 4,
      rho = 0.0008256085*(267915.73/(162928.86+altitude))^13.20114;
    case 5,
      rho = 0.0000891178*exp(0.00003847383*(154199.48-altitude));
    case 6,
      rho = 0.000053788*(1.52762-altitude/317128.33)^11.20114;
    case 7,
      rho = 0.000004008555*(1.661542-altitude/352116.14)^16.081597;
  end

end

%--------------------------------------------------------------------------
function rho = water_density(depth)
%
%   Computes water density at a given depth (lb/ft^3).
%
%--------------------------------------------------------------------------

  rho = 64.2235;

end

%--------------------------------------------------------------------------
function moneyString = num2money(value)
%
%   Converts a numeric value to a monetary value string.
%
%--------------------------------------------------------------------------

  moneyString = sprintf(',%c%c%c',fliplr(num2str(round(abs(value)))));
  moneyString = ['$',fliplr(moneyString(2:end))];
  if (value < 0),
    moneyString = ['-',moneyString];
  end

end

%--------------------------------------------------------------------------
function rgbVector = str2rgb(colorString)
%
%   Converts a string representation of a color to an RGB triple.
%
%--------------------------------------------------------------------------

  expression = {'yellow','magenta','cyan','red','green','blue','white',...
                'black','y','m','c','r','g','b','w','k','[^ \-\.0-9]'};
  replace = {'[1 1 0]','[1 0 1]','[0 1 1]','[1 0 0]','[0 1 0]',...
             '[0 0 1]','[1 1 1]','[0 0 0]','[1 1 0]','[1 0 1]',...
             '[0 1 1]','[1 0 0]','[0 1 0]','[0 0 1]','[1 1 1]',...
             '[0 0 0]',' '};
  rgbVector = sscanf(regexprep(colorString,expression,replace),'%f').';
  if ((numel(rgbVector) ~= 3) || any((rgbVector < 0) | (rgbVector > 1))),
    rgbVector = nan;
  end

end

%--------------------------------------------------------------------------
function isWithin = within_axes(point,position)
%
%   Determines if a point is within an axes region.
%
%--------------------------------------------------------------------------

  isWithin = ((point(1) >= position(1)) && ...
              (point(2) >= position(2)) && ...
              (point(1) <= sum(position([1 3]))) && ...
              (point(2) <= sum(position([2 4]))));

end

%--------------------------------------------------------------------------
function value = normrand(sizeArray,minLimit,maxLimit)
%
%   Generates a Gaussian random variate within a given range.
%
%--------------------------------------------------------------------------

  value = sqrt(-2.*log(rand(sizeArray))).*sin(2*pi.*rand(sizeArray));
  value = min(max(value,minLimit),maxLimit);

end

%--------------------------------------------------------------------------
function A = unit(A)
%
%   Normalizes the length of a vector to 1.
%
%--------------------------------------------------------------------------

  nA = norm(A);
  if (nA > 0),
    A = A./nA;
  end

end

%--------------------------------------------------------------------------
function C = cross(A,B)
%
%   Computes the cross product of two vectors.
%
%--------------------------------------------------------------------------

  C = [A(2)*B(3)-A(3)*B(2) A(3)*B(1)-A(1)*B(3) A(1)*B(2)-A(2)*B(1)];

end

%--------------------------------------------------------------------------
function R = rotation_matrix(theta,rotationAxis)
%
%   Function for computing a rotation transformation matrix (x'=x*R).
%
%--------------------------------------------------------------------------

  C = cos(theta);
  S = sin(theta);
  OMC = 1.0-C;
  uX = rotationAxis(1);
  uY = rotationAxis(2);
  uZ = rotationAxis(3);
  R = [C+uX^2*OMC      uX*uY*OMC+uZ*S  uX*uZ*OMC-uY*S; ...
       uX*uY*OMC-uZ*S  C+uY^2*OMC      uY*uZ*OMC+uX*S; ...
       uX*uZ*OMC+uY*S  uY*uZ*OMC-uX*S  C+uZ^2*OMC     ];

end

%--------------------------------------------------------------------------
function filterMatrix = make_filter(R)
%
%   Function for creating a disk-shaped image filter matrix of radius R.
%
%--------------------------------------------------------------------------

  RR = R*R;
  intR = ceil(R-0.5);
  [X,Y] = meshgrid(-intR:intR);
  maxXY = max(abs(X),abs(Y));
  minXY = min(abs(X),abs(Y));
  temp1 = (maxXY+0.5).^2;
  temp2 = (maxXY-0.5).^2;
  temp3 = (minXY+0.5).^2;
  temp4 = (minXY-0.5).^2;
  m1 = (RR < temp1+temp4);
  m1 = m1.*(minXY-0.5)+(~m1).*sqrt(RR-temp1);
  m2 = (RR > temp2+temp3);
  m2 = m2.*(minXY+0.5)+(~m2).*sqrt(RR-temp2);
  temp1 = temp1+temp3;
  temp2 = ((RR < temp1) & (RR > temp2+temp4));
  temp3 = asin(m2./R);
  temp4 = asin(m1./R);
  filterMatrix = ((m1-m2).*(maxXY-0.5)+(m1-minXY+0.5)+...
                  0.5*RR.*(temp3-temp4+0.5.*(sin(2.*temp3)-...
                                             sin(2.*temp4)))).*... 
                 (temp2 | ((minXY == 0) & (maxXY-0.5 < R) & ...
                           (maxXY+0.5 >= R)));
  filterMatrix = filterMatrix+(temp1 < RR);
  filterMatrix(intR+1,intR+1) = min(pi*RR,pi/2);
  if ((intR > 0) && (R > intR-0.5) && (RR < (intR-0.5)^2+0.25)), 
    m1 = sqrt(RR-(intR-0.5)^2);
    m2 = asin(m1/R);
    temp1 = RR*(m2+0.5*sin(2*m2))-2*m1*(intR-0.5);
    nFilter = 2*intR+1;
    index = [intR+1 nFilter*intR+1 nFilter*(intR+1) nFilter*nFilter-intR];
    filterMatrix(index) = temp1;
    index = index+[nFilter 1 -1 -nFilter];
    filterMatrix(index) = filterMatrix(index)-temp1;
  end
  filterMatrix(intR+1,intR+1) = min(filterMatrix(intR+1,intR+1),1);
  filterMatrix = filterMatrix./sum(filterMatrix(:));

end

%--------------------------------------------------------------------------
function imageMatrix = filter_image(imageMatrix,filterMatrix)
%
%   Function for filtering an image matrix.
%
%--------------------------------------------------------------------------

  % Initialize variables:

  [rImage,cImage,dImage] = size(imageMatrix);
  [rFilter,cFilter] = size(filterMatrix);
  rPad = ceil((rFilter-1)/2);
  cPad = ceil((cFilter-1)/2);
  filterMatrix = flipud(fliplr(filterMatrix));

  % Pad edges of image matrix:

  imageMatrix = [repmat(imageMatrix(1,1,:),rPad,cPad) ...
                 repmat(imageMatrix(1,:,:),rPad,1) ...
                 repmat(imageMatrix(1,cImage,:),rPad,cPad); ...
                 repmat(imageMatrix(:,1,:),1,cPad) ...
                 imageMatrix ...
                 repmat(imageMatrix(:,cImage,:),1,cPad); ...
                 repmat(imageMatrix(rImage,1,:),rPad,cPad) ...
                 repmat(imageMatrix(rImage,:,:),rPad,1) ...
                 repmat(imageMatrix(rImage,cImage,:),rPad,cPad)];

  % Change image type, if necessary:

  imageClass = class(imageMatrix);
  if (~strcmp(imageClass,'double')),
    imageMatrix = double(imageMatrix);
  end

  % Filter image:

  if (dImage == 1),
    imageMatrix = conv2(imageMatrix,filterMatrix,'same');
  else
    imageMatrix(:,:,1) = conv2(imageMatrix(:,:,1),filterMatrix,'same');
    imageMatrix(:,:,2) = conv2(imageMatrix(:,:,2),filterMatrix,'same');
    imageMatrix(:,:,3) = conv2(imageMatrix(:,:,3),filterMatrix,'same');
  end

  % Change image back to original type:

  switch imageClass,
    case 'double',
      % Do-nothing case
    case 'logical',
      imageMatrix = (imageMatrix > 0.5);
    otherwise,
      imageMatrix = cast(imageMatrix,imageClass);
  end

  % Remove padding:

  imageMatrix = imageMatrix((rPad+1):(rImage+rPad),...
                            (cPad+1):(cImage+cPad),:);

end

%--------------------------------------------------------------------------
function imageMatrix = resize_mask(imageMatrix,scale)
%
%   Function for resizing a binary image mask (nearest-neighbor method).
%
%--------------------------------------------------------------------------

  % Initialize variables:

  oldSize = size(imageMatrix);
  newSize = max(floor(scale.*oldSize),1);
  scale = [scale scale];
  invMatrix = inv([scale(2) 0 0; 0 scale(1) 0; 0.5.*(1-scale([2 1])) 1]);
  invMatrix(:,3) = [0; 0; 1];

  % Resample matrix:

  temp = [(1:newSize(2)).' ones(newSize(2),2)]*invMatrix;
  colIndex = min(round(temp(:,1)),oldSize(2));
  temp = [ones(newSize(1),1) (1:newSize(1)).' ...
          ones(newSize(1),1)]*invMatrix;
  rowIndex = min(round(temp(:,2)),oldSize(1));
  imageMatrix = imageMatrix(rowIndex,colIndex,:);

end

%--------------------------------------------------------------------------
function binaryMask = dilate_mask(binaryMask,filterElement)
%
%   Function for dilating a binary image mask.
%
%--------------------------------------------------------------------------

  binaryMask = filter_image(binaryMask,sign(filterElement));

end

%~~~End subfunctions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~