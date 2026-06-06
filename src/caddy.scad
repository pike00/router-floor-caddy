// Router floor caddy — Xfinity XB8 + Netgear Orbi RBR850
// SINGLE-PIECE vented floor box: one shell, three internal bays, prints whole.
//
//   Orbi is rotated 90deg (thin 72mm edge sideways) so both towers + a storage
//   bay pack into a ~206 x 200 mm footprint that fits a 256 mm bed in one print.
//
//   export:  openscad -o export/caddy.stl src/caddy.scad
//
// Coordinates: X = width, Y = depth (front = -Y, lowered for access; back = +Y,
// cable entry), Z = up. Towers stand in vented bays and protrude above the open
// tops, fully exposed for cooling.

// ----------------------------- parameters ----------------------------------
$fn = 32;                       // global smoothness (raise for final export)

// fit
clearance = 2;                  // router-to-wall gap, per side (loose insert)

// structure
wall        = 3;                // shell + divider thickness
floor_th    = 3;                // perforated floor thickness
foot_height = 16;               // body standoff = base ring height -> under-caddy air gap
outer_h     = 140;              // shell wall height (grips lower half of towers)
front_lip   = 35;              // front wall lowered to this height for access
plate_r     = 6;                // outer corner radius

// part selector: "body" | "base" | "assembly"
part = "assembly";

// --- floor-mount base split ---
// The caddy splits into a BASE (a vented ring that screws to the floor) and the
// BODY. The base has alignment posts; the body drops over them and is screwed
// down into the posts. Both meet at 4 external corner ears:
//   base ear  : floor-mount screw (down into floor) + alignment post (up)
//   body ear  : socket over the post + screw down into the post's pilot
base_h   = foot_height;         // base ring height (the standoff)
ear      = 20;                  // ear length, sticking outward in X
ear_w    = 30;                  // ear width (Y)
ear_t    = 9;                   // body-ear thickness (Z)
post_d   = 7;                   // base alignment post OD
post_up  = 5;                   // post protrusion into the body ear
m3_clear = 3.4;                 // body->base screw clearance (M3)
m3_pilot = 2.6;                 // self-tap pilot in the post
floor_d  = 4.5;                 // base->floor screw clearance (#8 wood screw)
csk_d    = 8;                   // countersink head diameter

// devices  [width, depth] mm  (measured / datasheet — see README)
xb8_dev  = [117, 117];          // square rounded-base tower, ~218 tall
orbi_dev = [190, 72];           // leaf tower, ~280 tall (rotated 90deg here)

// storage / cable bay (tucked behind the shorter XB8)
storage_d = 70;                 // storage bay depth
cable_slot_w = 60;              // back-wall cable-entry window width
cable_slot_h = 55;              // ... window height
back_rim     = 12;              // solid wall left above the window (rim bar tying the flaps)
cable_slot_cx = 134;            // window center X — tuned to sit between back vent slots
                                // (slot pitch 20mm; 134 leaves ~8mm wall to the flanking
                                // slots so there's no thin sliver, while keeping all slots)
cable_pass_h = 42;              // height of internal divider cable pass-throughs
// Both routers' port faces point INTO the central storage bay:
//   - Orbi port (broad) face -> +X divider, cable drops into the storage bay
//   - XB8 port face -> +Y divider, cable drops into the storage bay
// Storage bay collects both and exits the rear cable notch.

// ----------------------------- derived layout ------------------------------
orbi_ix = orbi_dev[1] + 2*clearance;   // 76  (Orbi rotated: thin edge = X)
orbi_iy = orbi_dev[0] + 2*clearance;   // 194 (broad face runs in depth)
xb8_ix  = xb8_dev[0]  + 2*clearance;   // 121
xb8_iy  = xb8_dev[1]  + 2*clearance;   // 121

W_in = orbi_ix + wall + xb8_ix;        // 200
D_in = max(orbi_iy, xb8_iy + wall + storage_d); // 194
W = W_in + 2*wall;                      // 206 outer
D = D_in + 2*wall;                      // 200 outer
floor_top = foot_height + floor_th;
top = floor_top + outer_h;

// four corner mount ears: [cornerX, cornerY, outward-X sign]
ears = [[0, 34, -1], [0, D-34, -1], [W, 34, 1], [W, D-34, 1]];
function earcx(c) = c[0] + c[2]*8;            // ear tab center X
function eph(c)   = [c[0] + c[2]*11, c[1]-8]; // alignment post / body screw XY
function efh(c)   = [c[0] + c[2]*11, c[1]+8]; // floor-mount screw XY

// bay rectangles in local (corner) coords [x0,y0,x1,y1]
orbi_bay = [wall,            wall, wall+orbi_ix,        wall+orbi_iy];
colB_x0  = wall + orbi_ix + wall;
xb8_bay  = [colB_x0,         wall, colB_x0+xb8_ix,      wall+xb8_iy];
stor_y0  = wall + xb8_iy + wall;
stor_bay = [colB_x0,     stor_y0, colB_x0+xb8_ix,       stor_y0+storage_d];

// ----------------------------- helpers -------------------------------------
module rrect(w, d, r) hull() for (sx=[-1,1], sy=[-1,1])
    translate([sx*(w/2-r), sy*(d/2-r)]) circle(r=r, $fn=48);
module rbox(w, d, h, r) linear_extrude(h) rrect(w, d, r);

// open-top pocket cutter for a bay rect (cuts from floor through the top)
module pocket(b) {
    translate([b[0], b[1], floor_top-0.01])
        cube([b[2]-b[0], b[3]-b[1], outer_h+1]);
}

// hex-staggered round vent holes filling a bay rect (cutter at floor)
module vent_rect(b) {
    r = 4; pitch = 12;
    w = b[2]-b[0]; d = b[3]-b[1];
    cols = ceil(w/pitch); rows = ceil(d/pitch);
    for (i=[0:cols], j=[0:rows]) {
        x = b[0] + 2 + i*pitch + ((j%2==1)? pitch/2 : 0);
        y = b[1] + 2 + j*pitch;
        if (x <= b[2]-2 && y <= b[3]-2)
            translate([x, y, foot_height-0.02]) cylinder(r=r, h=floor_th+0.04, $fn=20);
    }
}

// six raised feet under the plate, z:[0,foot_height]
module feet() {
    fs = 18; ins = 8;
    xs = [ins+fs/2, W/2, W-ins-fs/2];
    ys = [ins+fs/2, D-ins-fs/2];
    for (x = xs, y = ys) translate([x, y, 0]) rbox(fs, fs, foot_height, 4);
}

// 2D honeycomb field: hexagonal holes (circumradius rh) on a hex grid of cell
// circumradius Rc, filling a uw x vh area centered on the origin.
module honey2d(uw, vh, Rc, rh) {
    hp = sqrt(3)*Rc; vp = 1.5*Rc;
    nu = ceil(uw/(2*hp)) + 1; nv = ceil(vh/(2*vp)) + 1;
    for (j = [-nv:nv], i = [-nu:nu]) {
        x = i*hp + ((((j%2)+2)%2) == 1 ? hp/2 : 0);
        y = j*vp;
        if (abs(x) <= uw/2 - rh && abs(y) <= vh/2 - rh)
            translate([x, y]) rotate(30) circle(r=rh, $fn=6);
    }
}

// honeycomb vents over one outer wall side: side = "back"|"left"|"right".
// The 2D field is mapped onto each wall (its vertical axis -> Z). On the back
// wall the field skips the cable-window footprint so the window keeps a border.
module wall_honey(side) {
    Rc = 13; rh = 10; t = wall*3;                       // cell + hole circumradius
    z0 = floor_top + 8; z1 = top - 8; V = z1 - z0; zc = (z0 + z1)/2;
    if (side == "back") {
        wkc_z = top - (cable_slot_h + back_rim)/2;      // cable-window center (Z)
        translate([W/2, D, zc]) rotate([90,0,0]) linear_extrude(t, center=true)
            difference() {
                honey2d(W - 26, V, Rc, rh);
                translate([cable_slot_cx - W/2, wkc_z - zc])
                    square([cable_slot_w + 2*rh + 8,
                            (cable_slot_h - back_rim) + 2*rh + 8], center=true);
            }
    } else {
        translate([(side=="left") ? 0 : W, D/2, zc]) rotate([0,90,0])
            linear_extrude(t, center=true) honey2d(V, D - 26, Rc, rh);
    }
}

// ----------------------------- the caddy -----------------------------------
module caddy() {
    translate([-W/2, -D/2, 0]) difference() {
        union() {
            translate([W/2, D/2, foot_height]) rbox(W, D, floor_th, plate_r);  // floor
            translate([W/2, D/2, floor_top])   rbox(W, D, outer_h, plate_r);   // shell
            // mount ears at the four corners (bottom)
            for (c = ears) translate([earcx(c), c[1], foot_height]) rbox(24, ear_w, ear_t, 4);
        }
        // ear holes: CONICAL post socket (self-centering, prints with no support
        // since the cone walls slope) + screw clearance + countersink (top)
        for (c = ears) {
            p = eph(c);
            translate([p[0], p[1], foot_height-0.01]) cylinder(d1=post_d+2.4, d2=post_d-2.6, h=post_up+0.5);
            translate([p[0], p[1], foot_height-0.01]) cylinder(d=m3_clear, h=ear_t+0.02);
            translate([p[0], p[1], foot_height+ear_t-2.6]) cylinder(d1=m3_clear, d2=csk_d, h=2.7);
        }
        // hollow the three bays (open tops)
        pocket(orbi_bay); pocket(xb8_bay); pocket(stor_bay);
        // perforate each bay floor
        vent_rect(orbi_bay); vent_rect(xb8_bay); vent_rect(stor_bay);
        // lower the front (y=0) wall across the two router bays for access
        translate([16, -1, floor_top+front_lip])
            cube([W-32, wall+2, outer_h]);
        // cable-entry window in the back wall behind the storage bay. Closed at
        // the top by a `back_rim` band, and split by a center mullion so the rim
        // is supported by a short bridge (no wide unsupported span).
        for (s = [-1, 1]) {
            mw = cable_slot_w/2 - 3;
            translate([cable_slot_cx + s*(cable_slot_w/4 + 1.5) - mw/2, D-wall*1.5,
                       top - cable_slot_h])
                cube([mw, wall*3, cable_slot_h - back_rim]);
        }
        // ventilate the internal divider walls with honeycomb (full area); the
        // bottom cells also let cables pass between bays into the storage bay.
        // +X divider (Orbi | XB8/storage), full depth:
        translate([orbi_bay[2] + wall/2, D/2, (floor_top + 6 + top - 8)/2])
            rotate([0,90,0]) linear_extrude(wall*3, center=true)
                honey2d(top - 8 - (floor_top + 6), D - 2*wall - 10, 13, 10);
        // +Y divider (XB8 | storage):
        translate([(colB_x0 + W - wall)/2, xb8_bay[3] + wall/2, (floor_top + 6 + top - 8)/2])
            rotate([90,0,0]) linear_extrude(wall*3, center=true)
                honey2d((W - wall) - colB_x0 - 10, top - 8 - (floor_top + 6), 13, 10);
        // honeycomb vents in back / left / right walls
        wall_honey("back"); wall_honey("left"); wall_honey("right");
    }
}

// ----------------------------- the base ------------------------------------
// vertical slot vents for the base ring sides (z 0..base_h); short ring -> tiny
// bridges, prints clean. side = "back"|"front"|"left"|"right".
module base_vents(side) {
    sw = 6; gap = 11; z0 = 4; hh = base_h - 8; t = wall*3;
    span = (side=="back" || side=="front") ? W - 44 : D - 44;
    n = max(1, floor(span/(sw+gap)));
    for (i = [0:n-1]) {
        q = -span/2 + span/(2*n) + i*span/n;
        if (side=="back" || side=="front")
            translate([W/2+q, (side=="back")?D:0, z0+hh/2]) cube([sw, t, hh], center=true);
        else
            translate([(side=="left")?0:W, D/2+q, z0+hh/2]) cube([t, sw, hh], center=true);
    }
}

// Floor-mount base: a vented ring + 4 corner ears. Screw the ears to the floor;
// the body drops over the alignment posts and screws down into them.
module make_base() {
    translate([-W/2, -D/2, 0]) difference() {
        union() {
            // perimeter ring (open top + bottom)
            difference() {
                translate([W/2, D/2, 0])     rbox(W, D, base_h, plate_r);
                translate([W/2, D/2, -0.01]) rbox(W-2*wall, D-2*wall, base_h+0.02, max(plate_r-wall,1.5));
            }
            // full-height corner ears (legs) + alignment posts on top
            for (c = ears) {
                translate([earcx(c), c[1], 0]) rbox(24, ear_w, base_h, 4);
                p = eph(c);
                translate([p[0], p[1], base_h-0.01]) cylinder(d1=post_d+2, d2=post_d-3, h=post_up);
            }
        }
        base_vents("back"); base_vents("front"); base_vents("left"); base_vents("right");
        // ear cuts: post pilot (self-tap) + countersunk floor-mount hole
        for (c = ears) {
            p = eph(c); f = efh(c);
            translate([p[0], p[1], -0.01]) cylinder(d=m3_pilot, h=base_h+post_up+0.02);
            translate([f[0], f[1], -0.01]) cylinder(d=floor_d, h=base_h+0.02);
            translate([f[0], f[1], base_h-2.7]) cylinder(d1=floor_d, d2=csk_d, h=2.71);
        }
    }
}

// ----------------------------- dispatch ------------------------------------
if      (part == "body") translate([0,0,-foot_height]) caddy();  // drop to bed
else if (part == "base") make_base();
else { caddy(); make_base(); }                                   // assembly view
