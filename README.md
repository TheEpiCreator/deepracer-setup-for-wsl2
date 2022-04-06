# Details
This repository contains a Linux shell file for easily installing deepracer-for-cloud on Windows Subsystem for Linux 2 (wsl2).

### Disclaimer
This repo has only been tested on a clean installation of Ubuntu 20.04 LTS for wsl2 on win11 using an Nvidia GPU and AMD/Intel CPU.

### Prerequisites
- Nvidia drivers compatible with wsl2
	- Instructions can be found at https://docs.nvidia.com/cuda/wsl-user-guide/index.html.
	- Stop after completing step 3, everything else will be done by this program.
- An access key with the ability to read and write models to/from an S3 bucket
	
## Usage
### Initial Setup
Execute this in your Ubuntu shell with the ability to use sudo:

	git clone https://github.com/TheEpiCreator/deepracer-setup-for-wsl2 && sudo bash ./deepracer-setup-for-wsl2/setup.sh

To use the experimental branch:

	git clone https://github.com/TheEpiCreator/deepracer-setup-for-wsl2 && cd ./deepracer-setup-for-wsl2 && git checkout experimental && cd .. && sudo bash ./deepracer-setup-for-wsl2/setup.sh
### Setup on Startup
If the WSL interface is restarted, run

	sudo -i

followed by
	
	source /home/YOUR-USERNAME-HERE/deepracer-for-cloud/bin/activate.sh

to get everything back up and running.
