function [wind_vel, wind_direction, humidity, temperature, pressure] = weatherApi(utm, zone)
%% Transform coordinates
[lat,lon] = utm2ll_fcn(utm(1), utm(2), zone);

%% WEATHER API
% https://www.weatherapi.com/docs/
%% Create request
apiKey = 'f4e4e58c9c0c4492aeb144023231005'; 
request = append('http://api.weatherapi.com/v1/current.json?key=',apiKey,'&q=',num2str(lat),',',num2str(lon),'&aqi=no');
webOpt = weboptions('Timeout',1000, 'RequestMethod', 'get');
data = webread(request);

%% Load data
wind_vel = data.current.wind_kph*1000/3600;          % [m/s]
wind_direction= data.current.wind_degree;            % [º] 
humidity = data.current.humidity;                    % [%]
temperature = data.current.temp_c;                   % [ºC]
pressure = data.current.pressure_mb*100;             % [Pa] 


end