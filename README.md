# Details
This repository contains a Linux shell file for easily installing deepracer-for-cloud on Windows Subsystem for Linux 2 (wsl2).

### Disclaimer
This repo has only been tested on a clean installation of Ubuntu 20.04 LTS for wsl2 on win11 using an Nvidia GPU and AMD CPU.

### Prerequisites
- Nvidia drivers compatible with wsl2
	- Instructions can be found at https://docs.nvidia.com/cuda/wsl-user-guide/index.html.
	- Only follow the instructions up to step 2.4, everything else will be done by the program.
- An AWS account in which to dump training info
	
## Usage
Execute this in your Ubuntu shell with the ability to use sudo:

	git clone https://github.com/TheEpiCreator/deepracer-setup-for-wsl2 && sudo bash ./deepracer-setup-for-wsl2/setup.sh

To use the experimental branch:

	git clone https://github.com/TheEpiCreator/deepracer-setup-for-wsl2 && cd ./deepracer-setup-for-wsl2 && git checkout experimental && cd .. && sudo bash ./deepracer-setup-for-wsl2/setup.sh