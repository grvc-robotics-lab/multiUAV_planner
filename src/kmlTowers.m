function [towers, grid_connection] = kmlTowers(kmlFile, offset_tower)
%% The kml file should be done by multyples paths unify into a Multi Geometry
% Select all the paths of the mision and click secondary botton. 

%% Default offset to unify towers
if nargin < 3
    offset_tower = 10; 
end
%% Obtain text
formatSpec = '%c';
fileID = fopen(kmlFile, 'r');
text_original = fscanf(fileID, '%c', Inf);
fclose(fileID);
%% Paths
% Extract each path
lines_str = extractBetween(text_original, "<coordinates>", "</coordinates>");
lines={};
n_lines = length(lines_str); 
towers = []; 
grid_connection=[]; 
for n = 1:n_lines
    line = lines_str{n,1};
    %Erase line feed
    line = erase(line, char(10)); 
    line = erase(line, char(13)); 
    %Erase tab
    line = erase(line, char(9)); 
    line = split(line, ' '); 
    %Erase any empty cell
    line = line(~cellfun(@isempty,line)); 
    line = split(line, ','); 
    line = str2double(line);
    %Change to UTM
    [N, E, zoneUTM]= ll2utm_fcn(line(:,2), line(:,1));
    % elevation = zeros(size(N)); 
    elevation = line(:,3);
    lines = [lines;[N,E,elevation ]];
end
%% Save towers
 towers = lines{1}; 
 n_towers = length(towers); 
 %Save the first branch connection
 grid_connection = [1:n_towers-1; 2:n_towers]';
 for n = 2:n_lines
    line  = lines{n};
    connection_nodes = []; 
    % Detect nodes taht are on more than one branch
    for nt = 1:length(line)
        dist_v = towers - line(nt,:);
        dist = hypot(dist_v(:,1), dist_v(:,2));
        connection_nodes  = [connection_nodes , dist < offset_tower]; 
    end
    [t, l]= find(connection_nodes==1); 
    towers=[towers; line(~any(connection_nodes), :)]; 
    new_tower = max(max(grid_connection))+1; 
    j = 1; 
    for i=1:length(line) -1
        if any(i == l) && ~any(i+1==l)  %Node i is a connection node and node i+1 isnt
            grid_connection = [grid_connection; [t(j), new_tower]];
            j=j+1; 
        elseif any(i+1 == l) && ~any(i==l)%Node i+1 is a connection node and node i isnt
            grid_connection = [grid_connection; [new_tower, t(j)]]; 
            new_tower=new_tower + 1; 
        elseif any(i+1 == l) && any(i==l) %Node i and node i+1 are connection node 
            grid_connection = [grid_connection; [t(j),t(j+1)]]; 
            j=j+1;
        else    %Node i and node i+1 arent a connection node
                grid_connection = [grid_connection; [new_tower, new_tower+1]]; 
                new_tower = new_tower+1; 
            end
    end
 end
end

