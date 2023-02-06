pi=3.141592;
$fn=16;
module tooth(pitch){
	translate([0,0,0])scale([2,1,1])circle(pitch/2,$fn=24);
	}

module gear2d(teeth,pitch,clearance){
		union(){
			translate([0,0,0])circle(((pitch*teeth)/pi)-clearance,$fn=100);
			for(n=[1:teeth]){
				rotate([0,0,(360/teeth)*n])
				translate([(pitch*teeth)/pi,0,0])tooth(pitch*1.1);
			}
		}
	}
    
    
module pin(factor=1) {
PIN_HEIGHT=2.5;
color("silver")
cube([1*factor, 0.4*factor, PIN_HEIGHT], center=true);
}

GEAR_HEIGHT=2;
color("black")
difference() {
linear_extrude(height=GEAR_HEIGHT, center=true,convexity=10,twist=0,slices=1)
gear2d(teeth=120,pitch=0.2,clearance=0);
cylinder(h=2.1, r=2, center=true);
}

// base
color("silver")
translate([0, 1.5, 1.25])
cube([11.4, 12.5, 0.5], center=true);

// mechanical
translate([-5, -2.5, 2.75])
rotate([0,0,90])
pin(factor=1.5);


translate([5, -2.5, 2.75])
rotate([0,0,90])
pin(factor=1.5);

// pins

translate([-4, 7.5, 2.75])
pin();
translate([0, 7.5, 2.75])
pin();
translate([4, 7.5, 2.75])
pin();