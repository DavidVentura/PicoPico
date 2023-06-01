$fn=20;
PIN_HEIGHT=2.8;
PIN_SPACING=2;

// main body
color("silver")
cube([8.6, 4.4, 4.7], center=true);

// switch
color("black")
translate([1-2*$t, 4, 0])
rotate([0, 90, 0])
cube([2.0, 4.0, 2.0], center=true);

// switch displacement area
color("gray")
translate([0, 2.2, 0])
rotate([0, 90, 0])
cube([2.0, 0.1, 4.0], center=true);

// mechanical pins
color("darkgray")
translate([-8.6/2+0.4/2, 0, -(PIN_HEIGHT/2)-(4.7/2)])
cube([0.4, 1.2, PIN_HEIGHT], center=true);

color("darkgray")
translate([8.6/2-0.4/2, 0, -(PIN_HEIGHT/2)-(4.7/2)])
cube([0.4, 1.2, PIN_HEIGHT], center=true);

// electrical pins
color("darkgray")
translate([-8.6/2+0.4/2+PIN_SPACING*1, 0, -(PIN_HEIGHT/2)-(4.7/2)])
cylinder(r=0.25, h=PIN_HEIGHT, center=true);
color("darkgray")
translate([-8.6/2+0.4/2+PIN_SPACING*2, 0, -(PIN_HEIGHT/2)-(4.7/2)])
cylinder(r=0.25, h=PIN_HEIGHT, center=true);

color("darkgray")
translate([-8.6/2+0.4/2+PIN_SPACING*3, 0, -(PIN_HEIGHT/2)-(4.7/2)])
cylinder(r=0.25, h=PIN_HEIGHT, center=true);