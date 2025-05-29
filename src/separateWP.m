function wp = separateWP(offset_wp, grid_connections, tours, towers_pos, base_pos, n_UAVs, inspection_height, towers_height, UAVs_model)
wp = cell(size(tours));
% Change x and y to easy geometry
towers_pos = [towers_pos(:,2), towers_pos(:,1),towers_pos(:,3)];
for UAV =  1:n_UAVs
    offset = offset_wp(UAV);
    towers_height_UAV = [0,0,towers_height,0,0, 0];
    inspection_height_UAV = [0,0,towers_height + inspection_height(UAV),0,0, 0];
    wp_tour = [[base_pos(UAV, :), 0, 0, 0] + towers_height_UAV; [base_pos(UAV, :), 0, 0, 0] + inspection_height_UAV];
    tour = tours{UAV};
    tour = tour(:,1:2);
    n_wp_tour = length(tour);
    %% GIMBAL
    gimbal = - atand((inspection_height(UAV))/offset);
    if offset == 0
        for i = 1:n_wp_tour-1
            node_1 = tour(i,2);
            node_2 = tour(i+1,2);
            isVector1Grid = any((grid_connections(:,1) ==node_1 & grid_connections(:,2) ==node_2) |...
                (grid_connections(:,1) ==node_2 & grid_connections(:,2) ==node_1));
            if node_1 & node_2
                vector = towers_pos(node_2,1:2) - towers_pos(node_1,1:2);
            elseif  node_2
                vector = towers_pos(node_2,1:2) - [base_pos(UAV,2),base_pos(UAV,1)];
            elseif node_1
                vector = [base_pos(UAV,2),base_pos(UAV,1)] - towers_pos(node_1,1:2);
            end
            yaw = atan2(vector(2), vector(1));
            yaw = yaw * 180/pi;
            % % Change references system to North = 0;
            yaw = yaw - 90;
            % Adjust the value to the range
            while yaw > 180 | yaw < -180
                yaw = yaw -sign(yaw)*360;
            end
            % Change to ounterclockwise to clockwise
            yaw = - yaw;
            % Round
            yaw = round(yaw,7);
            wp_tour = [wp_tour;[towers_pos(node_1,2),towers_pos(node_1,1),towers_pos(node_1,3),isVector1Grid, yaw, gimbal]+inspection_height_UAV];
        end
        wp_tour = [wp_tour; [base_pos(UAV, :), 0, 0, 0] + inspection_height_UAV;];        %% Correct the first angle
        %% Correct the angle of the first edge
        % It is the 3 and 2 because the wp at the base its duplicated to
        % can orientate.
        vector_0 = [wp_tour(3,2), wp_tour(3,1)] - [wp_tour(2,2), wp_tour(2,1)];
        angle_0= atan2(vector_0(2), vector_0(1));
        % Convert to º
        angle_0 = angle_0 * 180/pi;
        % % Change references system to North = 0;
        angle_0 = angle_0 - 90;
        % Adjust the value to the range
        while angle_0 > 180 | angle_0 < -180
            angle_0 = angle_0 -sign(angle_0)*360;
        end
        % Change to ounterclockwise to clockwise
        angle_0 = -angle_0;
        % Round
        angle_0 = round(angle_0,7);
        wp_tour(2,5) = angle_0;  
        wp_tour(2,6) = gimbal; 
    else
        for i = 1:n_wp_tour-1
            %%  Save nodes1
            node_1 = tour(i, 1);
            node_2 = tour(i,2);
            node_3 = tour(i+1,2);

            %% Check if the vectors are Power Lines
            isVector1Grid = any((grid_connections(:,1) ==node_1 & grid_connections(:,2) ==node_2) |...
                (grid_connections(:,1) ==node_2 & grid_connections(:,2) ==node_1));
            isVector2Grid = any((grid_connections(:,1) ==node_2 & grid_connections(:,2) ==node_3) |...
                (grid_connections(:,1) ==node_3 & grid_connections(:,2) ==node_2));

            %% Calculate vectors
            if node_1 == 0
                vector_1 = towers_pos(node_2,1:2)-[base_pos(UAV,2),base_pos(UAV,1)];
            else
                vector_1 = towers_pos(node_2,1:2)-towers_pos(node_1,1:2);
            end
            if node_3 == 0
                vector_2 = [base_pos(UAV,2),base_pos(UAV,1)] - towers_pos(node_2,1:2);
            else
                vector_2 = towers_pos(node_3,1:2)-towers_pos(node_2,1:2);
            end
            %% Calculate angles of vectors
            alpha_2= atan2(vector_2(2), vector_2(1)); %% Y axis is W, the first component
            alpha_1= atan2(vector_1(2), vector_1(1));

            if isVector1Grid & isVector2Grid
                %% Both vectors are Power Lines
                alpha = alpha_2-alpha_1+pi;
                angle_margin = 10*pi/180; %degree
                if abs(alpha) < (pi+angle_margin) & abs(alpha) > (pi-angle_margin)
                    %% Both vectors are almost paralel
                    beta = alpha_1+alpha/2;%*abs(sin(pi-2*beta)/sin(beta));
                    nodes = node_2;
                    % %% Select side for the new wp to not cross the Power Line
                else
                    beta = [alpha_1 + pi/2,alpha_2 + pi/2];
                    nodes =[node_2, node_2];
                    %% The vectors aren't parallel:
                    % There are going to be 2 new wp. The  first one is from the same pylon,
                    % while the second one is in relation to the next pylons.
                    % %% Select the first wp to position parallel to the Power Line
                end
                %% At least one vector is not a Power Line
            else
                if isVector1Grid
                    beta = alpha_1 + pi/2;
                elseif isVector2Grid
                    beta = alpha_2 + pi/2;
                end
                nodes = node_2;
            end
            new_wp = [];
            yaw =[];
            for j = 1:length(beta)
                %% Select the nearest posibility
                % If it's the neares, the trajectory dont have to cut the
                % Power Line.
                if isempty(new_wp)
                    point = [wp_tour(end,2), wp_tour(end,1)];
                else
                    point = [new_wp(end,1:2)];
                end
                distPos = norm(towers_pos(nodes(j),1:2)+offset*[cos(beta(j)), sin(beta(j))] - point);
                distNeg = norm(towers_pos(nodes(j),1:2)-offset*[cos(beta(j)), sin(beta(j))] - point);
                if distPos < distNeg
                    aux = round(towers_pos(nodes(j),:)+offset*[cos(beta(j)), sin(beta(j)), 0], 9);
                    aux_yaw = beta(j) - pi;
                else
                    aux = round(towers_pos(nodes(j),:)-offset*[cos(beta(j)), sin(beta(j)), 0], 9);
                    aux_yaw = beta(j);
                end
                if node_3 == 0 | isVector2Grid == 0
                    aux_yaw = alpha_2;
                end
                %% YAW
                % Convert to º
                aux_yaw = aux_yaw * 180/pi;
                % % Change references system to North = 0;
                aux_yaw = aux_yaw - 90;
                % Adjust the value to the range
                while aux_yaw > 180 | aux_yaw < -180
                    aux_yaw = aux_yaw -sign(aux_yaw)*360;
                end
                % Change to ounterclockwise to clockwise
                aux_yaw = -aux_yaw;
                % Round
                aux_yaw = round(aux_yaw,7);
                %% If it not the previous waypoint, it's include to the list of wp
                if ((size(new_wp,1)==0) & ~((aux(1)==wp_tour(end,2)) & (aux(2)==wp_tour(end,1)) & (aux(3)==wp_tour(end,3)) & aux_yaw == wp_tour(end,5)))
                    new_wp = [new_wp; [aux,isVector1Grid, aux_yaw, gimbal]];
                elseif (size(new_wp,1) > 0)
                    if ~all(aux == new_wp(end,1:3) & aux_yaw == new_wp(end, 5))
                        new_wp = [new_wp; [aux,isVector1Grid, aux_yaw, gimbal]];
                    end
                end

            end
            %% Save new waypoint
            wp_tour = [wp_tour; [new_wp(:,2), new_wp(:,1),new_wp(:,3), new_wp(:,4), new_wp(:,5), new_wp(:,6)]+inspection_height_UAV];

        end
        %% Save last wp, the base
        wp_tour = [wp_tour; [base_pos(UAV, :), 0, 0, 0] + inspection_height_UAV;];
        %% Correct the first angle
        % It is the 3 and 2 because the wp at the base its duplicated to
        % can orientate.
        vector_0 = [wp_tour(3,2), wp_tour(3,1)] - [wp_tour(2,2), wp_tour(2,1)];
        angle_0= atan2(vector_0(2), vector_0(1));
        % Convert to º
        angle_0 = angle_0 * 180/pi;
        % % Change references system to North = 0;
        angle_0 = angle_0 - 90;
        % Adjust the value to the range
        while angle_0 > 180 | angle_0 < -180
            angle_0 = angle_0 -sign(angle_0)*360;
        end
        % Change to ounterclockwise to clockwise
        angle_0 = -angle_0;
        % Round
        angle_0 = round(angle_0,7);
        wp_tour(2,5) = angle_0; 
        wp_tour(2,6) = gimbal 
    end
    wp{UAV}=wp_tour;
end
end

% function wp = separateWP(offset_wp_UAV, grid_connections, tours, towers_pos, base_pos, n_UAVs)
%        wp = cell(size(tours));
%        towers_pos = [towers_pos(:,2), towers_pos(:,1),towers_pos(:,3)];
%
%        for UAV =  1:n_UAVs
%            wp_tour = base_pos(UAV, :);
%            tour = tours{UAV};
%            tour = tour(:,1:2);
%            n_wp_tour = length(tour)-1;
%            for i = 1:n_wp_tour
%                 node_1 = tour(i, 1);
%                 node_2 = tour(i,2);
%                 node_3 = tour(i+1,2);
%                 if node_1 == 0
%                     vector_1 = towers_pos(node_2,1:2)-base_pos(UAV,1:2);
%                 else
%                     vector_1 = towers_pos(node_2,1:2)-towers_pos(node_1,1:2);
%                 end
%                 if node_3 == 0
%                     vector_2 = base_pos(UAV,1:2)- towers_pos(node_2,1:2);
%                 else
%                     vector_2 = towers_pos(node_3,1:2)-towers_pos(node_2,1:2);
%                 end
%                isVector1Grid = any((grid_connections(:,1) ==node_1 & grid_connections(:,2) ==node_2) |...
%                    (grid_connections(:,1) ==node_2 & grid_connections(:,2) ==node_1));
%                isVector2Grid = any((grid_connections(:,1) ==node_2 & grid_connections(:,2) ==node_3) |...
%                    (grid_connections(:,1) ==node_3 & grid_connections(:,2) ==node_2));
%                if isVector1Grid & isVector2Grid
%                     alpha_2= atan2(vector_2(2), vector_2(1)); %% Y axis is W, the first component
%                     alpha_1= atan2(vector_1(2), vector_1(1));
%                     alpha = alpha_2-alpha_1+pi;
%                     beta = alpha_1+alpha/2;
%                 offset = offset_wp_UAV*abs(sin(pi-2*alpha)/sin(alpha));
%                elseif isVector1Grid
%                     alpha_1= atan2(vector_1(2), vector_1(1));
%                     beta = alpha_1 + pi/2;
%                     offset = offset_wp_UAV;
%                elseif isVector2Grid
%                     alpha_2= atan2(vector_2(2), vector_2(1));
%                     beta = alpha_2 + pi/2;
%                     offset = offset_wp_UAV;
%                end
%                 new_wp = towers_pos(node_2,:)+offset*[cos(beta), sin(beta), 0];
%                 wp_tour = [wp_tour; [new_wp(:,2), new_wp(:,1),new_wp(:,3) ]];
%            end
%            wp_tour = [wp_tour; base_pos(UAV, :)];
%            wp{UAV}=wp_tour;
%        end
% end

