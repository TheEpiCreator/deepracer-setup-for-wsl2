# Commands compiled by EPCR

# Some of the commands used can be found at:
#>https://docs.nvidia.com/cuda/wsl-user-guide/index.html#installing-nvidia-drivers
#>https://aws-deepracer-community.github.io/deepracer-for-cloud/windows.html
#>https://aws-deepracer-community.github.io/deepracer-for-cloud/installation.html
#>https://blog.gofynd.com/how-we-broke-into-the-top-1-of-the-aws-deepracer-virtual-circuit-c39a241979f5


# info
printf "This may take a while..."
sleep 5s

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
curl https://get.docker.com | sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
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
sudo sed -i 's/^{/{\n\t"default-runtime": "nvidia",/' /etc/docker/daemon.json


# inform user about completion
printf "\nSetup is done!"