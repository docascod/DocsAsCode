FROM node:12.13.0-alpine as node_builder

ENV NODE_ENV production
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV NPM_CONFIG_LOGLEVEL=error

RUN apk add --no-cache python make g++

WORKDIR /decktape

COPY scripts/decktape/package.json scripts/decktape/npm-shrinkwrap.json ./
COPY scripts/decktape/libs libs/
COPY scripts/decktape/plugins plugins/
COPY scripts/decktape/decktape.js ./

# Force HummusJS build from source
# See https://github.com/galkahana/HummusJS/issues/230
RUN npm install --build-from-source=hummus && \
    rm -rf node_modules/hummus/src && \
    rm -rf node_modules/hummus/build

WORKDIR /mermaid

RUN npm install mermaid.cli
ADD scripts/mermaid/puppeteer.json ./

WORKDIR /vega

RUN apk --no-cache --virtual .canvas-build-deps add \
        build-base \
        cairo-dev \
        jpeg-dev \
        pango-dev \
        giflib-dev \
        pixman-dev \
        pangomm-dev \
        libjpeg-turbo-dev \
        freetype-dev \
  && apk --no-cache add \
        pixman \
        cairo \
        pango \
        giflib \
  && npm config set user 0 \
  && npm config set unsafe-perm true \
  && npm install --build-from-source vega-cli vega vega-lite vega-embed

FROM alpine as pandoc_builder

ARG pandoc_version=2.9.2
ENV PANDOC_VERSION=${pandoc_version}

RUN mkdir /pandoc && wget -q https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz -P /tmp/ \
    && tar xzf /tmp/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz --strip-components 1 -C /pandoc/ \
    && rm -f /tmp/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz && ls -al /usr/local/

FROM alpine as grammalecte_builder

ARG grammalecte_version=1.7.0
ENV GRAMMALECTE_VERSION=${grammalecte_version}

RUN mkdir /grammalecte && wget -q https://grammalecte.net/grammalecte/zip/Grammalecte-fr-v${GRAMMALECTE_VERSION}.zip -P /grammalecte/ \
    && unzip -qq /grammalecte/Grammalecte-fr-v${GRAMMALECTE_VERSION}.zip -d /grammalecte/ \
    && rm -f /grammalecte/Grammalecte-fr-v${GRAMMALECTE_VERSION}.zip

FROM alpine as revealjs_builder
# carefull to asciidoc-revealjs version
ARG revealjs_version=3.9.2

ENV REVEALJS_VERSION=${revealjs_version}

RUN mkdir /revealjs && wget -q https://transfer.q2r.net/MCaDZ/${REVEALJS_VERSION}.tar.gz -P /tmp/ \
    && tar xzf /tmp/${REVEALJS_VERSION}.tar.gz --strip-components 1 -C /revealjs/

# ------ Final dockerfile ------

FROM asciidoctor/docker-asciidoctor

# Write UID/GID overwrite
ENV PID=1000
ENV GID=1000

LABEL MAINTAINERS="docsascode@protonmail.com"

# qpdf installation
RUN apk add --no-cache qpdf

# Chromium installation
RUN apk add --no-cache  chromium --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main

# Revealjs installation
COPY --from=revealjs_builder /revealjs /reveal.js
# upgrade version due to multicolumn layout
RUN apk add --no-cache --virtual .rubymakedepends \
    build-base \
    libxml2-dev \
    ruby-dev \
  && gem install --no-document \
    "asciidoctor-revealjs:4.0.1" \
  && apk del -r --no-cache .rubymakedepends

# Node.js installation
WORKDIR /
COPY --from=node_builder /usr/local/bin/node /usr/local/bin/

# DeckTape installation
ENV TERM xterm-color
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    echo @edge http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk add --no-cache \
    ca-certificates \
    libstdc++@edge \
    font-noto-emoji@edge \
    freetype@edge \
    harfbuzz@edge \
    nss@edge \
    ttf-freefont@edge \
    wqy-zenhei@edge && \
    mv /etc/fonts/conf.d/44-wqy-zenhei.conf /etc/fonts/conf.d/74-wqy-zenhei.conf

COPY --from=node_builder /decktape /decktape
ADD scripts/decktape/decktape /usr/local/bin/decktape

# Mermaid installation
COPY --from=node_builder /mermaid /mermaid
ADD scripts/mermaid/mmdc /usr/local/bin/mmdc

# Vega installation
COPY --from=node_builder /vega /vega
ENV PATH="/vega/node_modules/vega-cli/bin:/vega/node_modules/vega-lite/bin:${PATH}"

# Pandoc installation
COPY --from=pandoc_builder /pandoc /pandoc
ENV PATH="/pandoc/bin:${PATH}"

# Grammalecte installation
COPY --from=grammalecte_builder /grammalecte /grammalecte

# aspell installation
RUN apk add --no-cache \
    aspell \
    aspell-en \
    aspell-fr

RUN rm -rf /var/cache/apk/*

# ----- DocsAsCode -----

# RUN npm install -g @alexlafroscia/yaml-merge

ADD scripts/docsascode/*.tex /usr/local/bin/templates/
ADD scripts/docsascode/*.lua /usr/local/bin/templates/
ADD scripts/docsascode/*.sh /usr/local/bin/

# ------ Themes & checks integration --------

ADD fonts/* /usr/lib/ruby/gems/2.6.0/gems/asciidoctor-pdf-${ASCIIDOCTOR_PDF_VERSION}/data/fonts/
ADD checks/ /checks/
ADD outputs/ /output/

RUN addgroup -g 1000 node && \
    adduser -u 1000 -G node -s /bin/sh -D node && \
    chown node:node /documents

WORKDIR /documents
VOLUME /documents

# USER node

ENTRYPOINT ["entrypoint.sh"]