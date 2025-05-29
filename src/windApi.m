function wind = windApi(utm, zone)
% wind is a vector of [force, angle (N is 0º)]
%% should enter utm and converse inside to lle
[lat,lon] = utm2ll_fcn(utm(1), utm(2), zone);

%% WEATHER API
% https://www.weatherapi.com/docs/
apiKey = 'f4e4e58c9c0c4492aeb144023231005'; 
request = append('http://api.weatherapi.com/v1/current.json?key=',apiKey,'&q=',num2str(lat),',',num2str(lon),'&aqi=no');
webOpt = weboptions('Timeout',1000, 'RequestMethod', 'get');
data = webread(request);
data.current.wind_dir;
wind = [data.current.wind_kph*1000/3600, (data.current.wind_degree*pi/180)];% + 3*pi/4];
end