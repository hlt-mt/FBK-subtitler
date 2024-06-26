VERSION=v1_2

cd /FBK
# download models if the directory doesn't contains the same version
if [ ! -d "models" ]; then
    mkdir models
fi
if [ ! -d "models/FBK_data_$VERSION" ]; then
    wget -O models/FBK_data_$VERSION.tar.gz https://fbk.sharepoint.com/:u:/s/MTUnit/$SHAREPOINT_ID?download=1 && tar xvfz models/FBK_data_$VERSION.tar.gz && rm models/FBK_data_$VERSION.tar.gz
fi
echo "FBK_data_$VERSION downloaded"

mv models/FBK_data_$VERSION/* /root/.cache
