FROM docker:stable-dind

RUN apk --no-cache add \
  bash

COPY concourse-compose.sh /usr/local/bin/

ENTRYPOINT ["concourse-compose.sh"]
