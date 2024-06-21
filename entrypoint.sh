export VERSION=v1_2

cd /FBK
# download models if the directory doesn't contains the same version
if [ ! -d "models" ]; then
    mkdir models
fi
if [ ! -d "models/FBK_data_$VERSION" ]; then
    wget -O models/FBK_data_$VERSION.tar.gz https://fbk.sharepoint.com/:u:/s/MTUnit/$SHAREPOINT_ID?download=1 && tar xvfz models/FBK_data_$VERSION.tar.gz && rm models/FBK_data_$VERSION.tar.gz && mv FBK_data FBK_data_$VERSION && mv FBK_data_$VERSION/.cache/* /root/.cache
fi
echo "FBK_data_$VERSION downloaded"
echo "Creating upload and out directories"
mkdir /FBK/server/upload mkdir /FBK/server/out
echo "Starting the server"
bash /FBK/server/CMD.httpserver_start.sh
