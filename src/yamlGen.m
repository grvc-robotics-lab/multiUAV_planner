function yamlGen(mission_name, mission_description, mode_landing, wp, h_insp, bases_pos, bases_names, offset, vel, UAVs_model, UAVs_model_ID)

n_UAVs = length(wp);

if ~exist('./mission', 'dir')
    mkdir('./mission');
end

fileName = "./mission/mission_"+mission_name+".yaml";
fileID=fopen(fileName,'w+');
fprintf(fileID, strcat("version: ",char(39),"3",char(39)));
fprintf(fileID,'\n');

fprintf(fileID,'frame_id: /gps\n');
fprintf(fileID,'\n');

fprintf(fileID,'\n');

fprintf(fileID, strcat("description: ",char(39),mission_description,char(39)));
fprintf(fileID,'\n');

fprintf(fileID, 'route:');
fprintf(fileID, '\n');


for UAV = 1:n_UAVs
    wp_tour = wp{UAV};

    fprintf(fileID, strcat("  - name: ",char(34),mission_name,"  ",bases_names{UAV},char(34)));
    fprintf(fileID, '\n');
    fprintf(fileID, strcat("    uav: ",char(39),"uav_",string(UAV),char(39)));
    fprintf(fileID, '\n');
    fprintf(fileID, '    wp:');
    fprintf(fileID, '\n');

    for wp_node = 1:size(wp_tour,1)
        if UAVs_model{UAV}.camera
            if wp_node == 1
                gimbal = wp_tour(2, 6);
                yaw = wp_tour(2, 5);
                action = strcat(", action: {video_start: 0, gimbal: ",string(round(gimbal,1)),", yaw: ", string(round(yaw,1))+"}");
            elseif wp_node == length(wp_tour)
                action = ", action: {video_stop: 0}";
            else
                gimbal = wp_tour(wp_node, 6);
                yaw = wp_tour(wp_node, 5);
                action = strcat(", action: {gimbal: ",string(round(gimbal,1)),", yaw: ", string(round(yaw,1)),"}");
            end
        else
            action = "";
        end
        h = wp_tour(wp_node,3)-bases_pos(UAV,3);
        fprintf(fileID, "      - {pos: [%.8f, %.8f, %f]", wp_tour(wp_node, 1),wp_tour(wp_node, 2), h);
        fprintf(fileID, action);
        fprintf(fileID, "}");
        fprintf(fileID, '\n') ;
    end

    fprintf(fileID, '    attributes:');
    fprintf(fileID, '\n\n');
    fprintf(fileID, '      mode_landing: %d', mode_landing(UAV));
    fprintf(fileID, '\n\n');
    fprintf(fileID, '      mode_yaw: 3');
    fprintf(fileID, '\n\n'); 
    fprintf(fileID, '      idle_vel: %.1f', vel(UAV)); 
    fprintf(fileID, '\n\n\n') ;
end


fclose(fileID);


end