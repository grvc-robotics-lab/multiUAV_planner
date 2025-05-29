%% ===================================================================== %%
%                        Electric Power (Descent)                         %
% ======================================================================= %

function Pe = epower_descent(param,vc)

if vc>0
    error('ERROR: descent velocity >= 0')
end

% Induced power Pi  [W]:
T   = param.m*param.g/param.nr;            % thrust                   [N]
vi0 = sqrt(T/(2*param.rho*pi*param.R^2));  % induced velocity (hover) [m/s]

if vc/vi0<=-2
    % Windmill brake state:
    vi = ( -0.5*(vc/vi0)-sqrt(0.25*(vc/vi0)^2-1) )*vi0; % induced velocity (descent) [m/s]
else
    % Vortex ring state + turbulent wake state:
    k0 = 1;     k1 = -1.125;     k2 = -1.372;     k3 = -1.718;     k4 = -0.655;
    vi = ( k0 + k1*(vc/vi0) + k2*(vc/vi0)^2 +k3*(vc/vi0)^3+k4*(vc/vi0)^4 )*vi0; % induced velocity (descent) [m/s]
end
Pi = param.kappa*T*vi;

% Profile power P0 (blade-section drag dependent)  [W]:
omega = sqrt(6*T/(param.rho*param.b*param.c*param.R^3*param.Cl));  % rotor speed  [rad/s]
P0    = param.rho*param.R^4*omega^3*param.b*param.c*param.Cd/8;

% Climb power Pc  [W]:
Pc = T*vc;

% Total aerodynamic power Pa  [W]:
Pa = param.nr*(Pi+P0+Pc);

if Pa<0, Pa=0; end % The batteries cannot absorb energy

% Electric power  [W]:
Pe = Pa/param.eta;

%=========================================================================%