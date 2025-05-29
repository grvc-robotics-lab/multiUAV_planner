
function [tours, n_tours] = find_subtour(x, edges, n_UAVs, base_station)
    
if n_UAVs == 1
    edges_opt=[];
    n_edges=size(edges,1);
    UAV = edges(1,3); 
    % Build edges optimal tours
    for i=1:n_edges
        if x(i)
            edges_opt=[edges_opt; edges(i,1:2)];
        end
    end
    tours = {};
    tour = []; 
    current_node = base_station; 
    
    while sum(sum(edges_opt)) > 0
        path = find(edges_opt(:,1) == current_node, 1, 'first');
        tour = [tour; edges_opt(path, :)];
        current_node = edges_opt(path,2);
        edges_opt(path, :) = [0 0];
        if current_node == tour(1)
            tours = [tours; tour];
            tour = [];
            if sum(sum(edges_opt)) > 0
                current_node = edges_opt(find(edges_opt(:,1) ~= base_station,1, 'first'),1);
            end
        end
    end

    n_tours = length(tours);

    for i = 2:n_tours
        tour_base = tours{1}; 
        tour = tours{i};
        unique_pylons = unique(tour);
        unique_pylons_member = unique_pylons(ismember(unique_pylons, tour_base));

        if any(ismember(unique_pylons, tour_base))
            [row, col] = find(unique_pylons_member(1) == tour_base(:,2),1); 
            pylon_common = tour_base(row,col); 
            [row1, col1] = find(unique_pylons_member(1) == tour(:,1),1);
            tour = [tour(row1:end,:); tour(1:row1-1,:)]; 
            tour_base = [tour_base(1:row,:); tour; tour_base(row+1:end, :)]; 
            tours{1}=tour_base; 
            tours{i} = [];
        end     
    end
    tours_aux = tours;
    n_tours = length(tours);
    tours = {};
    for i = 1:n_tours
        if ~isempty(tours_aux{i})
            tours = [tours; [tours_aux{i}, UAV*ones(size(tours_aux{i},1),1)]];
        end
    end
    n_tours = length(tours);


else
    edges_opt=[];
    n_edges=length(edges);
    % Build edges optimal tours
    for i=1:n_edges
        if x(i)
            edges_opt=[edges_opt; edges(i,:)];
        end
    end

    %  Separate the edges according to UAVs
    tours_raw={};
    if n_UAVs > 1
        for UAV = 1:n_UAVs
            [row, col] = find(edges_opt(:,3) == UAV);
            tours_raw{UAV,1} = edges_opt(row,:);
        end
    else
        tours_raw = {edges_opt};
    end


    % Save first the tours that start and finish on the base station
    base_station = 0;
    tours = {};
    for UAV = 1:n_UAVs
        initial_tour = tours_raw{UAV};
        final_tour = [];
        act_node = base_station;
        while  length(initial_tour) > 0
            row_node = find(initial_tour(:,1) == act_node,1,'first');
            final_tour = [final_tour; initial_tour(row_node, :)];
            act_node = initial_tour(row_node,2);
            initial_tour(row_node, :) = [];
            if length(row_node)== 0
                tours = [tours; final_tour];
                final_tour = [];
                break;
            elseif act_node == final_tour(1)
                tours = [tours; final_tour];
                final_tour = [];
                break;
            end

        end

        tours_raw{UAV} = initial_tour;
        tours=[tours;final_tour];
    end

    % Eliminate empty cells
    tours_aux = {}; 
    for UAV = 1:length(tours_raw)
        if ~isempty(tours_raw{UAV})
        tours_aux{size(tours_aux,1)+1,1} = tours_raw{UAV};
        end
    end
    tours_raw = tours_aux;
    
    %   See if the others tours_raw are part of the original or not.
    final_tour = [];
    for i = 1:length(tours_raw)
        initial_tour = tours_raw{i};
        act_node = initial_tour(1);
        ordered_tours = {};
        % Order Subtour
        while length(initial_tour) > 0
            row_node = find(initial_tour(:,1) == act_node,1,'first');
            final_tour = [final_tour; initial_tour(row_node, :)];
            act_node = initial_tour(row_node,2);
            initial_tour(row_node, :) = [];
            if final_tour(1,1) == final_tour(end,2)
                ordered_tours = {ordered_tours{:}, final_tour};
                final_tour = [];
                if length(initial_tour) > 0
                    act_node = initial_tour(1,1); 
                end
            end
        end
        if n_UAVs >1
            UAV = tours_raw{i}(1,3);
        else
            UAV = 1;
        end

        for k = 1:length(ordered_tours)
            ordered_tour = ordered_tours{k};
            for j = 1:length(ordered_tour)
                ordered_tour = [ordered_tour(end,:);ordered_tour(1:end-1,:)];
                act_node = ordered_tour(1,1);
                row = find(tours{UAV}(:,2) == act_node);
                if length(row) > 0
                    tours{UAV} = [tours{UAV}(1:row,1:3); ordered_tour; tours{UAV}(row+1:end,1:3)];
                    break;
                end
                if j == length(ordered_tour)
                    tours = [tours; ordered_tour];
                end
            end
        end
    end

    n_tours = length(tours);

end
end

