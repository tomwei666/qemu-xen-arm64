FROM centos:7.2.1511
LABEL maintainer.name="The Xen Project" \
      maintainer.email="xen-devel@lists.xenproject.org"

# ensure we only get bits from the vault for
# the version we want
COPY CentOS-7.2.repo /etc/yum.repos.d/CentOS-Base.repo

# install EPEL for dev86, xz-devel and possibly other packages
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
        yum clean all

RUN mkdir /build
WORKDIR /build

# work around https://github.com/moby/moby/issues/10180
# and install Xen depends
RUN rpm --rebuilddb && \
    yum -y install \
        yum-plugin-ovl \
        gcc \
        gcc-c++ \
        ncurses-devel \
        zlib-devel \
        openssl-devel \
        python-devel \
        libuuid-devel \
        pkgconfig \
        gettext \
        flex \
        bison \
        libaio-devel \
        glib2-devel \
        yajl-devel \
        pixman-devel \
        glibc-devel \
        glibc-devel.i686 \
        make \
        binutils \
        git \
        wget \
        acpica-tools \
        python-markdown \
        patch \
        checkpolicy \
        dev86 \
        xz-devel \
        bzip2 \
        nasm \
    && yum clean all
