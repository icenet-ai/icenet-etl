# Standard library
import datetime
import io
import logging
import math
import os

# Third party
import azure.functions as func
import pandas as pd
import psycopg2
from shapely.geometry import Polygon
import xarray

# Local
from .progress import Progress
from .utils import batches, InputBlobTriggerException, mean_step_size


class Processor:
    def __init__(self, log_prefix, batch_size):
        """Constructor."""
        self.log_prefix = log_prefix
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
            "username_reader": "icenetreader",
            "username_writer": "icenetwriter",
        }
        self.projections = {
            "north": "6931",
            "south": "6932",
        }
        self.xr = None
        self.centroids_m = {}
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
                logging.info(
                    f"{self.log_prefix} Connected to database {db_name} on {db_host}."
                )
            except psycopg2.OperationalError as exc:
                logging.error(
                    f"{self.log_prefix} Failed to connect to database {db_name} on {db_host}!"
                )
                raise InputBlobTriggerException(exc)
        return self.cnxn_

    @property
    def cursor(self):
        """Construct a database cursor or return an existing cursor."""
        if not self.cursor_:
            self.cursor_ = self.cnxn.cursor()
        return self.cursor_

    def load(self, inputBlob: func.InputStream) -> None:
        """Load data from a file into an xarray."""
        logging.info(f"{self.log_prefix} Attempting to load {inputBlob.name}...")
        try:
            self.xr = xarray.open_dataset(io.BytesIO(inputBlob.read()))
            logging.info(
                f"{self.log_prefix} Loaded NetCDF data into array with dimensions: {self.xr.dims}."
            )
            # Compatibility with old file format
            compatibility = {}
            data_variables = list(self.xr.keys())
            if "mean" in data_variables:
                compatibility["mean"] = "sic_mean"
            if "stddev" in data_variables:
                compatibility["stddev"] = "sic_stddev"
            if compatibility:
                self.xr = self.xr.rename(compatibility)
            logging.info(
                f"{self.log_prefix} Identified data variables: {list(self.xr.keys())}."
            )
            # Try to identify hemisphere from geospatial extent
            if self.xr.attrs.get("geospatial_lat_max", 0) > 80:
                self.hemisphere = "north"
            elif self.xr.attrs.get("geospatial_lat_min", 0) < -80:
                self.hemisphere = "south"
            # Otherwise try to do so from keywords
            if not self.hemisphere:
                keywords = self.xr.attrs.get("keywords", "").lower()
                if "north" in keywords and "south" not in keywords:
                    self.hemisphere = "north"
                if "south" in keywords and "north" not in keywords:
                    self.hemisphere = "south"
            if not self.hemisphere:
                raise ValueError("Could not identify hemisphere!")
            logging.info(
                f"{self.log_prefix} Identified data as belonging to the {self.hemisphere}ern hemisphere."
            )
            # Read array into appropriate data structures
            self.centroids_m["x"] = [int(1000 * x_km) for x_km in self.xr.xc.values]
            self.centroids_m["y"] = [int(1000 * y_km) for y_km in self.xr.yc.values]
        except ValueError as exc:
            logging.error(
                f"{self.log_prefix} Could not load NetCDF data from {inputBlob.name}!"
            )
            raise InputBlobTriggerException(exc)

    def update_geometries(self) -> None:
        """Update the table of geometries, creating it if necessary."""
        # Ensure that geometry table exists
        logging.info(
            f"{self.log_prefix} Ensuring that geometries table '{self.tables['geom'][self.hemisphere]}' exists..."
        )
        self.cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {self.tables['geom'][self.hemisphere]} (
                cell_id SERIAL PRIMARY KEY,
                centroid_x int4,
                centroid_y int4,
                geom_{self.projections[self.hemisphere]} geometry,
                geom_4326 geometry,
                UNIQUE (centroid_x, centroid_y)
            );
            GRANT SELECT ON TABLE {self.tables['geom'][self.hemisphere]} TO icenetreader;
            GRANT INSERT, DELETE, UPDATE ON TABLE {self.tables['geom'][self.hemisphere]} TO icenetwriter;
            """
        )
        self.cnxn.commit()
        logging.info(
            f"{self.log_prefix} Ensured that geometries table '{self.tables['geom'][self.hemisphere]}' exists."
        )

        # Calculate the size of the grid cells
        logging.info(
            f"{self.log_prefix} Identifying cell geometries from input data..."
        )
        x_delta_m = int(0.5 * mean_step_size(self.centroids_m["x"]))
        y_delta_m = int(0.5 * mean_step_size(self.centroids_m["y"]))

        # Construct list of geometry records
        records = []
        for centroid_x_m in self.centroids_m["x"]:
            for centroid_y_m in self.centroids_m["y"]:
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
                records.append((centroid_x_m, centroid_y_m, geometry.wkt))
        logging.info(f"{self.log_prefix} Identified {len(records)} cell geometries.")

        # Insert geometries into the database
        logging.info(
            f"{self.log_prefix} Ensuring that '{self.tables['geom'][self.hemisphere]}' contains all {len(records)} geometries..."
        )
        n_batches = int(math.ceil(len(records) / self.batch_size))
        progress = Progress(len(records))
        for idx, record_batch in enumerate(batches(records, self.batch_size), start=1):
            logging.info(
                f"{self.log_prefix} Batch {idx}/{n_batches} :: preparing to insert/update {len(record_batch)} of {progress.total_records} geometries..."
            )
            insert_cmd = f"INSERT INTO {self.tables['geom'][self.hemisphere]} (cell_id, centroid_x, centroid_y, geom_{self.projections[self.hemisphere]}, geom_4326) VALUES\n"
            insert_cmd += ", ".join(
                [
                    f"(DEFAULT, {record[0]}, {record[1]}, ST_GeomFromText('{record[2]}', {self.projections[self.hemisphere]}), ST_Transform(ST_GeomFromText('{record[2]}', {self.projections[self.hemisphere]}), 4326))"
                    for record in record_batch
                ]
            )
            insert_cmd += "ON CONFLICT DO NOTHING;"
            self.cursor.execute(insert_cmd)
            self.cnxn.commit()
            logging.info(
                f"{f'{self.log_prefix} Batch {idx}/{n_batches} :: inserted/updated {len(record_batch)} geometries.':<100} {progress.snapshot(idx, n_batches)}"
            )
            # Explicitly delete collections once used
            del record_batch
        logging.info(
            f"{self.log_prefix} Ensured that '{self.tables['geom'][self.hemisphere]}' contains all geometries."
        )

    def update_forecasts(self) -> None:
        """Update the table of forecasts, creating it if necessary"""
        # Ensure that forecast table exists
        logging.info(
            f"{self.log_prefix} Ensuring that forecasts table '{self.tables['forecasts'][self.hemisphere]}' exists..."
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
            CREATE INDEX IF NOT EXISTS {self.tables['forecasts'][self.hemisphere]}_date_forecast_generated_index ON {self.tables['forecasts'][self.hemisphere]} (date_forecast_generated);
            GRANT SELECT ON TABLE {self.tables['forecasts'][self.hemisphere]} TO {self.tables['username_reader']};
            GRANT INSERT, DELETE, UPDATE ON TABLE {self.tables['forecasts'][self.hemisphere]} TO {self.tables['username_writer']};
            """
        )
        self.cnxn.commit()
        logging.info(
            f"{self.log_prefix} Ensured that forecasts table '{self.tables['forecasts'][self.hemisphere]}' exists."
        )

        # Construct a list of values
        logging.info(f"{self.log_prefix} Loading forecasts from input data...")
        df_forecasts = (
            self.xr.where(self.xr["sic_mean"] > 0).to_dataframe().dropna().reset_index()
        )
        df_forecasts["xc_m"] = pd.to_numeric(
            1000 * df_forecasts["xc"], downcast="integer"
        )
        df_forecasts["yc_m"] = pd.to_numeric(
            1000 * df_forecasts["yc"], downcast="integer"
        )
        logging.info(
            f"{self.log_prefix} Loaded {df_forecasts.shape[0]} forecasts from input data."
        )

        # Load all existing cells for this hemisphere
        logging.info(f"{self.log_prefix} Identifying cell IDs for all forecasts...")
        df_cells = pd.io.sql.read_sql_query(
            f"SELECT cell_id, centroid_x, centroid_y FROM {self.tables['geom'][self.hemisphere]};",
            self.cnxn,
        )
        logging.info(
            f"{self.log_prefix} Loaded {df_cells.shape[0]} cells from the database."
        )

        # Insert forecasts into the database
        logging.info(
            f"{self.log_prefix} Ensuring that table '{self.tables['forecasts'][self.hemisphere]}' contains all {df_forecasts.shape[0]} forecasts..."
        )
        n_batches = int(math.ceil(df_forecasts.shape[0] / self.batch_size))
        progress = Progress(df_forecasts.shape[0])
        for idx, df_batch in enumerate(
            batches(df_forecasts, self.batch_size, as_dataframe=True), start=1
        ):
            # Add cell IDs by merging forecasts onto pre-loaded cells
            df_merged = pd.merge(
                df_batch,
                df_cells,
                how="left",
                left_on=["xc_m", "yc_m"],
                right_on=["centroid_x", "centroid_y"],
            )
            # Insert merged forecasts into database
            logging.info(
                f"{self.log_prefix} Batch {idx}/{n_batches} :: preparing to insert/update {df_merged.shape[0]} of {progress.total_records} forecasts..."
            )
            insert_cmd = f"INSERT INTO {self.tables['forecasts'][self.hemisphere]} (forecast_id, date_forecast_generated, date_forecast_for, cell_id, sea_ice_concentration_mean, sea_ice_concentration_stddev) VALUES\n"
            insert_cmd += ", ".join(
                [
                    f"(DEFAULT, '{record.time.date()}', '{record.time.date() + datetime.timedelta(record.leadtime)}', {record.cell_id}, {record.sic_mean}, {record.sic_stddev})"
                    for record in df_merged.itertuples(False)
                ]
            )
            insert_cmd += "ON CONFLICT DO NOTHING;"
            self.cursor.execute(insert_cmd)
            self.cnxn.commit()
            logging.info(
                f"{f'{self.log_prefix} Batch {idx}/{n_batches} :: inserted/updated {df_merged.shape[0]} forecasts.':<100} {progress.snapshot(idx, n_batches)}"
            )
            # Explicitly delete collections once used
            del df_batch
            del df_merged
        logging.info(
            f"{self.log_prefix} Ensured that table '{self.tables['forecasts'][self.hemisphere]}' contains all {df_forecasts.shape[0]} forecasts."
        )

    def update_latest_forecast(self) -> None:
        """Update the 'latest forecast' view, creating it if necessary"""
        # Ensure that view table exists
        logging.info(
            f"{self.log_prefix} Updating materialised view '{self.tables['latest'][self.hemisphere]}'..."
        )
        self.cursor.execute(
            f"""
            DROP MATERIALIZED VIEW IF EXISTS {self.tables['latest'][self.hemisphere]};
            CREATE MATERIALIZED VIEW {self.tables['latest'][self.hemisphere]} AS
                SELECT
                    row_number() OVER (PARTITION BY true) as forecast_latest_id,
                    {self.tables['forecasts'][self.hemisphere]}.date_forecast_generated,
                    {self.tables['forecasts'][self.hemisphere]}.date_forecast_for,
                    {self.tables['forecasts'][self.hemisphere]}.sea_ice_concentration_mean,
                    {self.tables['forecasts'][self.hemisphere]}.sea_ice_concentration_stddev,
                    {self.tables['geom'][self.hemisphere]}.geom_{self.projections[self.hemisphere]},
                    {self.tables['geom'][self.hemisphere]}.geom_4326
                FROM {self.tables['forecasts'][self.hemisphere]}
                FULL OUTER JOIN {self.tables['geom'][self.hemisphere]}
                    ON {self.tables['forecasts'][self.hemisphere]}.cell_id = {self.tables['geom'][self.hemisphere]}.cell_id
                WHERE date_forecast_generated = (SELECT max(date_forecast_generated) FROM {self.tables['forecasts'][self.hemisphere]})
                GROUP BY date_forecast_generated, date_forecast_for, sea_ice_concentration_mean, sea_ice_concentration_stddev, geom_{self.projections[self.hemisphere]}, geom_4326;
            GRANT SELECT ON TABLE {self.tables['latest'][self.hemisphere]} TO {self.tables['username_reader']};
            GRANT INSERT, DELETE, UPDATE ON TABLE {self.tables['latest'][self.hemisphere]} TO {self.tables['username_writer']};
            """
        )
        self.cnxn.commit()
        logging.info(
            f"{self.log_prefix} Updated materialised view '{self.tables['latest'][self.hemisphere]}'."
        )
