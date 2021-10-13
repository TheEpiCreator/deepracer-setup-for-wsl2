# Commands compiled by EPCR

# Some of the commands used can be found at:
#>https://docs.nvidia.com/cuda/wsl-user-guide/index.html#installing-nvidia-drivers
#>https://aws-deepracer-community.github.io/deepracer-for-cloud/windows.html
#>https://aws-deepracer-community.github.io/deepracer-for-cloud/installation.html
#>https://blog.gofynd.com/how-we-broke-into-the-top-1-of-the-aws-deepracer-virtual-circuit-c39a241979f5


# define utility variables
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[1;32m'


# info
echo -e "${GREEN}You may have to enter some data during configuration.\nThis may take a while...${NC}"
sleep 3s

# install appropriate nvidia toolkit(s)
sudo apt-get update
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
sudo dpkg -i cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
sudo apt-key add /var/cuda-repo-wsl-ubuntu-11-4-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda

# install nvidia-compatible docker
echo -e "${RED}Please DO NOT abort the script. Doing so will result in an incomplete setup.${NC}"

curl https://get.docker.com | sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update

echo -e "Installing prerequisites."
echo -e "${GREEN}Please enter 'y' when prompted.${NC}"
sudo apt-get install -y nvidia-docker2

sudo service docker stop
sudo service docker start

# install and configure prerequisites for aws-deepracer-community
sudo apt-get install jq awscli python3-boto3 docker-compose

cat /etc/docker/daemon.json | jq 'del(."default-runtime") + {"default-runtime": "nvidia"}' | sudo tee /etc/docker/daemon.json
sudo usermod -a -G docker $(id -un)

# install and configure aws-deepracer-community
git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git

cd deepracer-for-cloud
sudo bin/init.sh -a gpu -c local
# configure docker daemon settings
echo -e "{\n\t\"runtimes\": {\n\t\t\"nvidia\": {\n\t\t\t\"path\": \"nvidia-container-runtime\",\n\t\t\t\"runtimeArgs\": []\n\t\t}\n\t},\n\t\"default-runtime\": \"nvidia\"\n}" | sudo tee /etc/docker/daemon.json

# configure AWS
REGION=$(cat system.env | grep -P 'DR_AWS_APP_REGION=([\w\d\-]+)' -o | grep -P '[\w\d\-]+$' -o)

echo -e "${GREEN}Please enter your AWS credentials."
echo -e "When prompted for default region name and output format, type '${REGION}' and 'json' respectively${NC}"
aws configure

echo -e "${GREEN}Please enter 'minioadmin' for the first two prompts, leaving the others blank.${NC}"
aws configure --profile minio

# configure environment
cd bin
sudo -s
source activate.sh
docker ps
# create local buckets
dr-upload-custom-files

# get cuda working
apt install nvidia-utils-470-server
sudo apt update
sudo apt install python3-dev python3-pip python3-venv
pip install tensorflow
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64

dr-start-training



# inform user about completion
echo -e "Setup is done!"