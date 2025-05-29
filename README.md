# Multi-UAVs planner for power-lines inspection

 A functional planner with UI for power-lines and towers inspections with a heterogeneous multi-UAVs team. 

## Description
The main objective of this planner is allow the user to obtain a mission to inspect power lines using a heterogeneous multi-UAVs teams. The planner focus on minimize the total time of the mission. 

Also, the UI allow the user to specify different aspect of the mission and different cases of uses. 

![Planner](./media/planner.png)

### UI options
 - Introduce different parameters that each UAV will need during the mission. 
 - Import weather data from internet or introduce manually. 
 - Import terrain elevation data from internet or use local data. 
 - Allow clustering on inspection of power segments. 
 - Invert the plan of a specific UAV. 
 - Simulate the mission on different velocity. 
 - Generate files *.yaml and *.kml of the mission. 

### Cases of use
 - Inspect different segments of the power grid. 
 - Inspect one tower from different angles. 

### How to Install
Clone the repository to your computer: 

``` bash
git clone https://github.com/fraromesc/pli_planner
```

#### Requirements : 
 - Matlab R2023a or newer. 
 - [Optimization Toolbox](https://nl.mathworks.com/products/optimization.html)
 - [Image Processing Toolbox](https://nl.mathworks.com/products/image-processing.html) 
 
## Quick Start 
### Launch GUI
Run on Matlab's Command Window: 


``` Matlab
run gui_planner
```

### Load Map
To load the map is necessary to complete all the parameters at the box at top right. To define the map are required:
 - Average tower height.
 - Select if the elevation of the terrain will be collected from [Open Topo Data](https://www.opentopodata.org/datasets/eudem/).
 - Paths of three files at the boxes:

    1. **Tower file:** This file define the positions and connection betweens towers and how they are connected. It is a .kml file created by [Google Earth Pro](https://www.google.com/intl/es/earth/about/versions/#earth-pro). To generate it is recommended follow the steps at this video.

        ![Select towers](./media/guidePylons.gif)

    2. **Bases file:** This file define the positions of the bases. It is a .kml file created on [Google Earth Pro](https://www.google.com/intl/es/earth/about/versions/#earth-pro). To generate it is recommended follow the steps at this video.

        ![Select bases](./media/guideStations.gif)

    3. **UAVs file:** This file define the UAVs which will be use at the mission and the batteries they will use. The file '/files/UAVs_bat_data.m" is an example that may be used as a guide to create others. 

### Configure Mission Parameters

   1. At the top table, select all parameters for each base.
        - The information about all UAVs and batteries available are at the box 'Information', at the left side.
        - The relative position of the UAV respect to the power line can be determined by defined two parameters:
            - 'Horizontal offset' and 'Inspection height'
            - 'Distance offset' and 'Gimbal angle' 
   2.  Update weather condition manually or with online data (based on the first base position). 

### Select Mission
Depends the mission, there are two options to plan. At both cases, it is able to change the direction of a specific UAV.  
1. **Segments inspection:** 
    Clicking the button 'Planner', a mission to inspect all the segments using all the UAVs defined will be planned. At this case of use you can decide cluster the towers to obtain a mission faster that can required more time. 
2. **Tower inspection:**
    Clicking the button 'Inspect', a mission to inspect a specific tower with an specific UAV will be planned. At this case is necessary to determinate:
    - UAV to do the inspection. 
    - Tower to inspect.
    - How many photos od the tower are required. 

### Simulation
It is able to obtain a simple simulation with the button 'Simulation' to check the directions of the UAVs and the relative position. The speed can be increased or decreased by box 'Speed simulation'.

### Generate files
While there is a correct mission, the files .yaml (to the GCS) and .kml (to visualize on Google Earth Pro) can ge generated, defined a name and a brief description. The files will be generated at the main folder of the repo as 'mission_{Mission Name}.kml' and 'mission_{Mission Name}.yaml'. 
