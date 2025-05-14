FROM python AS build-stage

RUN pip install --no-cache-dir scrapyd-client

WORKDIR /workdir

COPY . .

RUN scrapyd-deploy --build-egg=tapology_scraper.egg

# Build the image.

FROM python:alpine

# Install Scrapy dependencies - and any others for your project.

RUN apk --no-cache add --virtual build-dependencies \
   gcc \
   musl-dev \
   libffi-dev \
   libressl-dev \
   libxml2-dev \
   libxslt-dev \
 && pip install --no-cache-dir \
   scrapyd \
 && apk del build-dependencies \
 && apk add \
   libressl \
   libxml2 \
   libxslt

# Mount two volumes for configuration and runtime.

VOLUME /etc/scrapyd/ /var/lib/scrapyd/

COPY ./scrapyd.conf /etc/scrapyd/

RUN mkdir -p /src/eggs/tapology_scraper

COPY --from=build-stage /workdir/tapology_scraper.egg /src/eggs/tapology_scraper/1.egg

# Copy requirements.txt and install dependencies
COPY requirements.txt .

RUN pip install -r requirements.txt

EXPOSE 6800

ENTRYPOINT ["scrapyd", "--pidfile="]