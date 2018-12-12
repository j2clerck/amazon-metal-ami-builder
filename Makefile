# VARIABLES
PACKER_URL ?= "https://releases.hashicorp.com/packer/1.3.3/packer_1.3.3_linux_amd64.zip"
GITHUB_REPO ?= "https://github.com/j2clerck/amazon-metal-ami-builder.git"
ISO_URL ?= "s3://clerckj/packer-windows/iso/Win10_1803_English_x64.iso"
PACKER_BUILD_FILE ?= "windows_10.json"
BUILD_NAME ?= "Windows_10"
BUILD_VERSION ?= "20181212"


# SETUP ENVIRONMENT
install_packages:
	set -e ; \
	apt update; \
	apt -y install unzip awscli nvme-cli git virtualbox jq ; \
	mkdir /opt/workdir/ ; \
	wget -O /tmp/packer.zip $(PACKER_URL) ; \
	unzip /tmp/packer.zip ; \
	chmod +x /tmp/packer ; \
	mv /tmp/packer /usr/bin/packer

# DOWNLOAD PACKER BUILD CONFIGURATION
download_build_spec:
	git clone $(GITHUB_REPO) ami-builder
	aws s3 cp $(ISO_URL) /opt/workdir/ami-builder/iso/

# LAUNCH BUILD
launch_build:
	set -e; \
	cd /opt/workdir/ami-builder/packer; \
	packer build --only virtualbox-iso $(PACKER_BUILD_FILE)

# UPLOAD OUTPUT TO S3
upload:
	aws s3 cp output-virtualbox-iso/*.ova s3://clerckj/vmimport/$(BUILD_NAME)_$(BUILD_VERSION).ova

import:
# LAUNCH VM IMPORT
	cat << EOF > disk.json
	[
	{
		"Description": "Windows10",
		"Format": "ova",
		"UserBucket": {
		"S3Bucket": "clerckj",
		"S3Key": "vmimport/$(BUILD_NAME)_$(BUILD_VERSION).ova"
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
	echo "Task id is ${ImportTaskId}. Run aws ec2 describe-import-image-tasks --import-task-ids ${ImportTaskId}"