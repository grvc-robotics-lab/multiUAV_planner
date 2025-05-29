function [bases_pos, bases_names, zoneUTM] = kmlBases(kmlFile)
%% The kml file should be done by multyples paths unify into a Multi Geometry
% Select all the paths of the mision and click secondary botton. 

%% Obtain text
formatSpec = '%c';
fileID = fopen(kmlFile, 'r');
text_original = fscanf(fileID, '%c', Inf);
fclose(fileID);
%% PATHS
% Extract each path
text = extractBetween(text_original, "<Placemark>", "</Placemark>");
% bases_names = []; 
bases_names ={};
n_bases = length(text); 
bases_pos = []; 
for n = 1:n_bases
    % Extract text of the base n
    base_text = text{n};
    % Save the name of the base
    base_name = extractBetween(base_text, "<name>", "</name>");
    bases_names = [bases_names; base_name{1}];
    %Extract coordinates
    coordinates =  extractBetween(base_text, "<coordinates>", "</coordinates>"); 
    coordinates = split(coordinates, ","); 
    longitude = coordinates{1};
    latitude = coordinates{2};
    elevation = coordinates{3}; 
    %Transform coordinates into numbers
    longitude = str2double(longitude); 
    latitude= str2double(latitude); 
    elevation = str2double(elevation); 
    %Change to UTM
     [N, E, zone]= ll2utm_fcn(latitude, longitude); 
    %Save base position
    bases_pos= [bases_pos; [N, E, elevation]];
end
zoneUTM = zone(1);
end

