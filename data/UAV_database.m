%% _______Don't touch___________
bats ={};
UAVs_model={}; 
%% ________________________________


%% UAV template
% %% --- MODEL 1 UAV ---
% UAV.name = "model 1"; 
% UAV.category = 0;    % 0 = multirotor, 1 = fixed_wing, 2 = v-toll
% % Mass and geometry:
% UAV.m      = 7.2;     % total mass                  [kg]
% UAV.nr     = 4;       % number of rotors            [-]
% UAV.b      = 2;       % number of rotor blades      [-]
% UAV.R      = 0.2667;  % rotor radius                [m]
% UAV.c      = 0.0247;  % blade chord (x=0.7*R)       [m]
% % Aerodynamics:
% UAV.Cl     = 1.01;    % section lift coefficient    [-]
% UAV.Cd     = 0.01;    % section drag coefficient    [-]
% UAV.kappa  = 1.15;    % induced power factor        [-]
% UAV.eta    = 0.72;    % energy efficiency           [-]
% UAV.K_mu   = 4.65;    % P0 numerical constant       [-]
% UAV.f      = 0.35;    % equivalent flat-plate area  [m^2]
% UAV.camera = 1;       % If need camera actions. 1 == yes, 0 == no 
% % Planning: 
% UAV.max_gradiant_climb   = pi/180;       % Max angle can climb the UAV. Inf for multirotor  [rad]
% UAV.radius_turn          = 0;            % Minimun radius that UAV can turn [m]
%UAV=[UAV; UAV];


%% ---BATTERY M210---

bat.name = "Battery M210";
bat.capacity = 2*7660; %capacity [mAh]
bat.cells = 1; 
bat.volt = 22.8; % voltage/cell [V/cell]
bats=[bats; bat];


%% ---BATTERY M300---
bat.name = "Battery M300";
bat.capacity = 5935*2; %capacity [mAh]
bat.cells = 1; 
bat.volt = 52.8; % voltage/cell [V/cell]
bats=[bats;bat];


%% --- MODEL 1 UAV ---
UAV.name = "M210"; 
UAV.category = 0;    % 0 = multirotor, 1 = fixed_wing, 2 = v-toll
% Mass and geometry:
UAV.m      = 5.15;     % total mass                  [kg]
UAV.nr     = 4;       % number of rotors            [-]
UAV.b      = 2;       % number of rotor blades      [-]
UAV.R      = 0.214;  % rotor radius                [m]
UAV.c      = 0.01991;  % blade chord (x=0.7*R)       [m]

% Aerodynamics:
UAV.Cl     = 1.01;    % section lift coefficient    [-]
UAV.Cd     = 0.008;    % section drag coefficient    [-]
UAV.kappa  = 1.15;    % induced power factor        [-]
UAV.eta    = 0.68;    % energy efficiency           [-]

UAV.K_mu   = 4.65;    % P0 numerical constant       [-]
UAV.f      = 0.27;    % equivalent flat-plate area  [m^2]
UAV.camera = 1;       % If need camera actions. 1 == yes, 0 == no 
% % Planning: 
UAV.max_gradiant_climb   = inf*pi/180;       % Max angle can climb the UAV. Inf for multirotor  [rad]
UAV.radius_turn          = 0;       % Minimun radius that UAV can turn [m]
UAV.distance_take_off    = 200; 
UAV.height_take_off      = 100; 
UAVs_model=[UAVs_model; UAV];

%% --- MODEL 2 UAV ---
UAV.name = "M300"; 
UAV.category = 0;    % 0 = multirotor, 1 = fixed_wing, 2 = v-toll
% Mass and geometry:
UAV.m      = 6.30;     % total mass                  [kg]
UAV.nr     = 4;       % number of rotors            [-]
UAV.b      = 2;       % number of rotor blades      [-]
UAV.R      = 0.2667;  % rotor radius                [m]
UAV.c      = 0.0247;  % blade chord (x=0.7*R)       [m]

% Aerodynamics:
UAV.Cl     = 1.01;    % section lift cuoefficient    [-]
UAV.Cd     = 0.01;    % section drag coefficient    [-]
UAV.kappa  = 1.15;    % induced power factor        [-]
UAV.eta    = 0.72;    % energy eelciency           [-]

UAV.K_mu   = 4.65;    % P0 numerical constant       [-]
UAV.f      = 0.35;    % equivalent flat-plate area  [m^2]
UAV.camera = 1;       % If need camera actions. 1 == yes, 0 == no 
% Planning: 
UAV.max_gradiant_climb   = 8*pi/180;       % Max angle can climb the UAV. Inf for multirotor  [rad]
UAV.radius_turn          = 80;             % Minimun radius that UAV can turn [m]
UAV.distance_take_off    = 200; 
UAV.height_take_off      = 87; 
UAV.distance_land     = 200;
UAV.height_land       = 87; 
UAVs_model=[UAVs_model; UAV];

