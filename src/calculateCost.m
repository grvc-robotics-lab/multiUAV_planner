function total_cost=calculateCost(cost, edges, tours)
    total_cost = [];
    for j = 1:size(tours,1)
        cost_tour = 0; 
        tour=tours{j}; 
        for path = 1:size(tour,1) 
            aux = find(edges(:,1)==tour(path,1) & edges(:,2)==tour(path,2) & edges(:,3)==tour(path,3))  ;
            cost_tour = cost_tour + cost(aux);
        end
        total_cost=[total_cost, cost_tour]; 
    end
end

