# Stage 1: Build Percolator
FROM alpine:latest AS builder

RUN apk add --no-cache cmake build-base boost-dev boost-static gtest-dev

WORKDIR /app

# download specific tag tarball
RUN wget -qO- https://github.com/percolator/percolator/archive/refs/tags/rel-3-06-05.tar.gz \
    | tar xz && mv percolator-rel-3-06-05 percolator

WORKDIR /app/percolator

# build
RUN cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DGOOGLE_TEST=OFF . && cmake --build .

# Stage 2: Minimal Runtime Image
FROM alpine:latest

# runtime deps + zip
RUN apk add --no-cache boost-libs libgomp zip unzip

WORKDIR /app/percolator

# copy percolator binary
COPY --from=builder /app/percolator/src/percolator /app/percolator/

# copy your entrypoint wrapper
COPY entrypoint.sh /usr/local/bin/percolator-entrypoint
RUN chmod +x /usr/local/bin/percolator-entrypoint

# use the wrapper
ENTRYPOINT ["/usr/local/bin/percolator-entrypoint"]
