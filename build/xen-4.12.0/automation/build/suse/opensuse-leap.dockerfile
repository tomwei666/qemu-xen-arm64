FROM opensuse/leap
LABEL maintainer.name="The Xen Project" \
      maintainer.email="xen-devel@lists.xenproject.org"

ENV USER root

RUN mkdir /build
WORKDIR /build

RUN zypper ref && zypper up -y
RUN zypper install -y \
        acpica \
        bc \
        bin86 \
        bison \
        bzip2 \
        checkpolicy \
        clang \
        cmake \
        dev86 \
        discount \
        flex \
        gcc \
        gettext-tools \
        git \
        glib2-devel \
        glibc-devel \
        glibc-devel-32bit \
        gzip \
        hostname \
        libSDL2-devel \
        libaio-devel \
        libbz2-devel \
        libext2fs-devel \
        libgnutls-devel \
        libjpeg62-devel \
        libnl3-devel \
        libnuma-devel \
        libpixman-1-0-devel \
        libpng16-devel \
        libssh2-devel \
        libtasn1-devel \
        libuuid-devel \
        libyajl-devel \
        lzo-devel \
        make \
        nasm \
        ncurses-devel \
        ocaml \
        ocaml-findlib-devel \
        ocaml-ocamlbuild \
        ocaml-ocamldoc \
        pandoc \
        patch \
        pkg-config \
        python \
        python-devel \
        systemd-devel \
        tar \
        transfig \
        valgrind-devel \
        wget \
        which \
        xz-devel \
        zlib-devel \
        && \
        zypper clean
