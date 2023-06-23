include <./airfoil.scad>

module grid(x, z, space)
{
	for (i = [0:1:x-1]) {
		for (j = [0:1:z-1]) {
			translate([i*space, 0, j*space]) {
				children();
			}
		}
	}
}

module mclFollowingGrid(c = 100, naca = 0015, x, z, space)
{
	for (i = [0:1:x-1]) {
		for (j = [0:1:z-1]) {
			translate([0, 0, j*space]) {
				translateToMclPoint(c, naca, i*space/c)
					children();
			}
		}
	}
}