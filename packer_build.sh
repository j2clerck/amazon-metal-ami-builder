#!/bin/bash

# VARIABLES
PACKER_URL="https://releases.hashicorp.com/packer/1.3.3/packer_1.3.3_linux_amd64.zip"
GITHUB_REPO="https://github.com/j2clerck/amazon-metal-ami-builder.git"
ISO_URL="s3://clerckj/packer-windows/iso/Win10_1803_English_x64.iso"
PACKER_BUILD_FILE="windows_10.json"
BUILD_NAME="Windows_10"
BUILD_VERSION="20181212"


# SETUP ENVIRONMENT
apt -y install unzip awscli nvme-cli git virtualbox jq
mkdir /opt/workdir/
cd /opt/workdir
wget $PACKER_URL
unzip packer_1.3.3_linux_amd64.zip
chmod +x packer
mv packer /usr/bin/

# DOWNLOAD PACKER BUILD CONFIGURATION
git clone $GITHUB_REPO
cd amazon-ami-builder/packer/
aws s3 cp $W10_URL ./iso/

# LAUNCH BUILD
packer build --only virtualbox-iso $PACKER_BUILD_FILE
if [ $? -ne 0 ]
then
    echo "Packer build failed"
    exit 1
fi

# UPLOAD OUTPUT TO S3
aws s3 cp output-virtualbox-iso/*.ova s3://clerckj/vmimport/${BUILD_NAME}_${BUILD_VERSION}.ova
if [ $? -ne 0 ]
then
    echo "Upload to S3 failed"
    exit 1
fi
# LAUNCH VM IMPORT
cat << EOF > disk.json
[
  {
    "Description": "Windows10",
    "Format": "ova",
    "UserBucket": {
      "S3Bucket": "clerckj",
      "S3Key": "vmimport/${BUILD_NAME}_${BUILD_VERSION}.ova"
    }
  }
]
EOF

ImportTaskId=`aws ec2 import-image \
    --architecture x86_64 \
    --description "Import packer build of ${BUILD_NAME}_${BUILD_VERSION}" \
    --license-type AUTO \
    --platform Windows \
    --disk-containers file://disk.json \
    --output json \
    | jq .ImportTaskId`

if [ $? -ne 0 ]
then
    echo "Start import task failed"
    exit 1
fi

echo "Task id is ${ImportTaskId}. Run aws ec2 describe-import-image-tasks --import-task-ids ${ImportTaskId}"