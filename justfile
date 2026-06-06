# Router floor caddy — build / render recipes
# OpenSCAD 2021.01 on PATH. Override the binary with OPENSCAD=/path/to/AppImage.

openscad := env_var_or_default("OPENSCAD", "openscad")
# Headless host (no X display): xvfb-run gives OpenSCAD a GL context for PNGs.
render   := env_var_or_default("RENDER", "xvfb-run -a " + openscad)
src      := "src/caddy.scad"

default:
    @just --list

# Export the single-piece caddy STL.
build:
    {{openscad}} -o export/caddy.stl {{src}}

build-all: build

# Re-render the committed preview PNGs (STL export needs no GL; PNGs do).
view := "--imgsize=1600,1200 --colorscheme=Tomorrow --projection=perspective --viewall"
preview:
    {{render}} -o images/caddy-hero.png {{view}} --camera=0,-420,320,0,0,0 {{src}}
    {{render}} -o images/caddy-top.png  {{view}} --camera=0,0,600,0,0,0     {{src}} --render

# Remove generated meshes (PNGs are committed).
clean:
    rm -f export/*.stl
