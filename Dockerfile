FROM eclipse-temurin:17-jdk-jammy

ARG DAML_SDK_VERSION=3.5.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl make \
    && rm -rf /var/lib/apt/lists/*

ENV DPM_HOME=/root/.dpm
ENV PATH="${DPM_HOME}/bin:${PATH}"

WORKDIR /workspace
RUN curl -fsSL https://get.digitalasset.com/install/install.sh \
    | sh -s "${DAML_SDK_VERSION}"

EXPOSE 6865 6866 6867 6868 6869 7575
