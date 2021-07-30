#!/bin/bash

# File: .platform/hooks/prebuild/01_install_yarn.sh
# https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/platforms-linux-extend.html
# With Amazon Linux 2, installation scripts on the EC2 hosts are run through
# platform hooks. This script will execute within the prebuild step which occurs
# in the staging path.
# Make sure that this file has executable permissions (chmod +x)

echo "Installing NodeJS and Yarn"

# Install Node
echo "Checking if Node is already installed"
if ! command -v node > /dev/null; then
  echo "Installing Node...";
  curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -;
fi

node --version;

# Install yarn
echo "Checking if Yarn is already installed"
if ! command -v yarn > /dev/null; then
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo;
  sudo yum install -y yarn;
fi

yarn --version
view raw
