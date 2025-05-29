function kmlGen(mission_name, mission_description, wp, bases_names)
n_UAVs = length(wp);
width = 5;
color = {"ffff0000";"ff00ff00"; "ff0000ff";"ff00ffff"};  ; % format ABGR

if ~exist('./mission', 'dir')
    mkdir('./mission');
end

fileName = "./mission/mission_"+mission_name+".kml";
fileID=fopen(fileName,'w+');

%% SPECIAL SYMBOL
dq = char(34);  % Double quotes '"'
%% HEADER
fprintf(fileID, '<?xml version="1.0" encoding="UTF-8"?>');
fprintf(fileID, '\n');
fprintf(fileID,'<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">\n');
%% DOCUMENT
fprintf(fileID, '\n<Document>\n');
fprintf(fileID, '	<name>'+fileName+'</name>\n');

%% FOLDER
fprintf(fileID, '\t<Folder>\n');
fprintf(fileID, '%s', mission_name);

for UAV = 1:n_UAVs;
    fprintf(fileID, '\n');
    fprintf(fileID, '\t\t\t<Placemark>\n');
    fprintf(fileID, '\t\t\t<name>%s</name>\n', bases_names{UAV}); 
    %%% STYLE
    fprintf(fileID, '\t\t<Style>\n');
    fprintf(fileID, '\t\t\t<LineStyle>\n');
    fprintf(fileID, '\t\t\t\t<color>%s</color> <!-- Color en formato ABGR (alfa, azul, verde, rojo) -->\n', color{UAV});
    fprintf(fileID, '\t\t\t\t<width>%d</width> <!-- Grosor de la línea -->\n', width);
    fprintf(fileID, '\t\t\t</LineStyle>\n');
    fprintf(fileID, '\t\t\t</Style>\n');
    fprintf(fileID, '\t\t\t<LineString>\n');
    fprintf(fileID, '\t\t\t\t<coordinates>\n');
    %% Points
    wp_UAV = wp{UAV};
    n_wp = size(wp_UAV, 1);
    for i = 1: n_wp
        fprintf(fileID, '\t\t\t\t%.8f,%.8f,%.8f\n', wp_UAV(i,2), wp_UAV(i,1), wp_UAV(i,3));
    end
    fprintf(fileID, '\t\t\t\t</coordinates>\n');
    fprintf(fileID, '\t\t\t</LineString>\n');
    fprintf(fileID, '\t\t</Placemark>\n');

end


%% CLOSE EVERYTHING
fprintf(fileID, '\t</Folder>\n');
fprintf(fileID, '</Document>\n');
fprintf(fileID, '</kml>');

fclose(fileID);
end