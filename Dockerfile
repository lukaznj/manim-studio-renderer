# Manim Studio's render server: renders exports sent by the app, so the computer you work on stays free.
# It builds the worker from a tagged release of Manim Studio, so it renders exactly like that version of
# the app. Keep STUDIO_REF at the version of Manim Studio you use.
FROM debian:bookworm-slim

ARG STUDIO_REF=v0.5.0
ARG PIXI_VERSION=v0.81.0

# TeX Live for MathTex (what the app installs as TinyTeX), fonts for Text, git and curl for the build.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git \
      texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended \
      texlive-science texlive-lang-european cm-super dvisvgm \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pixi.sh/install.sh | PIXI_VERSION=${PIXI_VERSION} PIXI_HOME=/usr/local bash

# The Python side of Manim Studio (manim, the studio package, the runner and the worker), with the
# same locked environment the app installs.
RUN git clone --depth 1 --branch "${STUDIO_REF}" https://github.com/lukaznj/manim-studio /src \
 && mv /src/python /app && rm -rf /src
WORKDIR /app
RUN pixi install --frozen -e default && rm -rf /root/.cache/rattler

ENV STUDIO_VERSION=${STUDIO_REF} \
    STUDIO_WORKER_DATA=/data \
    STUDIO_WORKER_PORT=7400 \
    PYTHONUNBUFFERED=1
VOLUME /data
EXPOSE 7400
CMD ["pixi", "run", "--frozen", "-e", "default", "python", "-m", "studio_worker"]
