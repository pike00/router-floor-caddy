# Router floor caddy — build / render recipes
# OpenSCAD 2021.01 on PATH. Override the binary with OPENSCAD=/path/to/AppImage.

openscad := env_var_or_default("OPENSCAD", "openscad")
# Headless host (no X display): xvfb-run gives OpenSCAD a GL context for PNGs.
render   := env_var_or_default("RENDER", "xvfb-run -a " + openscad)
src      := "src/caddy.scad"

default:
    @just --list

# Export each printable tile as its own STL.
build:
    {{openscad}} -D 'part="xb8"'  -o export/xb8-cradle.stl  {{src}}
    {{openscad}} -D 'part="orbi"' -o export/orbi-cradle.stl {{src}}
    {{openscad}} -D 'part="tray"' -o export/storage-tray.stl {{src}}

build-all: build

# Re-render the committed preview PNGs (STL export needs no GL; PNGs do).
view := "--imgsize=1600,1200 --colorscheme=Tomorrow --projection=perspective --viewall"
preview:
    {{render}} -o images/assembly-hero.png {{view}} --camera=0,-520,360,0,0,0 {{src}}
    {{render}} -o images/assembly-top.png  {{view}} --camera=0,0,700,0,0,0     {{src}}
    {{render}} -o images/xb8-cradle.png  {{view}} --render -D 'part="xb8"'  {{src}}
    {{render}} -o images/orbi-cradle.png {{view}} --render -D 'part="orbi"' {{src}}
    {{render}} -o images/storage-tray.png {{view}} --render -D 'part="tray"' {{src}}

# Remove generated meshes (PNGs are committed).
clean:
    rm -f export/*.stl
