FROM debian:testing-20201012-slim
# Install Bazel and Node dependencies along with Git
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
   && apt-get install --no-install-recommends -y \
   ca-certificates \
   curl \
   g++ \
   git \
   gnupg2 \
   python3 \
   python-is-python3 \
   unzip \
   zip \
   && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts


# Install bazel
RUN curl -fSsL -o /tmp/bazel-installer.sh https://github.com/bazelbuild/bazel/releases/download/3.6.0/bazel-3.6.0-installer-linux-x86_64.sh \
   && (echo "74818248b8c643da013f3e76c9fdc81c37dd4aceedcc7c55d2ba52ff6044379c */tmp/bazel-installer.sh" | sha256sum --check - ) \
   && /bin/bash /tmp/bazel-installer.sh --base=/usr/local/bazel \
   && rm /tmp/bazel-installer.sh \
   && echo 'source /usr/local/bazel/bin/bazel-complete.bash' >> ~/.bashrc

# Install ibazel
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
   && echo 'deb https://deb.nodesource.com/node_12.x bullseye main' > /etc/apt/sources.list.d/nodesource.list \
   && apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
   nodejs \
   && rm -rf /var/lib/apt/lists/* \
   && npm install --global @bazel/ibazel

# Install buildifier
RUN mkdir /tmp/buildifier \
   && cd /tmp/buildifier \
   && curl https://github.com/bazelbuild/buildtools/archive/3.5.0.tar.gz -sLo- | tar xzvf - --strip-components=1 \
   && bazel build -c opt //buildifier && bazel shutdown \
   && cp $(bazel info -c opt bazel-bin)/buildifier/linux_amd64_stripped/buildifier /usr/local/bin \
   && bazel clean --expunge

# Install openvpn build deps
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
   && apt-get install --no-install-recommends -y \
   cmake \
   bison \
   flex \
   autoconf \
   build-essential \
   automake \
   libtool \
   && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts
