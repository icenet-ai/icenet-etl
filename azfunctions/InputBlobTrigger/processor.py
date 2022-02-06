# Standard library
import datetime
import io
import logging
import math
import os
import time

# Third party
import azure.functions as func
import pandas as pd
import psycopg2
from shapely.geometry import Polygon
import xarray

# Local
from .utils import batches, human_readable, mean_step_size


class Processor:
    def __init__(self, batch_size):
        """Constructor."""
        self.batch_size = batch_size
        self.cnxn_ = None
        self.cursor_ = None
        self.tables = {
            "geom": {
                "north": "north_cell",
                "south": "south_cell",
            },
            "forecasts": {
                "north": "north_forecast",
                "south": "south_forecast",
            },
            "latest": {
                "north": "north_forecast_latest",
                "south": "south_forecast_latest",
            },
        }
        self.xr = None
        self.hemisphere = None

    def __del__(self):
        """Destructor."""
        if self.cnxn_:
            self.cnxn_.close()

    @property
    def cnxn(self):
        """Connect to the database or return an existing connection."""
        if not self.cnxn_:
            try:
                db_host = os.getenv("PSQL_HOST")
                db_name = os.getenv("PSQL_DB")
                db_user = os.getenv("PSQL_USER")
                db_pwd = os.getenv("PSQL_PWD")
                self.cnxn_ = psycopg2.connect(
                    dbname=db_name,
                    port="5432",
                    user=f"{db_user}@{db_host}",
                    password=db_pwd,
                    host=db_host,
                )
                logging.info(f"Connected to database {db_name} on {db_host}.")
            except psycopg2.OperationalError:
                logging.error(f"Failed to connect to database {db_name} on {db_host}!")
                raise
        return self.cnxn_

    @property
    def cursor(self):
        """Construct a database cursor or return an existing cursor."""
        if not self.cursor_:
            self.cursor_ = self.cnxn.cursor()
        return self.cursor_

    def load(self, inputBlob: func.InputStream) -> None:
        """Load data from a file into an xarray."""
        logging.info(f"Attempting to load {inputBlob.name}...")
        try:
            self.xr = xarray.open_dataset(io.BytesIO(inputBlob.read()))
            logging.info(
                f"Loaded NetCDF data into array with dimensions: {self.xr.dims}."
            )
            keywords = self.xr.attrs.get("keywords", "").lower()
            lat_max = self.xr.attrs.get("geospatial_lat_max", 0)
            lat_min = self.xr.attrs.get("geospatial_lat_min", 0)
            if ("north" in keywords) or (lat_max > 80.0):
                self.hemisphere = "north"
            elif ("south" in keywords) or (lat_min < -80):
                self.hemisphere = "south"
            if not self.hemisphere:
                raise ValueError("Could not identify hemisphere!")
            logging.info(
                f"Identified data as belonging to the {self.hemisphere}ern hemisphere."
            )
        except ValueError as exc:
            logging.error(f"Could not load NetCDF data from {inputBlob.name}!")
            logging.error(exc)

    def update_geometries(self) -> None:
        """Update the table of geometries, creating it if necessary."""
        # Ensure that geometry table exists
        logging.info(
            f"Ensuring that geometries table '{self.tables['geom'][self.hemisphere]}' exists..."
        )
        self.cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {self.tables['geom'][self.hemisphere]} (
                cell_id SERIAL PRIMARY KEY,
                centroid_x int4,
                centroid_y int4,
                geom_6931 geometry,
                geom_4326 geometry,
                UNIQUE (centroid_x, centroid_y)
            );
            """
        )
        self.cnxn.commit()
        logging.info(
            f"Ensured that geometries table '{self.tables['geom'][self.hemisphere]}' exists."
        )

        # Calculate the size of the grid cells
        logging.info("Identifying cell geometries from input data...")
        centroids_x_km, centroids_y_km = self.xr.xc.values, self.xr.yc.values
        x_delta_m = 1000 * int(0.5 * mean_step_size(centroids_x_km))
        y_delta_m = 1000 * int(0.5 * mean_step_size(centroids_y_km))

        # Construct list of geometry records
        records = []
        for centroid_x_km in centroids_x_km:
            centroid_x_m = int(1000 * centroid_x_km)
            for centroid_y_km in centroids_y_km:
                centroid_y_m = int(1000 * centroid_y_km)
                x_min_m, x_max_m = centroid_x_m - x_delta_m, centroid_x_m + x_delta_m
                y_min_m, y_max_m = centroid_y_m - y_delta_m, centroid_y_m + y_delta_m
                geometry = Polygon(
                    [
                        [x_min_m, y_max_m],
                        [x_max_m, y_max_m],
                        [x_max_m, y_min_m],
                        [x_min_m, y_min_m],
                        [x_min_m, y_max_m],
                    ]
                )
                records.append((centroid_x_m, centroid_y_m, geometry.wkt, geometry.wkt))
        logging.info(f"Identified {len(records)} cell geometries.")

        # Insert geometries into the database
        logging.info(
            f"Ensuring that '{self.tables['geom'][self.hemisphere]}' contains all {len(records)} geometries..."
        )
        n_batches = int(math.ceil(len(records) / self.batch_size))
        start_time = time.monotonic()
        for idx, record_batch in enumerate(batches(records, self.batch_size), start=1):
            logging.info(
                f"Batch {idx}/{n_batches}. Preparing to insert/update {len(record_batch)} geometries..."
            )
            for record in record_batch:
                self.cursor.execute(
                    f"""
                    INSERT INTO {self.tables['geom'][self.hemisphere]} (cell_id, centroid_x, centroid_y, geom_6931, geom_4326)
                    VALUES(DEFAULT, %s, %s, ST_GeomFromText(%s, 6931), ST_Transform(ST_GeomFromText(%s, 6931), 4326))
                    ON CONFLICT DO NOTHING;
                    """,
                    record,
                )
            self.cnxn.commit()
            remaining_time = (time.monotonic() - start_time) * (n_batches / idx - 1)
            logging.info(
                f"Batch {idx}/{n_batches}. Inserted/updated {len(record_batch)} geometries. Time remaining {human_readable(remaining_time)}."
            )
        logging.info(
            f"Ensured that '{self.tables['geom'][self.hemisphere]}' contains all geometries."
        )

    def update_forecasts(self) -> None:
        """Update the table of forecasts, creating it if necessary"""
        # Ensure that forecast table exists
        logging.info(
            f"Ensuring that forecasts table '{self.tables['forecasts'][self.hemisphere]}' exists..."
        )
        self.cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {self.tables['forecasts'][self.hemisphere]} (
                forecast_id SERIAL PRIMARY KEY,
                date_forecast_generated date,
                date_forecast_for date,
                cell_id int4,
                sea_ice_concentration_mean float4,
                sea_ice_concentration_stddev float4,
                UNIQUE (date_forecast_generated, date_forecast_for, cell_id),
                CONSTRAINT fk_cell_id FOREIGN KEY(cell_id) REFERENCES {self.tables['geom'][self.hemisphere]}(cell_id)
            );
            """
        )
        self.cnxn.commit()
        logging.info(
            f"Ensured that forecasts table '{self.tables['forecasts'][self.hemisphere]}' exists."
        )

        # Construct a list of values
        logging.info("Loading forecasts from input data...")
        df_forecasts = (
            self.xr.where(self.xr["mean"] > 0).to_dataframe().dropna().reset_index()
        )
        df_forecasts["xc_m"] = pd.to_numeric(
            1000 * df_forecasts["xc"], downcast="integer"
        )
        df_forecasts["yc_m"] = pd.to_numeric(
            1000 * df_forecasts["yc"], downcast="integer"
        )
        logging.info(f"Loaded {df_forecasts.shape[0]} forecasts from input data.")

        # Get cell IDs by loading existing cells and merging onto list of forecasts
        logging.info("Identifying cell IDs for all forecasts...")
        df_cells = pd.io.sql.read_sql_query(
            f"SELECT cell_id, centroid_x, centroid_y FROM {self.tables['geom'][self.hemisphere]};",
            self.cnxn,
        )
        df_merged = pd.merge(
            df_forecasts,
            df_cells,
            how="left",
            left_on=["xc_m", "yc_m"],
            right_on=["centroid_x", "centroid_y"],
        )
        logging.info(f"Identified cell IDs for {df_merged.shape[0]} forecasts.")

        # Insert forecasts into the database
        logging.info(
            f"Ensuring that table '{self.tables['forecasts'][self.hemisphere]}' contains all {df_merged.shape[0]} forecasts..."
        )
        n_batches = int(math.ceil(df_merged.shape[0] / self.batch_size))
        start_time = time.monotonic()
        for idx, record_batch in enumerate(
            batches(df_merged, self.batch_size), start=1
        ):
            logging.info(
                f"Batch {idx}/{n_batches}. Preparing to insert/update {len(record_batch)} forecasts..."
            )
            for record in record_batch:
                self.cursor.execute(
                    f"""
                    INSERT INTO {self.tables['forecasts'][self.hemisphere]} (forecast_id, date_forecast_generated, date_forecast_for, cell_id, sea_ice_concentration_mean, sea_ice_concentration_stddev)
                    VALUES(
                        DEFAULT,
                        %s,
                        %s,
                        %s,
                        %s,
                        %s
                    )
                    ON CONFLICT DO NOTHING;
                    """,
                    [
                        record.time.date(),
                        record.time.date() + datetime.timedelta(record.leadtime),
                        record.cell_id,
                        record.mean,
                        record.stddev,
                    ],
                )
            self.cnxn.commit()
            remaining_time = (time.monotonic() - start_time) * (n_batches / idx - 1)
            logging.info(
                f"Batch {idx}/{n_batches}. Inserted/updated {len(record_batch)} forecasts. Time remaining {human_readable(remaining_time)}."
            )
        logging.info(
            f"Ensured that table '{self.tables['forecasts'][self.hemisphere]}' contains all {df_merged.shape[0]} forecasts."
        )

    def update_latest_forecast(self) -> None:
        """Update the 'latest forecast' view, creating it if necessary"""
        # Ensure that view table exists
        logging.info(
            f"Updating materialised view '{self.tables['latest'][self.hemisphere]}'..."
        )
        self.cursor.execute(
            f"""
            DROP MATERIALIZED VIEW {self.tables['latest'][self.hemisphere]};
            CREATE MATERIALIZED VIEW {self.tables['latest'][self.hemisphere]} AS
                SELECT
                    row_number() OVER (PARTITION BY true) as forecast_latest_id,
                    {self.tables['forecasts'][self.hemisphere]}.date_forecast_generated,
                    {self.tables['forecasts'][self.hemisphere]}.date_forecast_for,
                    {self.tables['forecasts'][self.hemisphere]}.sea_ice_concentration_mean,
                    {self.tables['forecasts'][self.hemisphere]}.sea_ice_concentration_stddev,
                    {self.tables['geom'][self.hemisphere]}.cell_id,
                    {self.tables['geom'][self.hemisphere]}.centroid_x,
                    {self.tables['geom'][self.hemisphere]}.centroid_y,
                    {self.tables['geom'][self.hemisphere]}.geom_6931,
                    {self.tables['geom'][self.hemisphere]}.geom_4326
                FROM {self.tables['forecasts'][self.hemisphere]}
                FULL OUTER JOIN cell ON {self.tables['forecasts'][self.hemisphere]}.cell_id = {self.tables['geom'][self.hemisphere]}.cell_id
                WHERE date_forecast_generated = (SELECT max(date_forecast_generated) FROM {self.tables['forecasts'][self.hemisphere]})
                GROUP BY {self.tables['geom'][self.hemisphere]}.cell_id, date_forecast_generated, date_forecast_for, centroid_x, centroid_y, sea_ice_concentration_mean, sea_ice_concentration_stddev, geom_6931, geom_4326;
            """
        )
        self.cnxn.commit()
        logging.info(
            f"Updated materialised view '{self.tables['latest'][self.hemisphere]}'."
        )
