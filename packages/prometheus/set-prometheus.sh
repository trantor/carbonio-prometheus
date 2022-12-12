#!/bin/bash
# Read Password
echo -n Please type Service Discover password: 
read -s password

CONSUL_HTTP_TOKEN=$(echo $password | gpg --batch --yes --passphrase-fd 0 -qdo - /etc/zextras/service-discover/cluster-credentials.tar.gpg | tar xOf - consul-acl-secret.json | jq .SecretID -r);

if [ -z ${CONSUL_HTTP_TOKEN} ]; then 
    echo "Wrong password";
    exit 1;
else
    export CONSUL_HTTP_TOKEN
    sed -i s/"{{ consultoken }}"/$CONSUL_HTTP_TOKEN/g /etc/carbonio/carbonio-prometheus/prometheus.yml;
    dom=$(hostname -d);
    sed -i s/"{{ hostsdomain }}"/$dom/g /etc/carbonio/carbonio-prometheus/prometheus.yml;
    consuldom=$(echo $(hostname -d) | sed s/\\\./-/g);
    sed -i s/"{{ consulhostsdomain }}"/$consuldom/g /etc/carbonio/carbonio-prometheus/prometheus.yml;

    echo "Restarting Carbonio Prometheus Service"
    systemctl restart carbonio-prometheus

    echo "Reloading Service Discover"
    consul reload
fi 