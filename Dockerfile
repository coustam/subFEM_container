# Multi-stage Dockerfile for KiCad, OpenEMS, gerber2ems
FROM debian:bookworm AS kicad-build
ARG KICAD_VERSION=9.0
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential cmake git ninja-build \
    libbz2-dev libcairo2-dev libglu1-mesa-dev libgl1-mesa-dev libglew-dev \
    libx11-dev libwxgtk3.2-dev mesa-common-dev pkg-config python3-dev \
    python3-wxgtk4.0 libboost-all-dev libglm-dev libcurl4-openssl-dev \
    libgtk-3-dev libngspice0-dev ngspice-dev \
    libocct-modeling-algorithms-dev libocct-modeling-data-dev \
    libocct-data-exchange-dev libocct-visualization-dev \
    libocct-foundation-dev libocct-ocaf-dev unixodbc-dev zlib1g-dev \
    shared-mime-info gettext libgit2-dev libsecret-1-dev \
    libnng-dev libprotobuf-dev protobuf-compiler swig4.0 python3-pip python3-venv

WORKDIR /src
RUN git clone -b $KICAD_VERSION https://gitlab.com/kicad/code/kicad.git && \
    git clone -b $KICAD_VERSION https://gitlab.com/kicad/libraries/kicad-symbols.git && \
    git clone -b $KICAD_VERSION https://gitlab.com/kicad/libraries/kicad-footprints.git && \
    git clone -b $KICAD_VERSION https://gitlab.com/kicad/libraries/kicad-templates.git

WORKDIR /src/kicad
RUN mkdir -p build && cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DKICAD_SCRIPTING_WXPYTHON=ON -DKICAD_USE_OCC=ON -DKICAD_SPICE=ON \
    -DKICAD_BUILD_I18N=ON -DCMAKE_INSTALL_PREFIX=/usr \
    -DKICAD_USE_CMAKE_FINDPROTOBUF=ON .. && \
    ninja && cmake --install . --prefix=/usr/installtemp

RUN for lib in kicad-symbols kicad-footprints kicad-templates; do \
    cd /src/$lib && \
    cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/usr . && ninja && \
    cmake --install . --prefix=/usr/installtemp; \
    done

FROM ubuntu:22.04 AS final
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libglu1-mesa libglew2.2 libx11-6 libwxgtk3.2* python3 python3-pip \
    libngspice0 ngspice libocct-modeling-algorithms libocct-modeling-data \
    libocct-data-exchange libocct-visualization libocct-foundation libocct-ocaf \
    zlib1g shared-mime-info libgit2-1.5 libsecret-1-0 libprotobuf32 libzstd1 libnng1 \
    build-essential cmake libhdf5-dev libvtk7-dev libboost-all-dev libcgal-dev \
    libtinyxml-dev qtbase5-dev libvtk7-qt-dev python3-dev pkg-config \
    octave liboctave-dev gengetopt help2man groff pod2pdf bison flex libhpdf-dev \
    libtool git wget curl libx11-dev x11-apps python3-tk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=kicad-build /usr/installtemp /usr/

RUN pip install --upgrade pip && \
    pip install numpy matplotlib cython h5py setuptools==58.2.0 wheel pyproject-toml

RUN git clone https://github.com/antmicro/gerber2ems.git /opt/gerber2ems && \
    pip install -r /opt/gerber2ems/requirements.txt && \
    pip install /opt/gerber2ems

WORKDIR /opt
RUN git clone --recursive https://github.com/thliebig/openEMS-Project.git
WORKDIR /opt/openEMS-Project
RUN ./update_openEMS.sh /usr/local/openEMS --with-hyp2mat --with-CTB --python

ENV PATH="/usr/local/openEMS/bin:$PATH"
ENV PYTHONPATH="/usr/local/openEMS/lib:$PYTHONPATH"

WORKDIR /workspace
CMD ["/bin/bash"]
