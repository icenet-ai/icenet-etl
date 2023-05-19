# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:4-python3.9-appservice
FROM mcr.microsoft.com/azure-functions/python:4-python3.9

ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    PYTHON_ISOLATE_WORKER_DEPENDENCIES=1

RUN apt-get -y install gcc g++ libgeos-dev pkg-config libhdf5-103 libhdf5-dev

COPY requirements.txt /
RUN pip install -r /requirements.txt

