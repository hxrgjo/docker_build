docker rm -f $(docker ps -a | grep tspv2_api_ad | awk '{print $1 }')
docker rmi -f $(docker images -q tspv2_api_ad)
docker rmi -f $(docker images -q asia.gcr.io/tspv1-188510/tspv2_api_ad)

docker rm -f $(docker ps -a | grep tspv2_api_proxy | awk '{print $1 }')
docker rmi -f $(docker images -q tspv2_api_proxy)
docker rmi -f $(docker images -q asia.gcr.io/tspv1-188510/tspv2_api_proxy)


