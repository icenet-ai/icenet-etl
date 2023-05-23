from copy import deepcopy
import logging
from psycopg2.extras import RealDictCursor
from psycopg2.sql import SQL, Identifier
from pygeoapi.provider.postgresql import DatabaseConnection, PostgreSQLProvider
from pygeoapi.provider.base import ProviderQueryError

LOGGER = logging.getLogger(__name__)


class IceNetViewProvider(PostgreSQLProvider):
    """Provider focusing on efficient retrieval of PostgreSQL views"""

    def __init__(self, provider_def):
        """Pass definitions to parent class"""
        # Extract the foreign key arguments
        parent_def = deepcopy(provider_def)
        self.foreign_key_table = parent_def["data"].pop("foreign_key_table")
        self.foreign_key_name = parent_def["data"].pop("foreign_key_name")
        # Pass other arguments upwards
        super().__init__(parent_def)

    def query(
        self,
        startindex=0,
        limit=10,
        bbox=[],
        properties=[],
        sortby=[],
        select_properties=[],
        skip_geometry=False,
        **kwargs,
    ):
        """
        Query Postgis for all the content.
        e,g: http://localhost:5000/collections/hotosm_bdi_waterways/items?
        limit=1&resulttype=results

        :param startindex: starting record to return (default 0)
        :param limit: number of records to return (default 10)
        :param bbox: bounding box [minx,miny,maxx,maxy]
        :param properties: list of tuples (name, value)
        :param sortby: list of dicts (property, order)
        :param select_properties: list of property names
        :param skip_geometry: bool of whether to skip geometry (default False)

        :returns: GeoJSON FeaturesCollection
        """
        LOGGER.debug("Querying PostGIS")

        with DatabaseConnection(
            self.conn_dic, self.table, properties=self.properties
        ) as db:
            cursor = db.conn.cursor(cursor_factory=RealDictCursor)

            props = (
                SQL(", ").join([Identifier(p) for p in select_properties])
                if select_properties
                else db.columns
            )

            geom = (
                SQL("")
                if skip_geometry
                else SQL(",ST_AsGeoJSON({})").format(Identifier(self.geom))
            )

            where_clause = self._PostgreSQLProvider__get_where_clauses(
                properties=properties, bbox=bbox
            )

            orderby = (
                self._make_orderby(sortby) if sortby else SQL("")
            )

            limit_clause = SQL(f"LIMIT {limit}") if limit else SQL("")
            offset_clause = SQL(f"OFFSET {startindex}") if startindex else SQL("")

            sql_query = SQL(
                "SELECT {} {} FROM {} JOIN {} ON {} = {} {} {} {} {};"
            ).format(
                props,
                geom,
                Identifier(self.table),
                Identifier(self.foreign_key_table),
                Identifier(self.table, self.foreign_key_name),
                Identifier(self.foreign_key_table, self.foreign_key_name),
                where_clause,
                orderby,
                limit_clause,
                offset_clause,
            )

            LOGGER.debug("SQL Query: {}".format(sql_query.as_string(cursor)))
            LOGGER.debug("Start Index: {}".format(startindex))
            LOGGER.debug("End Index: {}".format(startindex + limit))
            try:
                cursor.execute(sql_query)
            except Exception as err:
                LOGGER.error(
                    "Error executing sql_query: {}".format(sql_query.as_string(cursor))
                )
                LOGGER.error(err)
                raise ProviderQueryError()

            row_data = cursor.fetchall()

            feature_collection = {"type": "FeatureCollection", "features": []}
            for rd in row_data:
                feature_collection["features"].append(
                    self._PostgreSQLProvider__response_feature(rd)
                )

            return feature_collection
