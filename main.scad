include <lib/airfoil.scad>
include <lib/grid.scad>

$wing_length = 18;
$naca_airfoil = 4412;
$wing_chord_length = 150;
$rib_grid_distance = $wing_chord_length / 4 / sqrt(2);
$airfoil_cutoff_chord_fraction = 0.98;

$spar_enabled = true;
$spar_diameter = 10.4;
// Not _really_ required, but having this as a multiple of the rib_grid_distance / 2 fraction is ideal
$spar_position_chord_fraction = 1 / 4 / 2 * 3;
$spar_holding_structure_height_chord_fraction = 0.055;

$center_gap = 0.6;
$rib_width = 0.2;
$wing_x_offset_chord_fraction = 0.002;

// Make the grid as high as the chord length, so every thickness of wing up to a circular profile is acceptable
$grid_height = $wing_chord_length;

module generateStructureGrid() {
    $grid_diagonal_distance = $rib_grid_distance * sqrt(2);
    union()
    grid(ceil($wing_chord_length / $grid_diagonal_distance), ceil($wing_length / $grid_diagonal_distance) + 1, $grid_diagonal_distance)
    rotate([0, 45, 0])
    translate([0, -$grid_height / 2, 0])
    difference() {
        cube([$rib_grid_distance + $rib_width / 2, $grid_height, $rib_grid_distance + $rib_width / 2]);
        translate([$rib_width / 2, 0, $rib_width / 2])
        cube([$rib_grid_distance - $rib_width / 2, $grid_height, $rib_grid_distance - $rib_width / 2]);
    }
}

module generateWing() {
    intersection() {
        translate([0, -$wing_chord_length, 0])
        cube([$airfoil_cutoff_chord_fraction * $wing_chord_length, $wing_chord_length * 2, $wing_length]);
        
        translate([$wing_x_offset_chord_fraction * $wing_chord_length, 0, 0])
        linear_extrude(height = $wing_length)
            airfoil_poly($wing_chord_length, $naca_airfoil);
    }
}

module generateSparStructureGap() {
    if ($spar_enabled)
    translateToMclPoint($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
    linear_extrude(height = $wing_length)
    union() {
        circle(d=$spar_diameter + 1, $fn=30);
        square(size = [2, $wing_chord_length*2], center=true);
    }
}

module generateSparStructure() {
    if ($spar_enabled)
    translateToMclPoint($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
    linear_extrude(height = $wing_length)
    union() {
        circle(d=$spar_diameter, $fn=30);
        translate([0, -0.5, 0])
        translateFromMclToSurface($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
        translate([0, - $wing_chord_length, 0])
        square(size = [0.1, $wing_chord_length*2], center=true);
    }
}

module generateInnerStructure() {
    difference() {
        intersection() {
            generateWing();
            generateStructureGrid();
        }
        generateSparStructureGap();
        linear_extrude(height = $wing_length)
            mcl_poly($wing_chord_length, $naca_airfoil, $center_gap);
    }
}

difference() {
    generateWing();
    generateInnerStructure();
    generateSparStructure();
}

// generateSparStructure();