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
foot_height = 12;               // raised-foot height -> under-caddy air gap
outer_h     = 140;              // shell wall height (grips lower half of towers)
front_lip   = 35;              // front wall lowered to this height for access
plate_r     = 6;                // outer corner radius

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

// one diamond-shaped hole cutter through a wall whose normal is +Y (back wall)
module dia_Y(xc, zc, s, t)
    translate([xc, D, zc]) rotate([90,0,0]) linear_extrude(t, center=true)
        rotate(45) square(s, center=true);
// ... whose normal is +X (left/right walls)
module dia_X(xc, yc, zc, s, t)
    translate([xc, yc, zc]) rotate([0,90,0]) linear_extrude(t, center=true)
        rotate(45) square(s, center=true);

// diamond-lattice vents over one outer wall side: side = "back"|"left"|"right"
// (diamonds self-support at 45deg, so no bridging worries). On the back wall the
// lattice skips the cable-window footprint so the window keeps a clean border.
module wall_diamonds(side) {
    d = 22; strut = 3; p = d + strut; t = wall*3; s = d/sqrt(2);
    z0 = floor_top + 8; z1 = top - 8; vh = z1 - z0; zc = (z0 + z1) / 2;
    // back-wall cable-window keepout (expanded by half a diamond + 4mm)
    wx0 = cable_slot_cx - cable_slot_w/2 - d/2 - 4;
    wx1 = cable_slot_cx + cable_slot_w/2 + d/2 + 4;
    wz0 = (top - cable_slot_h) - d/2 - 4;
    wz1 = (top - back_rim)     + d/2 + 4;
    uw = (side == "back") ? W - 26 : D - 26;
    nu = floor(uw/(2*p)); nv = floor(vh/(2*p));
    for (i = [-nu:nu], j = [-nv:nv]) {
        u = i*p; v = j*p;
        if (abs(u) <= uw/2 - d/2 && abs(v) <= vh/2 - d/2) {
            if (side == "back") {
                x = W/2 + u; zz = zc + v;
                if (!(x > wx0 && x < wx1 && zz > wz0 && zz < wz1)) dia_Y(x, zz, s, t);
            } else
                dia_X((side=="left") ? 0 : W, D/2 + u, zc + v, s, t);
        }
    }
}

// ----------------------------- the caddy -----------------------------------
module caddy() {
    translate([-W/2, -D/2, 0]) difference() {
        union() {
            feet();
            translate([W/2, D/2, foot_height]) rbox(W, D, floor_th, plate_r);  // floor
            translate([W/2, D/2, floor_top])   rbox(W, D, outer_h, plate_r);   // shell
        }
        // hollow the three bays (open tops)
        pocket(orbi_bay); pocket(xb8_bay); pocket(stor_bay);
        // perforate each bay floor
        vent_rect(orbi_bay); vent_rect(xb8_bay); vent_rect(stor_bay);
        // lower the front (y=0) wall across the two router bays for access
        translate([16, -1, floor_top+front_lip])
            cube([W-32, wall+2, outer_h]);
        // cable-entry window in the back wall behind the storage bay.
        // Closed at the top: a `back_rim` band of wall stays, tying the two
        // flanking wall sections together instead of leaving free-top flaps.
        translate([cable_slot_cx - cable_slot_w/2, D-wall*1.5,
                   top - cable_slot_h])
            cube([cable_slot_w, wall*3, cable_slot_h - back_rim]);
        // low cable pass-through: Orbi bay -> storage bay (through the +X divider)
        translate([orbi_bay[2]-1, stor_bay[1]+8, floor_top-0.01])
            cube([wall+2, storage_d-16, cable_pass_h]);
        // low cable pass-through: XB8 bay -> storage bay (through the +Y divider)
        translate([colB_x0+28, xb8_bay[3]-1, floor_top-0.01])
            cube([xb8_ix-56, wall+2, cable_pass_h]);
        // lattice vents in the +X divider over the XB8-adjacent front portion
        for (yy = [26 : 25 : xb8_bay[3]-14], zz = [floor_top+28 : 25 : top-22])
            dia_X(orbi_bay[2] + wall/2, yy, zz, 22/sqrt(2), wall*3);
        // diamond-lattice vents in back / left / right walls
        wall_diamonds("back"); wall_diamonds("left"); wall_diamonds("right");
    }
}

caddy();
