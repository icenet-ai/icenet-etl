# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:4-python3.8-appservice
FROM mcr.microsoft.com/azure-functions/python:4-python3.8-appservice

ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    PYTHON_ISOLATE_WORKER_DEPENDENCIES=1

COPY requirements.txt /
# RUN apt-get update && apt-get install -y \
#    gcc g++ libgeos-dev pkg-config libhdf5-103 libhdf5-dev \
#    && rm -rf /var/lib/apt/lists/* && pip --no-cache-dir install --prefer-binary --user -r /requirements.txt
RUN pip install --upgrade pip setuptools wheel && rm -rf /var/lib/apt/lists/* && \
    pip --no-cache-dir install --prefer-binary \
        azure-functions \
        azure-communication-email \
        cfgrib \
        eccodes \
        h5py==2.10.0 \
        ibicus \
        matplotlib \
        netcdf4 \
        rioxarray \
        'urllib3<=2.0.0' \
        xarray[io] && pip install --no-deps icenet

COPY . /home/site/wwwroot
