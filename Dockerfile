ARG product_version=6.1.0
ARG build_number=83

FROM onlyoffice/documentserver:${product_version}.${build_number}
ARG product_version
ARG build_number


RUN sed -si \
  's/isSupportEditFeature:function(){return!1}/isSupportEditFeature:function(){return true}/g' \
  /var/www/onlyoffice/documentserver/web-apps/apps/documenteditor/mobile/app.js \
  /var/www/onlyoffice/documentserver/web-apps/apps/presentationeditor/mobile/app.js \
  /var/www/onlyoffice/documentserver/web-apps/apps/spreadsheeteditor/mobile/app.js


ARG build_deps="git make g++ nodejs npm"
RUN apt-get update && apt-get install -y ${build_deps}


ARG tag=v${product_version}.${build_number}
RUN  mkdir /build \
  && git clone --quiet --branch $tag --depth 1 https://github.com/ONLYOFFICE/build_tools.git /build/build_tools \
  && git clone --quiet --branch $tag --depth 1 https://github.com/ONLYOFFICE/server.git      /build/server

COPY license.patch /build/

WORKDIR /build/server

ENV PRODUCT_VERSION=${product_version}
ENV BUILD_NUMBER=${build_number}

RUN  npm install -g pkg grunt grunt-cli \
  && git apply /build/license.patch \
  && make \
  && pkg /build/build_tools/out/linux_64/onlyoffice/documentserver/server/FileConverter --targets=node10-linux -o /build/converter \
  && pkg /build/build_tools/out/linux_64/onlyoffice/documentserver/server/DocService --targets=node10-linux --options max_old_space_size=4096 -o /build/docservice \
  && cp /build/converter /var/www/onlyoffice/documentserver/server/FileConverter/converter \
  && cp /build/docservice /var/www/onlyoffice/documentserver/server/DocService/docservice

WORKDIR /

RUN  npm uninstall -g pkg grunt grunt-cli \
  && apt-get purge -y --autoremove ${build_deps} \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm -rf /root/.cache /root/.config/ /root/.npm/ /root/.pkg-cache \
  && rm -rf /build
