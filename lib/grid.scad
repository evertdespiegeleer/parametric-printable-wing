// grid(26, 26, 10)
// 	cylinder(r = 2, h = 10, $fn = 10);

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