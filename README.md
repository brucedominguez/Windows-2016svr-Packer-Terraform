
# Medium Article Artificates

This project outlines the Windows Server Builds using Packer and Terraform

## Installation

Use the Packer [Packer](https://www.packer.io/downloads.html) or run via Jenkins build.

```bash
# For Linux
curl -O https://releases.hashicorp.com/packer/1.3.3/packer_1.3.3_linux_amd64.zip 
sudo mkdir /bin/packer
sudo unzip packer_1.3.3_linux_amd64.zip -d /usr/local/bin/
sudo rm packer_1.3.3_linux_amd64.zip

# For Windows
https://releases.hashicorp.com/packer/1.3.3/packer_1.3.3_windows_amd64.zip
```

## Prerequisite
Set your AWS CLI profile prior to running scripts
```bash
aws configure --profile <NAME OF YOUR PROFILE>
```

## Usage

```bash
# Validate Packer file before run
packer validate #add json file name

# Validate Packer file before run
packer build #add json file name
```
## Terraform Outputs
```bash
Private_Key_Filename = XXXX.pem
Public_DNS = ec2-XXX-XXX-XXX-XXX.ap-southeast-2.compute.amazonaws.com
Public_IP = XXX.XXX.XX.XX
Public_Key_Filename = XXXX.pub
SSH_Key_Name = XXXXXXXXXXXXXXXX
administrator_password = <ADMIN PASSWORD>
instance_id = i-XXXXXXXXX
```
## Connect to Server

RDP to the Public_DNS address or Public_IP

## Authors

* **Bruce Dominguez** - *Initial work* - [GitHub][first-contributor]

## License
[MIT](https://choosealicense.com/licenses/mit/)