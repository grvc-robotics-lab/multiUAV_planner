% function [original_tours, cluster_info.n_original_towers, cluster_info.original_cost, ...
%     cluster_info.original_Q, cluster_info.original_grid_connections, ...
%     n_edges, cluster_info.original_edges, n_edges_UAV, cluster_info.original_edges_UAV] ...
%     = unclusterNodes(cluster_info, tours, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV); 
% function unclusterNodes(cluster_info, tours, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV); 
function [original_tours, n_original_towers, original_cost, ...
    original_Q, original_grid_connections, ...
    n_edges, original_edges, n_edges_UAV, original_edges_UAV] ...
    = unclusterNodes(cluster_info, tours, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV)
    
    % Realiza las operaciones necesarias en tu función
    
    % Cambia las variables de salida de cluster_info.x a x
    n_original_towers = cluster_info.n_original_towers;
    original_cost = cluster_info.original_cost;
    original_Q = cluster_info.original_Q;
    original_grid_connections = cluster_info.original_grid_connections;
    original_edges = cluster_info.original_edges;
    original_edges_UAV = cluster_info.original_edges_UAV;
    
%% CALCULATE PARAMETERS ARENT AT CLUSTER_INFO

n_edges = size(cluster_info.original_edges, 1); 
n_edges_UAV = size(cluster_info.original_edges_UAV, 1); 

%% RESTORE TOUR WITH ORIGINAL TOWERS
clustered_tours = tours; 
n_clustered_tours = size(clustered_tours, 1);   
original_tours = cell(size(clustered_tours)); 

for i_tour = 1:n_clustered_tours
    c_tour = clustered_tours{i_tour}; % Clustered tour
    uc_tour = []; % Unclustered tour
    % unclustered_tour = [0 cluster_info.original_towers_2_clustered_towers(clustered_tour,1)]; 
    for i_edge = 1:size(c_tour,1)
        towers = c_tour(i_edge,1:2); 
        UAV = c_tour(1,3);

        if towers(1) == 0
            uc_tour = [uc_tour; 0, cluster_info.original_towers_2_clustered_towers(towers(2),1), UAV]; 
        elseif towers(2) == 0; 
            uc_tour = [uc_tour; cluster_info.original_towers_2_clustered_towers(towers(1),1), 0, UAV]; 
        else
            % Check if the towers are on the same original branch
            o_towers = [cluster_info.original_towers_2_clustered_towers(towers(1),1), cluster_info.original_towers_2_clustered_towers(towers(2),1)]; 
            same_branch = 0; 
            for i_branch = 1:size(cluster_info.branches_2_original_tower,1)
                branch = cluster_info.branches_2_original_tower{i_branch}; 
                if all(ismember(o_towers, branch))
                    same_branch = 1; 
                    break; 
                end
            end

            if same_branch
                f_t = find(branch == o_towers(1)); 
                s_t = find(branch == o_towers(2)); 
                if f_t > s_t
                    all_towers = branch(s_t:f_t);
                    all_towers = flip(all_towers);
                else
                    all_towers = branch(f_t:s_t); 
                end
                for i = 1:length(all_towers) - 1; 
                    uc_tour = [uc_tour; all_towers(i), all_towers(i+1), UAV]; 
                end
            else
                uc_tour = [uc_tour; o_towers(1), o_towers(2), UAV]; 
            end
        
        end
        original_tours{i_tour} = uc_tour; 
    end
% A for loopp to see each tour, see the towers , convert and see if itws
% neccesary to add new ones. 
end