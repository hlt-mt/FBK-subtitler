cd /workspace
# download models if the directory doesn't contains the same version
if [ ! -d "models" ]; then
    mkdir models
fi
if [ ! -d "models/FBK_data_v1_2" ]; then
    wget -O models/FBK_data_v1_2.tar.gz https://fbk.sharepoint.com/:u:/s/MTUnit/$SHAREPOINT_ID?download=1 && tar xvfz models/FBK_data_v1_2.tar.gz && rm models/FBK_data_v1_2.tar.gz
fi
echo "FBK_data_v1_2 downloaded"

mv models/FBK_data_v1_2/* root/.cache
