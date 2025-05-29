
function air_density = airDensity(temperature, humidity, pressure)
                            %Temperature -> ºC
                            % Humidity -> % 
                            % Pressure -> Pa
% temp = temperature + 273.15; % [K]
temp = temperature;
pressure = pressure/1000;
% Saturation vapor pressure at given temperature
p1 = 6.1078*10^(7.5*temp/(temp+273.3)); % [Pa]
% Vapor pressure
pv = p1 * humidity/100; % [Pa] 
% Pressure of dry air
pd = pressure - pv;  % [Pa]
% Specific gas constant for dry air
Rd = 287.058; % [J/(kg·K)]
% Specific gas constant for water vapor equal to 
Rv = 461.495; % [J/(kg·K)]

air_density = ((pd/(Rd*temp)) + (pv/(Rv*temp)))*100;  % Pa/[J/kg] = [Pa*kg / J ]
                                                    %1.1176                                            %  [kg/m^3]
                                                                                                % Pa / J = m 3  
end