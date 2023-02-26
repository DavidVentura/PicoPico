$fn=35;
SPKR_DIAM=10;

difference() {
    cube([SPKR_DIAM+3, SPKR_DIAM+3, 0.5], center=true);
    cylinder(h=1.1, r=SPKR_DIAM/2, center=true); // main speaker hole
    
    for(x= [-1, 1]) {
        for(y= [-1, 1]) {
            translate([5*x, 5*y, 0])
            cylinder(h=1.1, r=1, center=true);
        }
    }
}