function [cluster_info,n_new_tower, new_cost, new_Q, new_grid_connections, n_new_edges, new_edges, n_new_edges_UAV, new_edges_UAV] = clusterNodes(alpha, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV)

n_edges_UAV = size(edges_UAV, 1);
%% SEPARATE BRANCHES
cardinality_towers = zeros(n_towers, 1);
for tower = 1:n_towers
    cardinality_towers(tower) = sum(sum(grid_connections==tower));
end
cardinality_towers_aux = cardinality_towers;
% Each cell will be one of the old branchs
branches_2_old_towers = {};
while (sum(cardinality_towers_aux))
    % Towers connected
    connection_towers = find(cardinality_towers_aux>2);

    % If there aren't towers with a cardinality bigger than 2, it's just one
    % line. So put one of the extreme tower
    if size(connection_towers,1) == 0
        connection_towers = find(cardinality_towers_aux==1,1);
    end

    for tower = connection_towers'
        % Look for the towers connected to tower
        towers_connected = zeros(cardinality_towers(tower),1);
        [row, col] = find(grid_connections == tower);
        col1 = find(col==1);
        col2 = find(col==2);
        col(col1) = 2;
        col(col2) = 1;
        towers_connected = zeros(length(col),1);
        for i = 1:length(col)
            towers_connected(i) = grid_connections(row(i), col(i));
        end
        % Separate each branch for this conection node
        branch = [tower];
        pre_tower = tower;
        for i = 1:length(towers_connected)
            act_tower = towers_connected(i);
            if cardinality_towers_aux(act_tower) == 2
                [row, col] = find(grid_connections == act_tower);
                aux = unique(grid_connections(row,:));
                next_tower = aux(aux ~= pre_tower & aux ~=act_tower);
                branch = [branch; act_tower];
                % While the next towers only has two connection, add normally toi
                % the branch
                while cardinality_towers_aux(next_tower) == 2
                    pre_tower = act_tower;
                    act_tower = next_tower;
                    [row, col] = find(grid_connections == act_tower);
                    aux = grid_connections(row,col);
                    next_tower = aux(aux ~= act_tower & aux ~= pre_tower);
                    branch = [branch; act_tower];
                end
            else
                next_tower = act_tower;
            end
            % When the next tower has 1 connection (last tower) or > 2
            % (connected tower)
            branch = [branch; next_tower];
            branches_2_old_towers = [branches_2_old_towers; branch];
            cardinality_towers_aux(branch(2:end-1)) = cardinality_towers_aux(branch(2:end-1)) - 2;
            cardinality_towers_aux(branch(1)) = cardinality_towers_aux(branch(1)) - 1;
            cardinality_towers_aux(branch(end)) = cardinality_towers_aux(branch(end)) - 1;
            pre_tower = tower;
            branch = [tower];
        end

    end
end

% Eliminate repeated branches. Usually, branches with one tower at both
% ends
repeated_branches = [];
for i = 1:size(branches_2_old_towers,1)-1
    branch = flip(branches_2_old_towers{i});
    for j = i+1:size(branches_2_old_towers,1)
        if length(branch) == length(branches_2_old_towers{j})
            if  all(branch == branches_2_old_towers{j})
                repeated_branches = [repeated_branches, j];
            end
        end
    end
end
aux = branches_2_old_towers;
branches_2_old_towers ={};
for i = 1:size(aux,1)
    if ~ismember(i, repeated_branches)
        branches_2_old_towers=[branches_2_old_towers; aux{i}];
    end
end
%% SEPARATE BRANCHES by HEURISTIC
% alpha = 0.1;
% This matrix will have 2 column. One for the old tower and another one
% with the new tower.
old_towers_2_new_towers = [0,0]; % Initialize the matrix
old_tower_col = 1;
new_tower_col = 2;
n_new_tower = 0;

for i_branch = 1:size(branches_2_old_towers,1)

    branch = branches_2_old_towers{i_branch};
    if cardinality_towers(branch(end)) == 1 & cardinality_towers(branch(1)) ~= 1
        branch = flip(branch);
    end
    if size(branch,1) <= 2 | (size(branch,1) == 3 & (cardinality_towers(branch(1)) > 1 & cardinality_towers(branch(end)) > 1))
        for i_tower = 1:length(branch)
            if ~any(branch(i_tower) == old_towers_2_new_towers(:,old_tower_col))
                n_new_tower = n_new_tower + 1;
                old_towers_2_new_towers = [old_towers_2_new_towers; [branch(i_tower), n_new_tower]];
            end
        end
    else
        n_nodes_branch = size(branch,1);% - (cardinality_towers(branch(end))~=1);
        bat = 0;
        bat_UAVs = zeros(2*n_UAVs, 1);

        bat_UAVs = zeros(n_nodes_branch-1, 2*n_UAVs);
        for i_tower = 1:n_nodes_branch-1
            edge = [branch(i_tower), branch(i_tower+1)];
            for UAV = 1:n_UAVs
                bat_UAVs(i_tower, UAV*2)   = Q(edges(:,1) == edge(1) & edges(:,2) == edge(2) & edges(:,3) == UAV);
                bat_UAVs(i_tower, UAV*2-1) = Q(edges(:,1) == edge(2) & edges(:,2) == edge(1) & edges(:,3) == UAV);
            end
        end
        max_bat = max(sum(bat_UAVs,1));
        if max_bat < alpha
            % If its a new tower, create the cluster noder
            for i_tower = [1,n_nodes_branch]
                if all(old_towers_2_new_towers(:,old_tower_col) ~= branch(i_tower))
                    n_new_tower = n_new_tower + 1;
                    old_towers_2_new_towers = [old_towers_2_new_towers; branch(i_tower), n_new_tower];
                end
            end
        else
            i_tower = 1;
            for j_tower = 2:size(bat_UAVs,1) + 1
                if max(sum(bat_UAVs(i_tower:j_tower-1, :),1)) > alpha
                    % Save tower i_tower
                    if all(old_towers_2_new_towers(:,old_tower_col) ~= branch(i_tower))
                        n_new_tower = n_new_tower + 1;
                        old_towers_2_new_towers = [old_towers_2_new_towers; branch(i_tower), n_new_tower];
                    end
                    % Save tower j_tower
                    if all(old_towers_2_new_towers(:,old_tower_col) ~= branch(j_tower))
                        n_new_tower = n_new_tower + 1;
                        old_towers_2_new_towers = [old_towers_2_new_towers; branch(j_tower), n_new_tower];
                    end

                    i_tower = j_tower;

                end
            end
            % Save last tower
            if all(old_towers_2_new_towers(:,old_tower_col) ~= branch(end))
                n_new_tower = n_new_tower + 1;
                old_towers_2_new_towers = [old_towers_2_new_towers; branch(end), n_new_tower];
            end
        end
    end
end
% Eliminate first row [0 0]
old_towers_2_new_towers = old_towers_2_new_towers(2:end, :);
%% CREATE NEW GRID CONNECTION
new_grid_connections = [];
n_branches = size(branches_2_old_towers,1);

for i_branch = 1:n_branches
    branch = branches_2_old_towers{i_branch};
    new_branch = [];
    for i_tower = 1:length(branch)
        if ismember(branch(i_tower), old_towers_2_new_towers(:,old_tower_col))
            new_branch = [new_branch; old_towers_2_new_towers(branch(i_tower) == old_towers_2_new_towers(:,old_tower_col), new_tower_col)];
        end
    end
    new_grid_connections = [new_grid_connections;  new_branch(1:end-1), new_branch(2:end)];

end

%% CREATE NEW EDGES
% Edges for each UAV, unify bases and towers on one matrix
new_edges_UAV = [nchoosek(sort([0,1:n_new_tower]),2); nchoosek(sort([0,1:n_new_tower], 'descend'), 2)];
n_new_edges_UAV = length(new_edges_UAV);
% All edges of the problem
new_edges = [];
for UAV = 1:n_UAVs
    new_edges = [new_edges; new_edges_UAV, UAV*ones(n_new_edges_UAV, 1)];
end
n_new_edges = length(new_edges);
% Minimun edges required to be visited
new_edges_required = new_grid_connections;
n_new_edges_required = length(new_edges_required);

%% CREATE NEW COST
new_cost = zeros(n_new_edges,1);
new_Q = zeros(n_new_edges_UAV, n_UAVs);
for UAV = 1:n_UAVs
    for i_edge = 1:n_new_edges_UAV
        % Check the old towers and check if there are at old and new
        % grid_connections. If the new towers are connected but the old
        % not, between the old towers there were more towers to  take care
        % to the new cost.
        % If there is the node 0, the edge isn't at any
        % grid_connection.
        new_towers = new_edges_UAV(i_edge,:);
        if new_towers(1) == 0
            old_towers = [ 0,old_towers_2_new_towers(new_towers(2), old_tower_col)];
            new_grid = 0;
            old_grid= 0;
        elseif new_towers(2) == 0
            old_towers = [old_towers_2_new_towers(new_towers(1), old_tower_col), 0];
            new_grid = 0;
            old_grid= 0;
        else
            old_towers = [old_towers_2_new_towers(new_towers(1), old_tower_col), old_towers_2_new_towers(new_towers(2), old_tower_col)];
            new_grid = any(new_grid_connections(:,1) == new_towers(1) & new_grid_connections(:,2) == new_towers(2)) | ...
                any(new_grid_connections(:,1) == new_towers(2) & new_grid_connections(:,2) == new_towers(1));
            old_grid = any(grid_connections(:,1) == old_towers(1) & grid_connections(:,2) == old_towers(2)) | ...
                any(grid_connections(:,1) == old_towers(2) & grid_connections(:,2) == old_towers(1));
        end
        % new_grid = 0 & old_grid = 0 -> No missing towers
        % new_grid = 1 & old_grid = 1 -> No missing towers
        % new_grid = 1 & old_grid = 0 -> Missing towers
        if new_grid == old_grid
            [r,c] = find(edges_UAV(:,1) == old_towers(1) & edges_UAV(:,2) == old_towers(2));
            new_Q(i_edge, UAV) = Q(r, UAV);
            new_cost(n_new_edges_UAV*(UAV-1) + i_edge) = cost(n_edges_UAV*(UAV-1)+r);
        else
            % Look for the branch where are the towers
            for i_branch = 1:n_branches
                branch = branches_2_old_towers{i_branch};
                if all(ismember(old_towers, branch))
                    f_t = find(branch == old_towers(1)); % First tower
                    s_t = find(branch == old_towers(2)); % Second tower
                    if f_t < s_t
                        towers = branch(f_t:s_t);
                    else
                        towers = branch(s_t:f_t);
                        towers = flip(towers);
                    end
                    break;
                end
            end
            % Sum the cost and Q ofall the towers between the old_towers
            aux_q = 0;
            aux_c = 0;
            for i_t = 1:length(towers)-1
                [r,c] = find(edges_UAV(:,1) == towers(i_t) & edges_UAV(:,2) == towers(i_t+1));
                aux_q = aux_q + Q(r, UAV);
                aux_c = aux_c + cost(n_edges_UAV*(UAV-1)+r);
            end
            new_Q(i_edge, UAV) = aux_q;
            new_cost(n_new_edges_UAV*(UAV-1) + i_edge) = aux_c;
        end
    end
end
cluster_info.original_towers_2_clustered_towers = old_towers_2_new_towers;
cluster_info.branches_2_original_tower = branches_2_old_towers;
cluster_info.n_original_towers = n_towers;
cluster_info.original_cost = cost;
cluster_info.original_Q = Q;
cluster_info.original_grid_connections = grid_connections;
cluster_info.original_edges = edges;
cluster_info.original_edges_UAV = edges_UAV;
cluster_info.clustered_grid_connections = new_grid_connections;

end


