FROM python:3.8.2-buster

RUN apt-get update

COPY . /src 
WORKDIR /src

RUN make venv

ENV IS_CI=true
