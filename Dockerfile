FROM node:16.13.0-alpine as build

WORKDIR /app

COPY package.json .yarnrc.yml /app/
COPY .yarn /app/.yarn
COPY packages/@uppy/companion /app/packages/@uppy/companion

RUN apk --update add  --virtual native-dep \
  make gcc g++ python3 libgcc libstdc++ git && \
  (cd /app && corepack yarn workspaces focus @uppy/companion) && \
  apk del native-dep

RUN cd /app && corepack yarn workspace @uppy/companion build

# Now remove all non-prod dependencies for a leaner image
RUN cd /app && corepack yarn workspaces focus @uppy/companion --production

FROM node:16.13.0-alpine

WORKDIR /app

# copy required files from build stage.
COPY --from=build /app/packages/@uppy/companion/bin /app/bin
COPY --from=build /app/packages/@uppy/companion/lib /app/lib
COPY --from=build /app/packages/@uppy/companion/package.json /app/package.json
COPY --from=build /app/packages/@uppy/companion/node_modules /app/node_modules

ENV PATH "${PATH}:/app/node_modules/.bin"

CMD ["node","/app/bin/companion"]
# This can be overruled later
EXPOSE 3020