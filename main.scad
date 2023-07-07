include <lib/airfoil.scad>
include <lib/grid.scad>

// ----- Wing settings ----- 
$wing_length = 26;
$naca_airfoil = 4412;
$wing_chord_length = 165;
$rib_grid_distance = 165 / 4 / sqrt(2);
$airfoil_cutoff_chord_fraction = 0.98;

$angle_of_incedence = 2.5;

// ----- Structure settings ----- 
// For ribs running all the way through the wing, set this value very high (greater than then chord length).
$rib_thickness = 1.5;
$rib_center_support_cones_enabled = true;
$rib_center_support_cone_inersection_diameter = 3;
$rib_center_support_cone_angle = 40; //degrees

// ----- Spar settings ----- 
$spar_enabled = true;
$spar_diameter = 10.4;
// Not _really_ required, but having this as a multiple of the rib_grid_distance / 2 fraction is ideal
$spar_position_chord_fraction = 1 / 4 / 2 * 3;
$spar_holding_structure_height_chord_fraction = 0.055;

// ----- Nitty gritty details ----- 
$center_gap = 0.9;
$rib_width = 0.1;
$wing_x_offset_chord_fraction = 0.002;

// Make the grid as high as the chord length, so every thickness of wing up to a circular profile is acceptable
$grid_height = $wing_chord_length;
$rib_center_support_sections_length = $wing_chord_length;

// ----- Code ----- 

/// Structure grid
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

/// Wing
module generateWing2D() {
    intersection() {
        translate([0, -$wing_chord_length])
        square([$airfoil_cutoff_chord_fraction * $wing_chord_length, $wing_chord_length * 2]);
        airfoil_poly($wing_chord_length, $naca_airfoil);
    }
}

module generateWing() {
    linear_extrude(height = $wing_length)
        generateWing2D();
}

/// Alignment spar
module generateAlignmentSpar2D() {
    translate([0, -2.7, 0])
    translateToMclPoint($wing_chord_length, $naca_airfoil, 0.05) {
        circle(d=3.9, $fn=30);
        translate([0, -$wing_chord_length / 2, 0])
        square(size = [0.1, $wing_chord_length], center=true);
    }
}

/// Spar
module generateSparStructureGap() {
    if ($spar_enabled)
    translateToMclPoint($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
    linear_extrude(height = $wing_length)
    union() {
        offset(delta = 1)
            rotate([0, 0, $angle_of_incedence]) {
                square(size = [20 + 0.1, 15 + 0.4], center=true);
                square(size = [28, 6.5], center=true);
            }
        square(size = [2, $wing_chord_length*2], center=true);
    }
}

module generateSparStructure() {
    if ($spar_enabled)
    translateToMclPoint($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
    linear_extrude(height = $wing_length)
    union() {
        rotate([0, 0, $angle_of_incedence]) {
            square(size = [20 + 0.1, 15 + 0.4], center=true);
            square(size = [28, 6.5], center=true);
        }
        translate([0, -0.5, 0])
        translateFromMclToSurface($wing_chord_length, $naca_airfoil, $spar_position_chord_fraction)
        translate([0, - $wing_chord_length, 0])
        square(size = [0.1, $wing_chord_length*2], center=true);
    }
}

/// Structure
module generateInnerStructureSupportCones() {
    // The / 2 causes every grid intersection to have a cone
    $grid_diagonal_distance = $rib_grid_distance * sqrt(2) / 2;
    if ($rib_center_support_cones_enabled)
    mclFollowingGrid(
        $wing_chord_length,
        $naca_airfoil,
        ceil($wing_chord_length / $grid_diagonal_distance),
        ceil($wing_length / $grid_diagonal_distance) + 1,
        $grid_diagonal_distance
        )
    rotate([90, 0, 0])
    union() {
        mirror([0, 0 ,1])
        translate([0, 0, -$rib_center_support_sections_length])
        cylinder(h = $rib_center_support_sections_length, d1 = $rib_center_support_cone_inersection_diameter + 2 * tan($rib_center_support_cone_angle) * $rib_center_support_sections_length, d2 = $rib_center_support_cone_inersection_diameter, center = false);

        translate([0, 0, -$rib_center_support_sections_length])
        cylinder(h = $rib_center_support_sections_length, d1 = $rib_center_support_cone_inersection_diameter + 2 * tan($rib_center_support_cone_angle) * $rib_center_support_sections_length, d2 = $rib_center_support_cone_inersection_diameter, center = false);
    }
}

module generateInnerStructureCutout() {
    difference() {
        linear_extrude(height = $wing_length) {
            offset(delta = -$rib_thickness)
                generateWing2D();
            offset(delta = 1)
                generateAlignmentSpar2D();
        }
        generateInnerStructureSupportCones();
    }
}

module generateInnerStructure() {
    difference() {
        intersection() {
            generateWing();
            generateStructureGrid();
        }
        generateInnerStructureCutout();
        generateSparStructureGap();
        linear_extrude(height = $wing_length)
            mcl_poly($wing_chord_length, $naca_airfoil, $center_gap);
    }
}

difference() {
    generateWing();
    generateInnerStructure();
    generateSparStructure();
    linear_extrude(height = $wing_length)
        generateAlignmentSpar2D();
}

// generateAlignmentSpar2D();