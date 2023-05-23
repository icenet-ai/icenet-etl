#! /bin/bash

# Get paths
SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
BASEPATH=$(python -c "import pygeoapi as pkg; print(pkg.__path__[0])")
echo "Preparing to patch pygeoapi at ${BASEPATH}"
cd "$BASEPATH" || (echo "Could not find path!"; exit 1)

# Install IceNetViewProvider plugin
echo "Installing IceNetViewProvider plugin"
cp "$SCRIPT_DIR/icenet_views.py" "${BASEPATH}/provider/"
EXISTING_PROVIDER="'PostgreSQL': 'pygeoapi.provider.postgresql.PostgreSQLProvider',"
NEW_PROVIDER="'IceNetView': 'pygeoapi.provider.icenet_views.IceNetViewProvider',"
sed -i "s|${EXISTING_PROVIDER}|${EXISTING_PROVIDER} ${NEW_PROVIDER}|g" "${BASEPATH}/plugin.py"

# Apply patch from pygeoapi directory
PATCH_PATH=$(ls "$SCRIPT_DIR/pygeoapi.patch" 2> /dev/null)
if [ ! "$PATCH_PATH" ]; then
    echo "Could not find patch!"
    exit 1
fi
echo "Applying patch from ${PATCH_PATH}"
patch -p0 < "$PATCH_PATH"

# Reset maximum number of columns displayed
echo "Patching templates/collections/items/index.html"
sed -i "s|loop.index < 5|loop.index < 10|g" "${BASEPATH}/templates/collections/items/index.html"