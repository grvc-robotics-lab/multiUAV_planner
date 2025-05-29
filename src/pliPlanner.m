% =========================================
%%      POWERLINE INSPECTION PLANNER
%      Long-Range Powerline Inspection
%    Heterogeneous UAVs & finity capacity
% =========================================

function [tours, totalCost, totalBat, cluster_info, times_info]=pliPlanner(fig,towers_pos, grid_connections,UAVs_base_pos, UAVs_base_name,UAVs,UAVs_vel_nav,UAVs_vel_ins,UAVs_vel_cli,UAVs_vel_des,UAVs_q,UAVs_bats_cells,UAVs_voltage, inspection_height, vel_wind, towers_height, cluster_flag)

timer_global = tic

%% PROBLEM PARAMETERS
base_node = 0;
n_towers = length(towers_pos);
n_UAVs = size(UAVs_base_pos, 1);
n_iter=1;

%% DISPLAY INIT
start_time=datetime("now");
disp("-----------------------------")
disp("")
disp("Launched at ")
disp( start_time)
disp("-----------------------------")

%% EDGES
% Edges for each UAV, unify bases and towers on one matrix
edges_UAV = [nchoosek(sort([base_node,1:n_towers]),2); nchoosek(sort([base_node,1:n_towers], 'descend'), 2)];
n_edges_UAV = length(edges_UAV);
% All edges of the problem
edges = [];
for UAV = 1:n_UAVs
    edges = [edges; edges_UAV, UAV*ones(n_edges_UAV, 1)];
end
n_edges = length(edges);
% Minimun edges required to be visited
edges_required = grid_connections;
n_edges_required = length(edges_required);

%% DISTANCES & ANGLES & COST
dist = [];
angle_UAV=[];
angle=[];
cost = zeros(n_edges, 1);
for edge = 1:n_edges
    % Select the nodes and see if it's a base or a tower
    node_1 = edges(edge,1);
    node_2 = edges(edge,2);
    UAV = edges(edge,3);
    % Select velocity of inspection or navegation
    if (node_1 == edges_required(:,1) & node_2==edges_required(:,2)) | (node_1 == edges_required(:,2) & node_2==edges_required(:,1))
        vel = UAVs_vel_ins(UAV);
    else
        vel = UAVs_vel_nav(UAV);
    end
    % Update elevation of nodes with towers and inspection height
    if node_1 == base_node
        pos_node_1 = UAVs_base_pos(UAV,:);
        aux1_h = inspection_height(UAV) + towers_height;
    else
        pos_node_1 = towers_pos(node_1,:);
        aux1_h=0;
    end
    if node_2 == base_node
        pos_node_2 = UAVs_base_pos(UAV,:);
        aux2_h=inspection_height(UAV) + towers_height;
    else
        pos_node_2 = towers_pos(node_2,:);
        aux2_h=0;
    end

    %dist = [dist; (norm(pos_node_1-pos_node_2)+aux1_h+aux2_h)];
    % atan or atan2
    % Angle respect Nort & clockwise
    angle = [angle; atan2((pos_node_2(2)-pos_node_1(2)),(pos_node_2(1)-pos_node_1(1)))];
    % Sum time from horizontal displacement
    cost(edge)=(norm(pos_node_1(1:2)-pos_node_2(1:2))/vel) + ...
        (aux1_h/UAVs_vel_cli(edges(edge,3))) + ... % height to climb
        aux2_h/UAVs_vel_des(edges(edge,3)); % height to desclimb

end

%% VELOCITY respect wind
vel = zeros(n_edges,1);
for edge = 1:n_edges
    v_mod = UAVs_vel_nav(edges(edge,3));
    v_ang = angle(edge);
    vel(edge) = sqrt(v_mod^2 + vel_wind(1)^2-2*v_mod*vel_wind(1)*cos(vel_wind(2) - angle(edge)));
end

%% CAPACITY
% I changed how select cost, before was cos(i*UAV). I think it not have
% sense. Now is more correct and faster.
Q = zeros(n_edges_UAV, n_UAVs);
for UAV = 1:n_UAVs
    for i = 1:n_edges_UAV
        edge = edges_UAV(i,:);
        cap = 0;
        current = 0;
        % Forward Velocity
        if (edges(i,1) == edges_required(:,1) & edges(i,2)==edges_required(:,2)) | ...
                (edges(i,1) == edges_required(:,2) & edges(i,2)==edges_required(:,1))
            vel_for = UAVs_vel_ins(UAV); %edges(i,3));
        else
            vel_for = UAVs_vel_nav(UAV); %edges(i,3));
        end
        % vel_for = vel(i);
        %% Classify type of movement
        % *Base to tower
        if edge(1) == 0 && edge(2)>0
            % Climb
            current = 1000*epower_climb(UAVs{UAV}, UAVs_vel_cli(UAV))/UAVs_voltage(UAV);  %[mA]
            elevation = inspection_height(UAV) + towers_height; %towers_pos(UAV, 3) - UAVs_base_pos(UAV, 3); %[m]
            time = elevation/(UAVs_vel_cli(UAV)*3600);    %[h]
            cap = current*time;     %[mAh]
            % Forward
            current = 1000*epower_forward(UAVs{UAV}, vel_for)/UAVs_voltage(UAV);  %[mA]
            time = cost(i + n_edges_UAV*(UAV-1))/3600; %[h]
            cap = cap + current*time;  %[mAh]
            % *Tower to base
        elseif edge(1) > 0 && edge(2)==0
            % Forward
            current = 1000*epower_forward(UAVs{UAV}, vel_for)/UAVs_voltage(UAV);  %[mA]
            time = cost(i + n_edges_UAV*(UAV-1))/3600;    %[h]
            cap = current*time;   %[mAh]
            % Descend
            current = 1000*epower_descent(UAVs{UAV}, UAVs_vel_des(UAV))/UAVs_voltage(UAV); %[mA]
            elevation = inspection_height(UAV) + towers_height;%UAVs_base_pos(UAV, 3) - towers_pos(UAV, 3); %[m]
            time = -elevation/(UAVs_vel_cli(UAV)*3600);  %[h]
            cap = cap + current*time;   %[mAh]
            % *Tower to tower
        elseif edge(1) > 0 && edge(2)>0
            current = 1000*epower_forward(UAVs{UAV}, vel_for)/UAVs_voltage(UAV);  %[mA]
            time = cost(i + n_edges_UAV*(UAV-1))/3600; %[h]
            cap = current*time;  %[mAh]
        end
        Q(i, UAV) = cap/UAVs_q(UAV);
    end
end

%% CLUSTERING
timer_cluster = tic;
alpha = 0.082;
if cluster_flag
    [cluster_info, n_towers, cost, Q, grid_connections, n_edges, edges, n_edges_UAV, edges_UAV] ...
        = clusterNodes(alpha, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV);
    edges_required  = grid_connections;
    n_edges_required = length(edges_required);
    cluster_info.original_towers_2_clustered_towers
else
    cluster_info.original_towers_2_clustered_towers = 0;
    cluster_info.branches_2_original_tower = 0;
    cluster_info.n_original_towers = 0;
    cluster_info.original_cost = 0;
    cluster_info.original_Q = 0;
    cluster_info.original_grid_connections = 0;
    cluster_info.original_edges = 0;
    cluster_info.original_edges_UAV = 0;

end
time_cluster = toc(timer_cluster);

%% COMBOS
if n_UAVs > 1
    UAVs_combos = nchoosek(1:n_UAVs, 2);
    n_UAVs_combos = size(UAVs_combos, 1);
else
    n_UAVs_combos = 0;
    UAVs_combos = [];
end

%% OPTIMIZATION MIN MAX PROBLEM

%%% OBJECTIVE FUNCTION
obj_fnc = [cost' ones(1,n_UAVs_combos)];

%% BASE CONSTRAINT
% Each UAV must visit its base only twice: at the beginning and to finish
% _To begin_
Aeq_origin_out = zeros(n_UAVs, n_edges + n_UAVs_combos);
for UAV = 1:n_UAVs
    [row, col] = find(edges(:,1) == base_node & edges(:,3) == UAV);
    Aeq_origin_out(UAV,row)=1;
end
beq_origin_out = ones(n_UAVs, 1);
% _To end_
Aeq_origin_in = zeros(n_UAVs, n_edges + n_UAVs_combos);
for UAV = 1:n_UAVs
    [row, col] = find(edges(:,2) == base_node & edges(:,3) == UAV);
    Aeq_origin_in(UAV,row)=1;
end
beq_origin_in=ones(n_UAVs, 1);

%% INOUT CONSTRAINT
% A UAV can't stay on a node. So, it must have the same number of edges to
% enter than to exit from all nodes.
Aeq_inout = zeros(n_towers*n_UAVs, n_edges + n_UAVs_combos);
f = 0;
for tower = 1:n_towers
    for UAV = 1:n_UAVs
        f = f + 1;
        [row, col] = find(edges(:,1) == tower & edges(:,3) == UAV);
        Aeq_inout(f,row) = 1;
        [row, col] = find(edges(:,2) == tower & edges(:,3) == UAV);
        Aeq_inout(f,row) = - 1;
    end
end
beq_inout = zeros(n_towers*n_UAVs, 1);

%% GRID CONNECTION CONSTRAINT
% Each connection of tower must be visit (at least) once to be inspected. Regardless of whether UAV does it.
A_segments = zeros(n_edges_required, n_edges + n_UAVs_combos);
for i=1:n_edges_required
    col=[];
    col = find((edges(:,1)==edges_required(i,1) & edges(:,2)==edges_required(i,2)) |...
        (edges(:,2)==edges_required(i,1) & edges(:,1)==edges_required(i,2)));
    A_segments(i, col) = -1;
end
b_segments = - ones(n_edges_required, 1);

% Each direction of an edge can be 0 or 1. Only one UAV inspect each edge_required
A_segments_limit = zeros(2*n_edges_required, n_edges + n_UAVs_combos);
for i=1:n_edges_required
    col = find((edges(:,1)==edges_required(i,1) & edges(:,2)==edges_required(i,2)));
    A_segments_limit(2*i, col) = 1;
    col = find((edges(:,2)==edges_required(i,1) & edges(:,1)==edges_required(i,2)));
    A_segments_limit(2*i-1, col) = 1;
end
b_segments_limit = ones(2*n_edges_required, 1);

% All the UAVs must inspect the line
A_segments_combo = zeros(n_UAVs+n_UAVs_combos, n_edges + n_UAVs_combos);
for i=1:n_UAVs+n_UAVs_combos
    if i <= n_UAVs
        for j = 1:n_edges_required
            UAV = i;
            col = find((edges(:,1)==edges_required(j,1) & edges(:,2)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;
            col = find((edges(:,2)==edges_required(j,1) & edges(:,1)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;
        end
    else
        for j = 1:n_edges_required
            UAV = UAVs_combos(i-n_UAVs, 1);
            col = find((edges(:,1)==edges_required(j,1) & edges(:,2)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;
            col = find((edges(:,2)==edges_required(j,1) & edges(:,1)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;

            UAV = UAVs_combos(i-n_UAVs, 2);
            col = find((edges(:,1)==edges_required(j,1) & edges(:,2)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;
            col = find((edges(:,2)==edges_required(j,1) & edges(:,1)==edges_required(j,2) & edges(:,3)==UAV));
            A_segments_combo(i, col) = 1;
        end
    end
end

b_segments_combo = n_edges_required*ones(n_UAVs+n_UAVs_combos, 1)-1;

%%% SIGMA CONSTRAINT
A_sigma = zeros(2*n_UAVs_combos, n_edges + n_UAVs_combos);
b_sigma = zeros(2*n_UAVs_combos, 1);
for combo = 1:n_UAVs_combos
    UAV_1 = UAVs_combos(combo, 1);
    row = (edges(:,3) == UAV_1);
    A_sigma(2*combo, row) = cost(row);
    A_sigma(2*combo-1, row) = -cost(row);
    A_sigma(2*combo, n_edges+1) = -1;

    UAV_2 = UAVs_combos(combo,2);
    row = (edges(:,3) == UAV_2);
    A_sigma(2*combo, row) = -cost(row);
    A_sigma(2*combo-1, row) = cost(row);

    A_sigma(2*combo, n_edges+1) = -1;
    A_sigma(2*combo-1, n_edges+1) = -1;
end

%%% CAPACITY CONSTRAINT
A_Q = zeros(n_UAVs, n_edges + n_UAVs_combos);
for UAV = 1:n_UAVs
    A_Q (UAV,(1:n_edges_UAV) + n_edges_UAV*(UAV -1)) = Q(1:n_edges_UAV, UAV)';
end
b_Q = ones(n_UAVs, 1);

%%% UNIFY CONSTRAINTS
Aeq = [Aeq_origin_out; Aeq_origin_in; Aeq_inout];
beq = [beq_origin_out; beq_origin_in; beq_inout];


A = [A_sigma; A_segments; A_segments_limit; A_Q];
b = [b_sigma; b_segments; b_segments_limit; b_Q];

%%% INTLINPROG PARAMETERS
ub = ones(n_edges + n_UAVs_combos,1);
lb = zeros(n_edges + n_UAVs_combos,1);

intcon = 1:n_edges;

%%% OPTIMIZATION
% Optimizations options
opts = optimoptions('intlinprog', 'Display', 'off', 'IntegerTolerance', 1e-06, 'ConstraintTolerance', 1e-09, 'LPOptimalityTolerance', 1e-10, 'RelativeGapTolerance', 0, 'Heuristics', 'round-diving', 'IPPreprocess', 'none');

disp("----------------------------")
disp("Begining MIN MAX PROBLEM optimization")
disp("----------------------------")

x = intlinprog(obj_fnc, intcon, A, b, Aeq, beq, lb, ub, [], opts);
x(intcon) = round(x(intcon));

%%% SUBTOUR DETECTION
[tours, n_tours] = find_subtour(x, edges, n_UAVs, base_node);

pre_n_tours = n_tours;
pre_tours = tours;
drawSol(fig, grid_connections, UAVs_base_pos, UAVs_base_name, n_UAVs, towers_pos, tours,  [], []);

%%% SUBTOUR ELIMINATION
while n_tours > n_UAVs
    disp("----------------------------")
    disp("iteration MIN MAX PROB " + string(n_iter))
    disp("time used " + string(toc(timer_global)) + " [s]")
    disp("----------------------------")
    n_iter = n_iter + 1;
    A_subtours = zeros(n_UAVs*(n_tours-n_UAVs), n_edges + n_UAVs_combos);
    b_subtours = -ones(n_UAVs*(n_tours-n_UAVs), 1);
    for i = 1:n_tours-n_UAVs
        tour=tours{i + n_UAVs};
        nodes_tour = unique(tour(:,1:2));
        UAV_tour = tour(1,3);
        for UAV = 1:n_UAVs
            for j=1:n_edges
                if (any(edges(j,1)==nodes_tour) && all(edges(j,2)~=nodes_tour) && edges(j,3) == UAV) || ...
                        (any(edges(j,2)==nodes_tour) && all(edges(j,1)~=nodes_tour) && edges(j,3) == UAV)
                    A_subtours(i+(n_tours-n_UAVs)*(UAV-1),j) = -1;
                end
            end
        end
    end
    A = [A; A_subtours];
    b = [b; b_subtours];

    x = intlinprog(obj_fnc, intcon, A, b, Aeq, beq, lb, ub, [], opts);
    x(intcon) = round(x(intcon));

    pre_n_tours = n_tours;
    pre_tours = tours ;

    % Subtour detection
    [tours, n_tours] = find_subtour(x, edges, n_UAVs, base_node);

end
disp("----------------------------")
disp("End optimization MIN MAX PROBLEM")
disp("time used " + string(toc(timer_global)) + " [s]")
disp("----------------------------")

disp("----------------------------")
disp("Begining optimization NON MIN MAX PROBLEM")
disp("----------------------------")

totalCost = calculateCost(cost, edges, tours);
timeMinMax = toc(timer_global);

%% OPTIMIZATION NON-MAX SOL
[max_cost, max_UAV] = max(totalCost);

non_max_sol_flag = 1;
if non_max_sol_flag
    %%% OPTIMIZATION OF EACH NON-MAX SOL
    for UAV = 1:n_tours
        if 1 %UAV ~= max_UAV
            tour = tours{UAV};
            %%% OBTAIN TOWERS
            pylons = unique(tour(:,1:2));
            pylons = pylons(pylons ~= base_node);
            n_pylons = length(pylons);

            %%% EDGES
            edges_tour = [nchoosek(sort([base_node;pylons]),2); nchoosek(sort([base_node;pylons], 'descend'), 2)];
            n_edges_tour = size(edges_tour,1);
            edges_tour = [edges_tour, UAV*ones(n_edges_tour,1)];
            edges_tour_required = [];
            for path = 1:size(tour,1)
                if any(edges_required(:,1) == tour(path,1) & edges_required(:,2) == tour(path,2) | ...
                        edges_required(:,1) == tour(path,2) & edges_required(:,2) == tour(path,1) )

                    edges_tour_required = [edges_tour_required; sort(tour(path,1:2)), UAV];
                end
            end
            edges_tour_required = unique(edges_tour_required, 'rows');
            n_edges_tour_required = size(edges_tour_required,1);

            %%% COST
            cost_tour = cost(ismember(edges,edges_tour,'rows'));

            %%% BASE CONSTRAINT
            Aeq_origin = zeros(2,n_edges_tour);
            Aeq_origin(1,edges_tour(:,1) == base_node) = 1;
            Aeq_origin(2,edges_tour(:,2) == base_node) = 1;
            beq_origin = ones(2, 1);
            %%% INOUT CONSTRAINT
            Aeq_inout = zeros(n_pylons, n_edges_tour);
            for i = 1:n_pylons
                aux = find(edges_tour(:,1) == pylons(i));
                Aeq_inout(i,aux) = 1;
                aux = find(edges_tour(:,2) == pylons(i));
                Aeq_inout(i,aux) = -1;
            end
            beq_inout = zeros(n_pylons, 1);
            %%% GRID CONNECTION CONSTRAINT
            A_segments = zeros(n_edges_tour_required, n_edges_tour);
            for path = 1:n_edges_tour_required
                col = find((edges_tour(:,1)==edges_tour_required(path,1) & edges_tour(:,2)==edges_tour_required(path,2)) |...
                    (edges_tour(:,2)==edges_tour_required(path,1) & edges_tour(:,1)==edges_tour_required(path,2)));
                A_segments(path, col) = -1;
            end
            b_segments = - ones(n_edges_tour_required, 1);
            %%% UNIFY CONSTRAINTS
            Aeq = [Aeq_origin; Aeq_inout];
            beq = [beq_origin; beq_inout];
            A = A_segments;
            b = b_segments;

            %%% INTLINPROG PARAMETERS
            ub = ones(n_edges_tour,1);
            lb = zeros(n_edges_tour,1);
            intcon = 1:n_edges_tour;

            %%% OPTIMIZATION
            x = intlinprog(cost_tour, intcon, A, b, Aeq, beq, lb, ub, [], opts);
            x(intcon) = round(x(intcon));

            %%% SUBTOUR DETECTION
            [tour, n_tour_aux] = find_subtour(x, edges_tour, 1, base_node);

            %% SUBTOUR ELIMINATION
            while n_tour_aux > 1
                A_subtours = zeros(n_tour_aux-1, n_edges_tour);
                b_subtours = -ones(n_tour_aux-1, 1);
                % for i = 1:n_tour_aux-1
                for i = 1:n_tour_aux - 1
                    tour_aux = tour{i+1};
                    pylons = unique(tour_aux(:,1:2));
                    for j=1:n_edges_tour
                        if (any(edges_tour(j,1)==pylons) && all(edges_tour(j,2)~=pylons)) || ...
                                (any(edges_tour(j,2)==pylons) && all(edges_tour(j,1)~=pylons))
                            A_subtours(i,j) = -1;
                        end
                    end
                end
                A = [A; A_subtours];
                b = [b; b_subtours];

                % Optimization

                x = intlinprog(cost_tour, intcon, A, b, Aeq, beq, lb, ub, [], opts);
                x(intcon) = round(x(intcon));

                % Subtour detection
                [tour, n_tour_aux] = find_subtour(x, edges_tour, 1, base_node);
            end
            tours{UAV} = tour{1};
        end
    end

end
%% UNCLUSTER PLAN
timer_uncluster = tic;
if cluster_flag
    [tours, n_towers, cost, Q, grid_connections, n_edges, edges, n_edges_UAV, edges_UAV] ...
        = unclusterNodes(cluster_info, tours, n_UAVs, n_towers, cost, Q, grid_connections, edges, edges_UAV);
end
time_uncluster = toc(timer_uncluster);
%% CALCULATE TOTAL BATTERY
bat =[];
for i = 1:n_UAVs
    bat = [bat; Q(:,i) ];
end

%% CALCULATES DISTANCES
totalDistances = [];
totalGridDistances = [];
for i=1:size(tours,1)

    tour = tours{i};
    totalDistance = 0; 
    totalGridDistance = 0; 
    for j=1:size(tour,1)
        if tour(j,1)
            node1 = towers_pos(tour(j,1),1:2);
        else 
            node1 = UAVs_base_pos(i,1:2);
        end
        if tour(j,2)
            node2 = towers_pos(tour(j,2),1:2);
        else 
            node2 = UAVs_base_pos(i,1:2);
        end
        if any((grid_connections(:,1)==tour(j,1) & grid_connections(:,2)==tour(j,2)) | (grid_connections(:,1)==tour(j,2) & grid_connections(:,2)==tour(j,1)))
            totalGridDistance = totalGridDistance + norm(node1-node2);
        end
        totalDistance = totalDistance + norm(node1-node2);
    end
    totalDistances = [totalDistances, totalDistance];
    totalGridDistances = [totalGridDistances, totalGridDistance];
end

%% PRINT FINAL INFORMATION
totalTime = toc(timer_global);

times_info.totalTime = totalTime;
times_info.timeMinMax = timeMinMax;
times_info.cluster = time_cluster;
times_info.uncluster = time_uncluster;
times_info.alpha = alpha;
disp("")
disp("----------------------RESULTS--------------------")
totalCost = calculateCost(cost, edges, tours);
totalBat = calculateCost(bat, edges, tours);
disp("Total time neccesary : "+string(totalCost) + "s");
disp("Total battery neccesary : "+string(totalBat*100) + "%");
disp("Total distances : "+string(totalDistances) + "m");
disp("Total grid distances : "+string(totalGridDistances) + "m");
disp("Number of iteration: "+string(n_iter));
disp("Time required to solve MIN-MAX Problem: " + datestr(seconds(timeMinMax), 'HH:MM:SS.FFF'));
disp("Total time required to solve NON MIN-MAX Problem : " + string(totalTime-timeMinMax) +'seconds');
disp("Total time required to solve : " + string(totalTime) +'seconds');

for i=1:size(tours,1)
    strRoute = "Route " + string(i) + " : {" + string(tours{i}(1)) ;
    for j = 2:size(tours{i},1)
        strRoute = strRoute + ", " + string(tours{i}(j));
    end
    strRoute = strRoute + "}";
    disp(strRoute)
end

end