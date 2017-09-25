// Units in mm

$fn = 64;

board_width = 285.0;
board_height = 94.6;

board_lip = 0;
pcb_thickness = 1.6;
slop = 1;

standoff_height = 1.5;  // 1/4" standoff

standoff_radius = 2 + 1.5; // 4mm drill-in, with 1mm border
inset_radius = 2.05;

height_over_standoff = 11;

case_width = 6;

hole_locations = [
    [25.2, 66.7],
    [260.05, 66.7],
    [128.2, 47.6],
    [190.5, 9.4],
    [3, 38.1],
    [board_width - 3, 38.1]
];

stock_height = case_width + standoff_height + height_over_standoff;

module case(x, y, z, wasted_stock) {
    translate([x, y, z]) {
        union() {
            cube(size=[(board_width + (2 * slop) + (2 * case_width)),
                       (board_height + (2 * slop) + (2 * case_width)),
                       wasted_stock]);

            translate([0, 0, wasted_stock]) {
              difference() {
                  cube(size=[(board_width + (2 * slop) + (2 * case_width)),
                             (board_height + (2 * slop) + (2 * case_width)),
                             standoff_height + case_width + height_over_standoff]);
                  union() {
                      translate([case_width + board_lip + slop,
                                 case_width + board_lip + slop,
                                 case_width]) {
                          cube(size=[board_width - (2 * board_lip),
                                     board_height - (2 * board_lip),
                                     standoff_height + case_width + height_over_standoff]);
                      }
                      translate([case_width,
                                 case_width,
                                 case_width + standoff_height]) {
                          cube(size=[board_width + (2*slop),
                                     board_height + (2*slop),
                                     standoff_height + case_width + height_over_standoff]);
                      }
                  }
              }
              translate([case_width + slop, case_width + slop, 0]) {
                  for (i = [0 : 1 : len(hole_locations) - 1]) {
                      translate(hole_locations[i])
                      cylinder(h=standoff_height + case_width, r=standoff_radius);
                  }
                  // translate([25.2, 66.7, 0])
                  // cylinder(h=standoff_height + case_width, r=standoff_radius);
                  // translate([260.05, 66.7, 0])
                  // cylinder(h=standoff_height + case_width, r=standoff_radius);
                  // translate([128.2, 47.6, 0])
                  // cylinder(h=standoff_height + case_width, r=standoff_radius);
                  // translate([190.5, 9.4, 0])
                  // cylinder(h=standoff_height + case_width, r=standoff_radius);
                  // union() {
                  //     translate([standoff_radius, 38.1, 0])
                  //     cylinder(h=standoff_height + case_width, r=standoff_radius);
                  //     translate([0, 38.1 - standoff_radius, 0])
                  //     cube(size=[standoff_radius, standoff_radius * 2, standoff_height + case_width]);
                  // }
                  // union() {
                  //     translate([board_width - standoff_radius, 38.1, 0])
                  //     cylinder(h=standoff_height + case_width, r=standoff_radius);
                  //     translate([board_width - standoff_radius, 38.1 - standoff_radius, 0])
                  //     cube(size=[standoff_radius, standoff_radius * 2, standoff_height + case_width]);
                  // }
              }
          }
      }
   }
}

module holes(x, y) {
  translate([case_width + slop, case_width + slop]) {
    for (i = [0 : 1 : len(hole_locations) - 1]) {
      translate(hole_locations[i])
      circle(r=inset_radius);
    }
  }
}

module centered_box(x, y, w, h) {
  translate([x, y]) {
    translate([x - (w/2), y - (h/2)]) {
      square([w, h]);
    }
  }
}

module usb() {
  translate([case_width + slop + 19.05,
             height_over_standoff + 2.05]) { // half the heigth of usb mini
    difference() {
      centered_box(0, 0, 12, 8.5);
      centered_box(0, 0, 10.5, 6);
    }
  }
}

module rcube(x, y, z, r) {
    hull() {
        translate([r, r, 0]) cylinder(r1=r, r2=r,  h=z);
        translate([x-r, r, 0]) cylinder(r1=r, r2=r, h=z);
        translate([r, y-r, 0]) cylinder(r1=r, r2=r, h=z);
        translate([x-r, y-r, 0]) cylinder(r1=r, r2=r, h=z);
    }
}

module standoff() {
  stock_height=25.4;

  piece_width = 30;

  bottom_trim = stock_height - (case_width + standoff_height + height_over_standoff);
  outer_height = (case_width * 2) + (slop * 2) + board_height;

  echo("bottom_trim: " , bottom_trim);
  echo("outer_height: ", outer_height);
  echo("rotate_angle: ", rotate_angle);

  rotate_angle = atan(bottom_trim / outer_height);

  rotate(a=[-rotate_angle, 0, 0]) {
    rotate(a=[rotate_angle, 0, 0]) {
      translate([case_width + slop, case_width + slop, 0]) {
        difference() {
          rcube(piece_width, board_height, standoff_height + height_over_standoff, 6.35);
          union() {
            for (i = [0 : 1 : len(hole_locations) - 1]) {
              translate([hole_locations[i][0], board_height - hole_locations[i][1], height_over_standoff - (standoff_height + 1)])
              cylinder(h=standoff_height + case_width, r=standoff_radius * 2);
            }
            for (i = [0 : 1 : len(hole_locations) - 1]) {
              translate([board_width - hole_locations[i][0], board_height - hole_locations[i][1], height_over_standoff - (standoff_height + 1)])
              cylinder(h=standoff_height + case_width, r=standoff_radius * 2);
            }
          }
        }
      }
    }

    inset = 4;

    translate([case_width + slop + inset, case_width + slop + inset, -2]) {
        cube(size=[piece_width - (2 * inset), board_height - (2 * inset), height_over_standoff + 2]);
    }
  }
}

module bottom() {
  overcut = 6.35;

  translate([-overcut, -overcut]) {
    square([(case_width * 2) + (slop * 2) + board_width + overcut,
            (case_width * 2) + (slop * 2) + board_height + overcut]);
  }
}

module feet() {
  // Got little circular 12mm dots
  dot_radius = 6.5;

  overall_width = (2 * case_width) + (2 * slop) + board_width;
  overall_height = (2 * case_width) + (2 * slop) + board_height;
  ofs = dot_radius * 2;

  translate([ofs, ofs]) circle(r=dot_radius);
  translate([ofs, overall_height - ofs]) circle(r=dot_radius);
  translate([overall_width - ofs, ofs]) circle(r=dot_radius);
  translate([overall_width - ofs, overall_height - ofs]) circle(r=dot_radius);
}


mod = "case";

if (mod == "case") {
  wasted_stock = stock_height - (case_width + standoff_height + height_over_standoff);
  echo("stock_height: ", stock_height);
  echo("wasted_stock: ", wasted_stock);
  case(0, 0, 0, wasted_stock);
}

if (mod == "holes") {
  holes(0, 0);
}

if (mod == "usb") {
  usb();
}

if (mod == "standoff") {
  standoff();
}

if (mod == "bottom") {
  bottom();
}

if (mod == "feet") {
  feet();
}