function drawSol(fig, segments,  UAVs_base_pos, UAVs_base_name, n_UAVs, towers_pos, tours,wp, UAVs_pos)
cla(fig);
hold(fig,'on');
legend_label=[];


%% Axis
axis(fig,'equal');
axi_x = [towers_pos(:,2);  UAVs_base_pos(:,2)]; 
axi_y = [towers_pos(:,1); UAVs_base_pos(:,1)]; 
if ~isempty(wp)
    for UAV = 1:length(tours)
        axi_x = [axi_x; wp{UAV}(:,2)];
        axi_y = [axi_y; wp{UAV}(:,1)];
    end
end

xlabel(fig,'West-East [m]', 'FontSize', 16, 'FontWeight', 'bold');  
ylabel(fig, 'South-North [m]', 'FontSize', 16, 'FontWeight', 'bold');  
    
axis_margin = 0.1*max( (max(axi_x)-min(axi_x)), (max(axi_y)-min(axi_y)));

minX = min(axi_x)-axis_margin; 
minY = min(axi_y)-axis_margin;

axis(fig,[ 0 max(axi_x)+axis_margin-minX 0 max(axi_y)+axis_margin-minY ]);

grid(fig, 'on')
towers_pos(:,1) = towers_pos(:,1) - minY; 
towers_pos(:,2) = towers_pos(:,2) - minX; 

UAVs_base_pos(:,1) = UAVs_base_pos(:,1) - minY; 
UAVs_base_pos(:,2) = UAVs_base_pos(:,2) - minX; 

if ~isempty(UAVs_pos)
    UAVs_pos(:,1) = UAVs_pos(:,1) - minY; 
    UAVs_pos(:,2) = UAVs_pos(:,2) - minX; 
end

if ~isempty(wp)
    for UAV = 1:length(tours)
    wp{UAV}(:,1) = wp{UAV}(:,1) -minY; 
    wp{UAV}(:,2) = wp{UAV}(:,2) -minX;
    end
end


%% UAVs Pos with image
if ~isempty(UAVs_pos)
    if exist("UAV_image.jpg")
        % Load image
        UAV_image = imread("UAV_image.jpg");
        % Correct colors
        threshold = 255/2;
        bg = find(UAV_image < threshold);
        fg = find(UAV_image >= threshold);
        UAV_image(bg) = 255;
        UAV_image(fg) = 0;
        % Correct original angle of image
        UAV_image=imrotate(UAV_image, -90);
        image_size = 0.05*(max(towers_pos(:,2)) - min(towers_pos(:,2)));
        for UAV =1:n_UAVs
            % Coordinates of centre
            x = (image_size/2)*[1 -1] + UAVs_pos(UAV,1);
            y = (image_size/2)*[1 -1] + UAVs_pos(UAV,2);
            % Orientate image of the angle 
            UAV_image_mod = imrotate(UAV_image, UAVs_pos(UAV,3));
            % Correct colors
            bg_mod = find(UAV_image_mod < threshold);
            fg_mod = find(UAV_image_mod >= threshold);
            UAV_image_mod(bg_mod) = 255;
            UAV_image_mod(fg_mod) = 0;
            UAVs_c = 1:n_UAVs; 
            UAVs_c = UAVs_c(UAVs_c ~= UAV); 

            UAV_image_mod(:,:,UAV) = 255 * ones(size(UAV_image_mod(:,:,UAV)));
            %Draw UAV icon
            image(fig,y,x,UAV_image_mod);
        end
    else
        % If there isn't an image 
        for UAV = 1:n_UAVs
            color = mod(UAV, length(colors));
            plot(fig, UAVs_pos(UAV,2), UAVs_pos(UAV,1),'Marker', 'hexagram',  'MarkerEdgeColor',colors(color,:), 'MarkerFaceColor',colors(color,:),"MarkerSize", 20);
            legend_label = [legend_label, "UAV " + string(UAV)];
        end
    end
end
%% Bases
for i = 1:size(UAVs_base_pos,1)
    legend_label=[legend_label,""];
    plot(fig,UAVs_base_pos(i,2), UAVs_base_pos(i,1),"m.", "MarkerSize", 40); %grid on;
end
legend_label=legend_label(1:end-1);
legend_label=[legend_label,"UAV stations"];
%% Bases names
for base = 1:n_UAVs
    text(fig,UAVs_base_pos(base,2), UAVs_base_pos(base,1), UAVs_base_name(base,:)+ " ", 'FontSize',25,'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom')
end

%% Towers & Segments
for i=1:length(segments)
    node_1 = segments(i, 1);
    node_2 =  segments(i, 2);
    x=[towers_pos(node_1,2),towers_pos(node_2,2)];
    y=[towers_pos(node_1,1),towers_pos(node_2,1)];
    plot(fig,x,y, "k.", "LineWidth",6, "MarkerSize",40)
    plot(fig,x,y, "k-", "LineWidth",4, "MarkerSize",12)
    legend_label=[legend_label,"", ""];
end
legend_label=legend_label(1:end-2);
legend_label=[legend_label,"Electric pylons","Connections"];



%% Name of towers
tx_offset = 0.5 * abs(towers_pos(2,2)-towers_pos(1,2));
ty_offset = 0.5 * abs(towers_pos(2,1)-towers_pos(1,1));
for tower = 1:length(towers_pos)
    if any(tower == [1:10]) 
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "T"+string(tower)+"  ", 'FontSize',22, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom')
    elseif any(tower == [11:18])
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "  T"+string(tower), 'FontSize',22, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top')
    elseif any(tower == [19:23])
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "T"+string(tower)+" ", 'FontSize',22, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom')
    elseif tower == 22
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "T"+string(tower)+"  ", 'FontSize',22, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle')
    elseif any(tower == [24, 25])
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "  T"+string(tower) + "  ", 'FontSize',22, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top')
    elseif any(tower == 26)
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "  T"+string(tower), 'FontSize',22, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top')
    elseif any(tower == 27)
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "  T"+string(tower), 'FontSize',22, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')
    else 
        text(fig,towers_pos(tower,2), towers_pos(tower,1), "  T"+string(tower), 'FontSize',22, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top')
    end
end


%% Colors
colors=["r", "g", "b","m","y","c","k","w"]';
colors=[1,0,0;...
    0,1,0;...
    0,0,1;...
    1,0,1;...
    1,1,0;...
    0,1,1;...
    0,0,0];

%% Tours with offset
for UAV = 1:length(tours)
    tour = tours{UAV};
    color = mod(tour(1,3), length(colors));
    if ~isempty(wp)
        wp_tour = wp{UAV};
        for i=1:size(wp_tour,1)-1
            
            plot(fig, wp_tour(i:i+1,2), wp_tour(i:i+1,1),'Color',colors(color,:), 'LineStyle','-','Marker','.','MarkerSize', 1,'LineWidth',2  );
            legend_label = [legend_label, ""];
        end
        legend_label=legend_label(1:end-1);
        legend_label = [legend_label,"Plan UAV " + string(UAV)];
   
    end
end





%% Legend
legend(fig,legend_label(:))


    
end
