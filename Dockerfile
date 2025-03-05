# Stage 1: Build Percolator
FROM alpine:latest AS builder

RUN apk add --no-cache cmake git build-base boost-dev boost-static

WORKDIR /app

# Clone the latest version from repository
RUN git clone https://github.com/percolator/percolator.git

WORKDIR /app/percolator

# Configure and build
RUN cmake .
RUN cmake --build .

# Stage 2: Minimal Runtime Image
FROM alpine:latest

# Install only runtime dependencies
RUN apk add --no-cache boost-libs libgomp

WORKDIR /app/percolator

# Copy only the final executable from the build stage
COPY --from=builder /app/percolator/src/percolator /app/percolator/

ENTRYPOINT [ "/app/percolator/percolator" ]
