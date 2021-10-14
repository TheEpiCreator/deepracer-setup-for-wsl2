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
echo "${GREEN}You may have to enter some data during configuration.\nThis may take a while...${NC}"

# get GPU info
read -p "Are you running this on WSL2 for win11? (Only answer 'no' if you know what you're doing) [Y/n]: " -r HASWSLREP
HASWSL = [[ $HASWSLREP =~ ^[Yy]$ ]]

read -p "Is your GPU a 30-series (3070, 3080ti, 3060 super, etc.)? [Y/n]: " -r HASNVREP
HASNV = [[ $HASNVREP =~ ^[Yy]$ ]]


# install appropriate nvidia toolkit(s)
if [ $HASWSL ]
then
  sudo apt-get update
  wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
  sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
  wget https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
  sudo dpkg -i cuda-repo-wsl-ubuntu-11-4-local_11.4.0-1_amd64.deb
  sudo apt-key add /var/cuda-repo-wsl-ubuntu-11-4-local/7fa2af80.pub
  sudo apt-get update
  sudo apt-get -y install cuda
fi

# install nvidia-compatible docker
if [ $HASWSL ]
then
  echo "${RED}Please DO NOT abort the script. Doing so will result in an incomplete setup.${NC}"
fi

curl https://get.docker.com | sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

if [ $HASWSL ]
then
  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
  sudo apt-get update

  echo "Installing prerequisites."
  echo "${GREEN}Please enter 'y' when prompted.${NC}"
  sudo apt-get install -y nvidia-docker2
fi

sudo service docker stop
sudo service docker start

# install and configure prerequisites for aws-deepracer-community
sudo apt-get install jq awscli python3-boto3 docker-compose

cat /etc/docker/daemon.json | jq 'del(."default-runtime") + {"default-runtime": "nvidia"}' | sudo tee /etc/docker/daemon.json
sudo usermod -a -G docker $(id -un)

# install and configure aws-deepracer-community
git clone https://github.com/aws-deepracer-community/deepracer-for-cloud.git

echo "${GREEN}"
pwd
echo "${NC}"

cd deepracer-for-cloud
sudo bin/init.sh -a gpu -c local
# configure docker daemon settings
echo "{\n\t\"runtimes\": {\n\t\t\"nvidia\": {\n\t\t\t\"path\": \"nvidia-container-runtime\",\n\t\t\t\"runtimeArgs\": []\n\t\t}\n\t},\n\t\"default-runtime\": \"nvidia\"\n}" | sudo tee /etc/docker/daemon.json

# configure AWS
REGION=$(cat system.env | grep -P 'DR_AWS_APP_REGION=([\w\d\-]+)' -o | grep -P '[\w\d\-]+$' -o)

echo "${GREEN}Please enter your AWS credentials."
echo "When prompted for default region name and output format, type '${REGION}' and 'json' respectively${NC}"
aws configure

echo "${GREEN}Please enter 'minioadmin' for the first two prompts, leaving the others blank.${NC}"
aws configure --profile minio

if [ $HASNV ]
then
  echo "Configuring docker for 30-series GPU..."
  #TODO: replace whatever
  sed -i 's/DR_SAGEMAKER_IMAGE=4\.0\.0-gpu/DR_SAGEMAKER_IMAGE=4.0.0-gpu-nv/' system.env
  echo "Installing additional docker images..."
  docker pull awsdeepracercommunity/deepracer-sagemaker:4.0.0-gpu-nv
fi

# configure environment
cd bin
source activate.sh
docker ps
dr-update
dr-upload-custom-files

dr-start-training

#TODO: systemctl restart docker

# inform user about completion
echo "Please run 'cd ./deepracer-for-cloud && source ./bin/activate.sh' to complete setup."
sudo -s