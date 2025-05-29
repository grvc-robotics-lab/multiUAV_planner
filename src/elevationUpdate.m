function towers_utm_updated = elevationUpdate(towers_utm, zone)
%% Transform from utm to ll
[lat,lon] = utm2ll_fcn(towers_utm(:,1), towers_utm(:,2), zone);
towers_ll = [lat,lon];
towers_utm_updated = [];
for j = 1:ceil(size(towers_ll,1)/100)
    %% Obtain towers to each request
    if j == ceil(size(towers_ll,1)/100) % Last request
        towers_request = towers_ll(1+100*(j-1):end,:);
    else
        towers_request = towers_ll(1+100*(j-1):100*j,:);
    end
    n_towers_request = size(towers_request,1); 
    init_t = 1+100*(j-1); 
    end_t = init_t + n_towers_request-1; 
    %% Create the request
    % Others possible apis:
    %   -google_api = 'https://maps.googleapis.com/maps/api/elevation/json?locations='
    %   -openTopoData_api = 'https://api.opentopodata.org/v1/eudem25m?locations='
    %   -url = 'https://api.open-elevation.com/api/v1/lookup?locations=';
    url = 'https://api.opentopodata.org/v1/eudem25m?locations=';
    webOpt = weboptions('Timeout',10, 'RequestMethod', 'get');
    towers_string = '';
    for i = 1:n_towers_request
        towers_string = towers_string+string(towers_request(i,1))+','+string(towers_request(i,2))+'|';
    end
    request = url +towers_string; 
    data = webread(request);
    
    %% Save data 
    elevation = []; 
    for i = 1:n_towers_request
        elevation = [elevation; data.results(i).elevation]; 
    end
    %% Group results
    towers_utm_updated = [towers_utm_updated; towers_utm(init_t:end_t,1), towers_utm(init_t:end_t,2),elevation];
    pause(1); % A delay that the api demands
end
end

