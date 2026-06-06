# Router floor caddy — build / render recipes
# OpenSCAD 2021.01 on PATH. Override the binary with OPENSCAD=/path/to/AppImage.

openscad := env_var_or_default("OPENSCAD", "openscad")
# Headless host (no X display): xvfb-run gives OpenSCAD a GL context for PNGs.
render   := env_var_or_default("RENDER", "xvfb-run -a " + openscad)
src      := "src/caddy.scad"
fn       := "64"

default:
    @just --list

# Export the two printable parts: body (the caddy) and the floor-mount base.
build:
    {{openscad}} -D '$fn={{fn}}' -D 'part="body"' -o export/caddy-body.stl {{src}}
    {{openscad}} -D '$fn={{fn}}' -D 'part="base"' -o export/caddy-base.stl {{src}}

build-all: build

# Re-render the committed preview PNGs (STL export needs no GL; PNGs do).
hero := "--imgsize=1600,1200 --colorscheme=Tomorrow --projection=perspective --render"
view := "--imgsize=1600,1200 --colorscheme=Tomorrow --projection=perspective --viewall --render"
preview:
    {{render}} {{hero}} -D 'part="assembly"' --camera=0,0,75,62,0,28,640 -o images/caddy-hero.png {{src}}
    {{render}} {{view}} -D 'part="assembly"' --camera=0,0,600,0,0,0 -o images/caddy-top.png {{src}}
    {{render}} {{view}} -D 'part="base"' --camera=0,0,0,58,0,28,1 -o images/caddy-base.png {{src}}

# Remove generated meshes (PNGs are committed).
clean:
    rm -f export/*.stl
