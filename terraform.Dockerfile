FROM hashicorp/terraform:0.13.3
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN apk add --no-cache bash py-pip
RUN apk add --virtual=build gcc libffi-dev musl-dev openssl-dev make python3-dev
RUN pip install --no-cache-dir azure-cli
COPY . /app
WORKDIR /app
ENTRYPOINT [ "bash", "/app/scripts/terraform.sh" ]
