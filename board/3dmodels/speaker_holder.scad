$fn=35;
OUT_SPKR_DIAM=10;
IN_SPKR_DIAM=8;
PAD=2;

difference() {
    cube([OUT_SPKR_DIAM+PAD, OUT_SPKR_DIAM+PAD, 0.5], center=true);
    
    translate([0, 0, 0.151])
    cylinder(h=0.2, r=OUT_SPKR_DIAM/2, center=true);
    cylinder(h=0.51, r=IN_SPKR_DIAM/2, center=true);
    
    for(x= [-1, 1]) {
        for(y= [-1, 1]) {
            translate([(OUT_SPKR_DIAM+PAD/2)/2*x-x, (OUT_SPKR_DIAM+PAD/2)/2*y-y, 0])
            cylinder(h=1.1, r=1, center=true);
        }
    }
}