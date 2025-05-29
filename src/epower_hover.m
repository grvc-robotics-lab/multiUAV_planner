%% ===================================================================== %%
%                         Electric Power (Hover)                          %
% ======================================================================= %

function Pe = epower_hover(param)

% Induced power Pi  [W]:
T  = param.m*param.g/param.nr;            % thrust           [N]
vi = sqrt(T/(2*param.rho*pi*param.R^2));  % induced velocity [m/s]
Pi = param.kappa*T*vi;

% Profile power P0 (blade-section drag dependent)  [W]:
omega = sqrt(6*T/(param.rho*param.b*param.c*param.R^3*param.Cl));  % rotor speed  [rad/s]
P0    = param.rho*param.R^4*omega^3*param.b*param.c*param.Cd/8;

% Total aerodynamic power Pa  [W]:
Pa = param.nr*(Pi+P0);

% Electric power  [W]:
Pe = Pa/param.eta;

%=========================================================================%