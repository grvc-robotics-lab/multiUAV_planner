%% ===================================================================== %%
%                     Electric Power (Forward flight)                     %
% ======================================================================= %

function Pe = epower_forward(param,vf)

% Induced power Pi  [W]:
D       = 0.5*param.rho*vf^2*param.f;               % fuselage drag            [N]
alpha_r = atan(D/(param.m*param.g));                % angle of attack (rotor)  [rad]
T       = param.m*param.g/(param.nr*cos(alpha_r));  % thrust                   [N]
vi      = fzero(@(x) (x-vf*sin(alpha_r))*(2*param.rho*pi*param.R^2*sqrt((vf*cos(alpha_r))^2+x^2))-T , vf) - vf*sin(alpha_r); % induced velocity [m/s]
Pi      = param.kappa*T*vi;

% Profile power P0 (blade-section drag dependent)  [W]:
omega = sqrt(6*T/(param.rho*param.b*param.c*param.R^3*param.Cl)-3/2*(vf*cos(alpha_r)/param.R)^2);  % rotor speed  [rad/s]
P0    = param.rho*param.R^4*omega^3*param.b*param.c*param.Cd/8*(1+param.K_mu*(vf*cos(alpha_r)/(omega*param.R))^2);

% Parasite power Pf (fuselage-drag dependent) [W]:
Pf = D*vf;

% Total aerodynamic power Pa  [W]:
Pa = param.nr*(Pi+P0)+Pf;

% Electric power  [W]:
Pe = Pa/param.eta;

%=========================================================================%