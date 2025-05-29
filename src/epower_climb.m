%% ===================================================================== %%
%                         Electric Power (Climb)                          %
% ======================================================================= %

function Pe = epower_climb(param,vc)

if vc<0
    error('ERROR: climb velocity <= 0')
end

% Induced power Pi  [W]:
T   = param.m*param.g/param.nr;                       % thrust                   [N]
vi0 = sqrt(T/(2*param.rho*pi*param.R^2));             % induced velocity (hover) [m/s]
vi  = ( -0.5*(vc/vi0)+sqrt(0.25*(vc/vi0)^2+1) )*vi0;  % induced velocity (climb) [m/s]
Pi  = param.kappa*T*vi;

% Profile power P0 (blade-section drag dependent)  [W]:
omega = sqrt(6*T/(param.rho*param.b*param.c*param.R^3*param.Cl));  % rotor speed  [rad/s]
P0    = param.rho*param.R^4*omega^3*param.b*param.c*param.Cd/8;

% Climb power Pc  [W]:
Pc = T*vc;

% Total aerodynamic power Pa  [W]:
Pa = param.nr*(Pi+P0+Pc);

% Electric power  [W]:
Pe = Pa/param.eta;

%=========================================================================%