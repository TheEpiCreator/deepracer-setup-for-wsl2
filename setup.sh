#!/bin/bash
# Commands compiled by EPCR

# Some of the commands used can be found at:
# https://docs.nvidia.com/cuda/wsl-user-guide/index.html#installing-nvidia-drivers
# https://aws-deepracer-community.github.io/deepracer-for-cloud/windows.html
# https://aws-deepracer-community.github.io/deepracer-for-cloud/installation.html
# https://blog.gofynd.com/how-we-broke-into-the-top-1-of-the-aws-deepracer-virtual-circuit-c39a241979f5
# https://www.hanselman.com/blog/how-to-ssh-into-wsl2-on-windows-10-from-an-external-machine

# define utility variables
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'

# info
echo -e "${GREEN}You may have to enter some data during configuration.\nThis may take a while...${NC}"

# get GPU info
read -p "Are you running this on WSL2 for win11? (Only answer 'no' if you know what you're doing) [Y/n]: " -n 1 -r wsl_response
echo
case "$wsl_response" in
y | Y) has_wsl=1 ;;
n | N) has_wsl=0 ;;
*)
  has_wsl=1
  echo -e "${RED}Invalid response, defaulting to 'yes'.${NC}"
  ;;
esac

read -p "Is your GPU a 30-series (3070, 3080ti, 3060 super, etc.)? [Y/n]: " -n 1 -r thirtyseries_response
echo
case "$thirtyseries_response" in
y | Y) has_thirtyseries=1 ;;
n | N) has_thirtyseries=0 ;;
*)
  has_thirtyseries=0
  echo -e "${RED}Invalid response, defaulting to 'no'.${NC}"
  ;;
esac

# install appropriate nvidia toolkit(s)
if [ $has_wsl ]; then
  echo -e "${YELLOW}Updating preinstalled utils...${NC}"
  sudo apt-get update
  echo -e "${YELLOW}Installing cuda...${NC}"
  wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
  sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
  wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
  sudo dpkg -i cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
  sudo apt-key add /var/cuda-repo-wsl-ubuntu-11-4-local/7fa2af80.pub
  sudo apt-get update
  sudo apt-get -y install cuda
fi

# install nvidia-compatible docker
echo -e "${YELLOW}Installing docker...${NC}"
if [ $has_wsl ]; then
  echo -e "${RED}Please DO NOT abort the script. Doing so will result in an incomplete setup.${NC}"
fi

curl https://get.docker.com | sh
distribution=$(
  . /etc/os-release
  echo -e $ID$VERSION_ID
)

if [ $has_wsl ]; then
  echo -e "${YELLOW}Installing Nvidia docker compatibility${NC}"
  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
  sudo apt-get update
  sudo apt-get install -y nvidia-docker2
fi

sudo service docker stop
sudo service docker start

# install and configure prerequisites for aws-deepracer-community
echo -e "${YELLOW}Installing other prerequisites and utils...${NC}"
echo -e "${GREEN}Please enter 'y' when prompted.${NC}"
sudo apt-get install jq awscli python3-boto3 docker-compose net-tools

cat /etc/docker/daemon.json | jq 'del(."default-runtime") + {"default-runtime": "nvidia"}' | sudo tee /etc/docker/daemon.json
sudo usermod -a -G docker $(id -un)

# install and configure aws-deepracer-community
echo -e "${YELLOW}Downloading deepracer-for-cloud...${NC}"
git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git

echo -e "${YELLOW}Installing deepracer-for-cloud${NC}"
cd deepracer-for-cloud
sudo bin/init.sh -a gpu -c local
# configure docker daemon settings
echo -e "${YELLOW}Configuring docker...${NC}"
echo -e "{\n\t\"runtimes\": {\n\t\t\"nvidia\": {\n\t\t\t\"path\": \"nvidia-container-runtime\",\n\t\t\t\"runtimeArgs\": []\n\t\t}\n\t},\n\t\"default-runtime\": \"nvidia\"\n}" | sudo tee /etc/docker/daemon.json

# configure AWS
echo -e "${YELLOW}Configuring AWS...${NC}"
REGION=$(cat system.env | grep -P 'DR_AWS_APP_REGION=([\w\d\-]+)' -o | grep -P '[\w\d\-]+$' -o)

echo -e "${GREEN}Please enter your AWS credentials. Make sure the user you are registering as has the ability to create and upload to S3 buckets."
echo -e "When prompted for default region name and output format, type '${REGION}' and 'json' respectively${NC}"
aws configure

echo -e "${GREEN}Please enter 'minioadmin' for the first two prompts, leaving the others blank.${NC}"
aws configure --profile minio

if [ $has_thirtyseries ]; then
  echo -e "${YELLOW}Configuring docker for 30-series GPU...${NC}"
  sed -i 's/DR_SAGEMAKER_IMAGE=4\.0\.0-gpu/DR_SAGEMAKER_IMAGE=4.0.0-gpu-nv/' system.env
  sed -i 's/DR_ROBOMAKER_IMAGE=4\.0\.10-cpu-avx2/DR_ROBOMAKER_IMAGE=4.0.10-gpu/' system.env
  echo -e "${YELLOW}Installing additional docker images...${NC}"
  docker pull awsdeepracercommunity/deepracer-sagemaker:4.0.0-gpu-nv
  docker pull awsdeepracercommunity/deepracer-robomaker:4.0.10-gpu
fi

# configure environment
echo -e "${YELLOW}Installing portainer...${NC}"
docker volume create portainer_data
docker run -d -p 9443:9443 --name portainer \
--restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
portainer/portainer-ce:latest

echo -e "${YELLOW}Configuring deepracer-for-cloud...${NC}"
cd bin
source ./activate.sh
# give time for docker to run
sleep 2s
docker ps
dr-update
dr-upload-custom-files

# inform user about completion
echo -e "${GREEN}Setup is done! Please run 'sudo -s', then 'source ./deepracer-for-cloud/bin/activate.sh' to enable commands."
echo -e "You can now connect to localhost:8100 for an interactive GUI interface powered by portainer.${NOCOL}"
