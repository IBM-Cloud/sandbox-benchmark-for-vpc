#!/bin/bash

## Setup logdna agent
if [ ! -z "${ingestion_key}" ]; then

sudo rpm --import https://assets.logdna.com/logdna.gpg

echo "[logdna]
name=LogDNA packages
baseurl=https://assets.logdna.com/el6/
enabled=1
gpgcheck=1
gpgkey=https://assets.logdna.com/logdna.gpg" | sudo tee /etc/yum.repos.d/logdna.repo

sudo yum -y install logdna-agent

sudo bash -c 'cat << EOF > /etc/logdna.env
LOGDNA_HOST="logs.${region}.logging.cloud.ibm.com"
LOGDNA_ENDPOINT=/logs/agent
LOGDNA_INGESTION_KEY="${ingestion_key}"
EOF'

# Allow the chronyd socket to send logs to Logdna
sudo ausearch -c 'chronyd' --raw | audit2allow -M my-chronyd
sudo semodule -X 300 -i my-chronyd.pp
sleep 10

sudo chkconfig logdna-agent on
sudo service logdna-agent start

fi
## Install docker, docker-compose and other yum packages
sudo yum update -y
sudo yum config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install unzip git docker-ce --allowerasing
sudo systemctl enable --now docker

curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose
mv docker-compose /usr/local/bin && sudo chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Download Sandbox UI repository
if [ ! -z "${personal_access_token}" ]; then
curl -H "Authorization: token ${personal_access_token}" -H "Accept: application/vnd.github.v3.raw" -L ${sandbox_ui_repo_url} -o sandbox.zip
else
curl -H "Accept: application/vnd.github.v3.raw" -L ${sandbox_ui_repo_url} -o sandbox.zip
fi

unzip sandbox.zip -d /opt/sandbox-dashboard
cd /opt/sandbox-dashboard/*/resources
./deploy.sh ${iam_trustedprofile} ${sandbox_uipassword}
