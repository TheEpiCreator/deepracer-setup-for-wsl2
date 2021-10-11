# Details
This repository contains a Linux shell file for easily installing deepracer-for-cloud on Windows Subsystem for Linux 2 (wsl2).

### Disclaimer
This repository is a personal project. It is not guaranteed to work and is not meant to be used in a production environment.

This repo has only been tested on Ubuntu for wsl2 using an Nvidia GPU and AMD CPU.

### Prerequisites
- Nvidia drivers compatible with wsl2
	- Instructions can be found at https://docs.nvidia.com/cuda/wsl-user-guide/index.html.
	- Only follow the instructions up to step 2.4, everything else will be done by the program.

## Usage
Execute this in your Ubuntu shell with sudo permissions:
	git clone https://github.com/TheEpiCreator/deepracer-setup-for-wsl2 && sudo sh ./deepracer-setup-for-wsl2/setup.sh