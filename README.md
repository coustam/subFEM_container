# KiCad + OpenEMS + gerber2ems Docker Suite

This repository builds a unified Docker environment containing:
- KiCad 9.0
- OpenEMS (with Python + Octave)
- gerber2ems tool

## Usage
0. abcs
```bash
git clone https://github.com/coustam/subFEM_container.git
```
1. Allow Docker to connect to your X11 display:

```bash
xhost +local:docker
```

2. Build the container:

```bash
docker compose build
```

3. Run it:

```bash
docker compose up
```

You can access the CLI inside:

```bash
docker exec -it kicad_openems bash
```

And launch `kicad`, `octave`, etc.

## Mount your designs into `./src`
All files inside `./src` are shared into `/workspace` inside the container.
