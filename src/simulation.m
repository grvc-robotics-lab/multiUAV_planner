function simulation(fig, wp, bases_names, bases, towers,  vel_ins, vel_nav, vel_climb, vel_descend, speed, n_UAVs,  grid_connections, tours)

time = 1/2;  %time to calculate points, FPS
time_vis = time*speed;  %time of visualization
time_extra = 0;
points={};
angles=cell(n_UAVs,1); 
% 4th column: 1 is a segment of the power line, 0 isn't it. 
UAVs_pos  = bases; % [bases, zeros(n_UAVs, 1)]
%% Calculate of trajectory for each drone
for UAV = 1:n_UAVs
    points_UAV = [];
    % Elevation not introduced, there are some points to think before
    wp_UAV = wp{UAV};
    n_wp = size(wp_UAV,1);
    % Calculate point between waypoints
    for i = 1:n_wp-1
        node_1 = wp_UAV(i,1:3);
        node_2 = wp_UAV(i+1, 1:3);

        %% Select velocity
        grid = wp_UAV(i,4);
        if grid
            vel_for=vel_ins(UAV);
        else
            vel_for = vel_nav(UAV);
        end

        %% Calculate distances
        height = node_2(3)-node_1(3);
        distance_nodes =  norm(node_2(1:2)-node_1(1:2));   % Distance to cover
        distance_extra = time_extra*vel_for;               %Distance didn't cover on a frame due to chane of nodes
        distance_vis = time_vis*vel_for;                   %Distance the UAV cover on a frame

        %% Direction vector
        dir_vector = (node_2-node_1)/norm(node_2-node_1);
        dir_vector_angle = atan2(dir_vector(2), dir_vector(1))*180/pi; 
            
        %% First point of trajectory
        if distance_extra > 0
            % Calculate the first point with distance_extra
            points_UAV = [points_UAV; node_1 + distance_extra*dir_vector];
            distance_nodes =distance_nodes-distance_extra;
            angles{UAV} = [angles{UAV}; angles{UAV}(end)];
        else
            points_UAV =  [points_UAV; node_1];
            angles{UAV} = [angles{UAV}; wp_UAV(i, 5)];
        end
        % While there are more distance to cover than the distance on a
        % frame, claculate new point.
        while distance_nodes > distance_vis
            points_UAV = [points_UAV; points_UAV(end,:)+ dir_vector*distance_vis];
            distance_nodes = distance_nodes-distance_vis; 
            angles{UAV} = [angles{UAV}; wp_UAV(i, 5)];
        end

        % Save distance to cover to the next edge
        distance_extra = distance_nodes;

    end
    %% Save the trajectories
    points_UAV = [points_UAV; wp_UAV(end,1:3)];
    points{UAV} = points_UAV;
end

%%  Padding trajectories
max_points = 0;
for UAV = 1:n_UAVs
    if size(points{UAV},1) > max_points
        max_points = size(points{UAV},1);
    end
end
for UAV = 1:n_UAVs
    size_wp =  size(points{UAV},1);
    if size_wp < max_points
        aux = points{UAV};
        for i = size_wp+1:max_points
            aux = [aux; aux(end,:)];
        end
        points{UAV} = aux;
    end
    while size(angles{UAV}) < max_points
        angles{UAV} = [angles{UAV}; angles{UAV}(end)];
    end
end
%% Represent the simulation
for i = 1:max_points
    tic;
    UAVs_pos=[]; 
    for UAV = 1:n_UAVs
        UAV_trajectory=points{UAV};
        UAVs_pos = [UAVs_pos; UAV_trajectory(i,1:2), angles{UAV}(i)];
    end
        drawSol(fig, grid_connections, bases, bases_names, n_UAVs, towers,  tours, wp, UAVs_pos);
    
    t = toc; 
    pause((time>t)*(time-t)); % Wait till the time of the FPS have been. 
end
end

