// Router floor caddy — Xfinity XB8 + Netgear Orbi RBR850
// Modular vented floor stand: three tiles that dovetail together.
//   part = "xb8" | "orbi" | "tray" | "assembly"
// Export one tile per STL via:  openscad -D 'part="xb8"' -o export/xb8.stl src/caddy.scad
// Assembly is preview-only (overlapping bodies; do not print as one).
//
// Coordinates: X = width / assembly direction, Y = depth (front = +Y), Z = up.
// Devices stand upright in slotted cradles that grip only their lower section;
// the towers protrude above the open tops, fully exposed for cooling.

// ----------------------------- parameters ----------------------------------
part = "assembly";              // which body to emit
$fn  = 32;                      // global smoothness (raise for final export)

// fit
clearance  = 2;                 // router-to-wall gap, per side (loose insert)
dt_clear   = 0.4;               // dovetail print fit, per face

// structure
wall        = 3;                // cradle / tray wall thickness
floor_th    = 3;                // perforated floor plate thickness
foot_height = 12;               // raised-foot height -> under-caddy air gap
plate_margin = 14;              // plate overhang on the X (joint) edges
plate_r     = 6;                // plate / wall corner radius

// dovetail (flat, plan-view; slide tiles together along Y to engage)
dt_t = 10;                      // tongue protrusion (X)
dt_a = 12;                      // tongue root width (Y)
dt_b = 20;                      // tongue tip width  (Y) -> flare locks against X pull

// devices  [width, depth] in mm (measured / datasheet — see README)
xb8_dev  = [117, 117];         // square rounded-base tower, ~218 tall
orbi_dev = [190, 72];          // leaf/egg tower, ~280 tall
xb8_wall_h  = 110;             // cradle grip height for the 218mm XB8
orbi_wall_h = 140;             // taller grip for the 280mm Orbi (stability)
front_lip   = 35;              // front wall lowered to this height for access

// tray (cable input + storage)
tray_in     = [194, 150];      // inner bin [width, depth]
tray_h      = 90;              // bin wall height
cable_slot_w = 60;             // back-wall cable-entry notch width
cable_slot_h = 55;             // ... notch depth from the top

// derived
floor_top = foot_height + floor_th;   // z of the floor plate's top face

// ----------------------------- 2D / 3D helpers -----------------------------
module rrect(w, d, r) {                          // rounded rectangle (2D)
    hull() for (sx = [-1,1], sy = [-1,1])
        translate([sx*(w/2-r), sy*(d/2-r)]) circle(r=r, $fn=48);
}
module rbox(w, d, h, r) linear_extrude(h) rrect(w, d, r);   // rounded box

// ----------------------------- shared pieces -------------------------------
module feet(pw, pd) {                            // four corner feet, z:[0,foot_height]
    fs = 18; ins = 6;
    for (sx = [-1,1], sy = [-1,1])
        translate([sx*(pw/2-fs/2-ins), sy*(pd/2-fs/2-ins), 0])
            rbox(fs, fs, foot_height, 4);
}

module floor_plate(pw, pd) rbox(pw, pd, floor_th, plate_r);  // place at z=foot_height

// hex-staggered round holes through the floor plate (cutter; place at z=foot_height)
module vent_floor(w, d) {
    r = 4; pitch = 12;
    cols = ceil(w/2/pitch); rows = ceil(d/2/pitch);
    for (i = [-cols:cols], j = [-rows:rows]) {
        x = i*pitch + ((((j % 2) + 2) % 2 == 1) ? pitch/2 : 0);
        y = j*pitch;
        if (abs(x) <= w/2 - r - 2 && abs(y) <= d/2 - r - 2)
            translate([x, y, -0.02]) cylinder(r=r, h=floor_th+0.04, $fn=20);
    }
}

module cradle_walls(ow, od, h) {                 // hollow tube; place at z=floor_top
    difference() {
        rbox(ow, od, h, plate_r);
        translate([0,0,-0.01]) rbox(ow-2*wall, od-2*wall, h+0.02, max(plate_r-wall, 1.5));
    }
}

// vertical slot vents through the front(+Y) and back(-Y) walls (cutter; at z=floor_top)
module wall_vents(ow, od, h) {
    sw = 6; gap = 12; z0 = 15; z1 = h - 12; hh = z1 - z0;
    n = max(1, floor((ow - 30) / (sw + gap)));
    for (i = [0:n-1]) {
        x = (i - (n-1)/2) * (sw + gap);
        for (sy = [-1,1])
            translate([x, sy*(od/2), z0 + hh/2]) cube([sw, wall*3, hh], center=true);
    }
}

// lower the front (+Y) wall to front_lip, keeping corner posts (cutter; at z=floor_top)
module front_access(ow, od, h) {
    ck = 16;
    translate([0, od/2 - wall/2, (front_lip + h)/2 + 0.01])
        cube([ow - 2*ck, wall*3, h - front_lip + 2], center=true);
}

// flat dovetail key on the +X plate edge (male), z:[0,floor_top]
module dovetail_tongue(pw) {
    linear_extrude(floor_top)
        polygon([[pw/2-1, -dt_a/2], [pw/2-1, dt_a/2],
                 [pw/2+dt_t, dt_b/2], [pw/2+dt_t, -dt_b/2]]);
}
// matching slot on the -X plate edge (female), oversized by dt_clear
module dovetail_groove(pw) {
    translate([0,0,-0.01]) linear_extrude(floor_top+0.02)
        offset(delta=dt_clear)
            polygon([[-pw/2+0.1, -dt_a/2], [-pw/2+0.1, dt_a/2],
                     [-pw/2+dt_t, dt_b/2], [-pw/2+dt_t, -dt_b/2]]);
}

// ----------------------------- tiles ---------------------------------------
// A vented cradle for one upright device.
module make_cradle(dev, wall_h, dmargin, joint_l, joint_r) {
    ow = dev[0] + 2*clearance + 2*wall;
    od = dev[1] + 2*clearance + 2*wall;
    pw = ow + 2*plate_margin;
    pd = od + 2*dmargin;
    difference() {
        union() {
            feet(pw, pd);
            translate([0,0,foot_height]) floor_plate(pw, pd);
            translate([0,0,floor_top])   cradle_walls(ow, od, wall_h);
            if (joint_r) dovetail_tongue(pw);
        }
        translate([0,0,foot_height]) vent_floor(dev[0]+2*clearance, dev[1]+2*clearance);
        translate([0,0,floor_top])   wall_vents(ow, od, wall_h);
        translate([0,0,floor_top])   front_access(ow, od, wall_h);
        if (joint_l) dovetail_groove(pw);
    }
}

// Cable-input + storage bin: open top, back-wall cable notch, one fixed divider.
module make_tray(joint_l=true, joint_r=false) {
    iw = tray_in[0]; id = tray_in[1];
    ow = iw + 2*wall; od = id + 2*wall;
    pw = ow + 2*plate_margin; pd = od + 2*8;
    difference() {
        union() {
            feet(pw, pd);
            translate([0,0,foot_height]) floor_plate(pw, pd);
            translate([0,0,floor_top])   cradle_walls(ow, od, tray_h);
            // fixed divider (embeds 1mm into each side wall)
            translate([0, -id/6, floor_top + tray_h*0.3])
                cube([iw + 2, wall, tray_h*0.6], center=true);
            if (joint_r) dovetail_tongue(pw);
        }
        // cable-entry U-notch in the back (-Y) wall, open at top
        translate([0, -od/2, floor_top + tray_h - cable_slot_h/2 + 0.01])
            cube([cable_slot_w, wall*3, cable_slot_h], center=true);
        translate([0,0,foot_height]) vent_floor(iw, id);
        if (joint_l) dovetail_groove(pw);
    }
}

// Preview-only: the three tiles abutted (bodies overlap at the joints).
module make_assembly() {
    orbi_pw = orbi_dev[0] + 2*clearance + 2*wall + 2*plate_margin;   // 228
    xb8_pw  = xb8_dev[0]  + 2*clearance + 2*wall + 2*plate_margin;   // 155
    tray_pw = tray_in[0]  + 2*wall + 2*plate_margin;                 // 228
    gap = 2;
    color("SteelBlue")
        translate([-(xb8_pw/2 + gap + orbi_pw/2), 0, 0])
            make_cradle(orbi_dev, orbi_wall_h, 34, false, true);
    color("IndianRed")
        make_cradle(xb8_dev, xb8_wall_h, 8, true, true);
    color("DarkSeaGreen")
        translate([(xb8_pw/2 + gap + tray_pw/2), 0, 0])
            make_tray(true, false);
}

// ----------------------------- dispatch ------------------------------------
if      (part == "xb8")  make_cradle(xb8_dev,  xb8_wall_h,  8,  true,  true);
else if (part == "orbi") make_cradle(orbi_dev, orbi_wall_h, 34, false, true);
else if (part == "tray") make_tray(true, false);
else                     make_assembly();
