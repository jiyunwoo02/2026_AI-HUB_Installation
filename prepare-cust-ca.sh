#!/bin/bash -e

# https://mikefarah.gitbook.io/yq/commands/write-update
YQ_MAIN_VERSION="$(./yq --version|sed -e 's/^.\+version \([0-9]\)\..*/\1/')"

function yq_read() {
    eval "yq_${YQ_MAIN_VERSION}_read $*"
}
function yq_write() {
    eval "yq_${YQ_MAIN_VERSION}_write $*"
}
function yq_add_map() {
  eval "yq_${YQ_MAIN_VERSION}_add_map $*"
}
function yq_4_read() {
    YML_FILE=$1
    ITEM=$2
    #yq eval '.services.rm-proxy-svc.environment' docker-compose.yml
    ./yq e ".$ITEM" "$YML_FILE"
}
function yq_4_write() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq eval '.services.rm-proxy-svc.environment' docker-compose.yml
    #yq e '.a.b += ["cow"]'
    ./yq -i e ".$ITEM += [\"$VALUE\"]" "$YML_FILE"
}
function yq_4_add_map() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq -i e ".services.deployment-init.user = \"root\""
    ./yq -i e ".$ITEM = \"$VALUE\"" "$YML_FILE"
}
function yq_3_read() {
    YML_FILE=$1
    ITEM=$2
    #yq r "$PLATFORM_YML" services.deployment-init.environment
    ./yq r "$YML_FILE" "$ITEM"
}
function yq_3_write() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq w -i "$PLATFORM_YML" "services.deployment-init.environment[+]" "HTTPS_CRT_PATH=\${HTTPS_CRT_PATH}"
    ./yq w -i "$YML_FILE" "$ITEM[+]" "$VALUE"
}
function yq_3_add_map() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq w -i docker-compose.yml "services.deployment-init.user" "root"
    ./yq w -i "$YML_FILE" "$ITEM" "$VALUE"
}

PLATFORM_YML="docker-compose.yml"
ENV_FILE=".env"

PLATFORM_ORIG="docker-compose_orig.yml"
ENV_ORIG=".env_orig"

if [ -f "$PLATFORM_ORIG" ];then
    echo "Backup file $PLATFORM_ORIG already created"
else
    cp "$PLATFORM_YML" "$PLATFORM_ORIG"
fi
if [ -f "$ENV_ORIG" ];then
    echo "Backup file $ENV_ORIG already created"
else
    cp "$ENV_FILE" "$ENV_ORIG"
fi

if [[ -n $1 && $1 == "extraKC" ]];
then
    #
    # Keycloak components
    #
    if ! (yq_read "$PLATFORM_YML" services.keycloak.volumes|grep -v "^#"|grep -q '\.\/ssl\/java_cacerts');then
        yq_write "$PLATFORM_YML" "services.keycloak.volumes" "./ssl/java_cacerts:/tmp/cacerts"
    fi
    if ! (yq_read "$PLATFORM_YML" services.keycloak|grep -v "^#"|grep -q 'spi-truststore-file-file=/tmp/cacerts/cacerts');then

        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" '/opt/keycloak/bin/kc.sh'
        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" 'start'
        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" 'firstPlaceholder'
        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" 'secondPlaceholder'
        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" 'thirdPlaceholder'
        yq_write "$PLATFORM_YML" "services.keycloak.entrypoint" 'fourthPlaceholder'

        sed -i 's,firstPlaceholder,--spi-truststore-file-file=/tmp/cacerts/cacerts,' "$PLATFORM_YML"
        sed -i 's,secondPlaceholder,--spi-truststore-file-password=changeit,' "$PLATFORM_YML"
        sed -i 's,thirdPlaceholder,--spi-truststore-file-hostname-verification-policy=ANY,' "$PLATFORM_YML"
        sed -i 's,fourthPlaceholder,--spi-truststore-file-type=jks,' "$PLATFORM_YML"

    fi
elif [[ -n $1 && $1 == "external-agent" ]];
then
    extPLATFORM_YML="external-agents/${PLATFORM_YML}"
    extENV_FILE="external-agents/${ENV_FILE}"

    if ! (yq_read "$extPLATFORM_YML" services.ext-webapi-agent-1.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
        yq_write "$extPLATFORM_YML" "services.ext-webapi-agent-1.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
    fi
    if ! (yq_read "$extPLATFORM_YML" services.ext-webapi-agent-1.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
        yq_write "$extPLATFORM_YML" "services.ext-webapi-agent-1.volumes" "../ssl/java_cacerts:/mnt/cacerts"
    fi
    if ! (yq_read "$extPLATFORM_YML" services.license-proxy.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
        yq_write "$extPLATFORM_YML" "services.license-proxy.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
    fi
    if ! (yq_read "$extPLATFORM_YML" services.license-proxy.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
        yq_write "$extPLATFORM_YML" "services.license-proxy.volumes" "../ssl/java_cacerts:/mnt/cacerts"
    fi
    if grep -q -E '^WEBAPI_REGISTRY_PROTOCOL=http$' "$extENV_FILE";then
        sed -i 's/^WEBAPI_REGISTRY_PROTOCOL=http$/WEBAPI_REGISTRY_PROTOCOL=https/' "$extENV_FILE"
    fi
    if grep -q -E '^WEBAPI_REGISTRY_PORT=80$' "$extENV_FILE";then
        sed -i 's/^WEBAPI_REGISTRY_PORT=80$/WEBAPI_REGISTRY_PORT=443/' "$extENV_FILE"
    fi
    if grep -q -E '^WEBAPI_AIHUB_CONNECTION_PROTOCOL=http$' "$extENV_FILE";then
        sed -i 's/^WEBAPI_AIHUB_CONNECTION_PROTOCOL=http$/WEBAPI_AIHUB_CONNECTION_PROTOCOL=https/' "$extENV_FILE"
    fi
    if grep -q -E '^WEBAPI_AIHUB_CONNECTION_PORT=80$' "$extENV_FILE";then
        sed -i 's/^WEBAPI_AIHUB_CONNECTION_PORT=80$/WEBAPI_AIHUB_CONNECTION_PORT=443/' "$extENV_FILE"
    fi
    if grep -q -E '^EUREKA_INSTANCE_SECURE_PORT_ENABLED=false$' "$extENV_FILE";then
        sed -i 's/^EUREKA_INSTANCE_SECURE_PORT_ENABLED=false/EUREKA_INSTANCE_SECURE_PORT_ENABLED=true/' "$extENV_FILE"
    fi
    if grep -q -E '^EUREKA_INSTANCE_NON_SECURE_PORT_ENABLED=true$' "$extENV_FILE";then
        sed -i 's/^EUREKA_INSTANCE_NON_SECURE_PORT_ENABLED=true/EUREKA_INSTANCE_NON_SECURE_PORT_ENABLED=false/' "$extENV_FILE"
    fi
    if ! (yq_read "$extPLATFORM_YML" services.coding-environment-storage.environment|grep -v "^#"|grep -q 'REQUESTS_CA_BUNDLE');then
        yq_write "$extPLATFORM_YML" "services.coding-environment-storage.environment" "REQUESTS_CA_BUNDLE=/etc/ssl/certs/"
    fi
    if ! (yq_read "$extPLATFORM_YML" services.coding-environment-storage.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
        yq_write "$extPLATFORM_YML" "services.coding-environment-storage.volumes" "../ssl/deb_cacerts:/etc/ssl/certs"
    fi
fi

if ! (yq_read "$PLATFORM_YML" "services.deployment-init"|grep -v "^#"|grep -q root);then
    yq_add_map "$PLATFORM_YML" "services.deployment-init.user" "root"
fi
if ! (yq_read "$PLATFORM_YML" services.deployment-init.volumes|grep -v "^#"|grep -q '\/tmp\/ssl');then
    yq_write "$PLATFORM_YML" "services.deployment-init.volumes" "./ssl:/tmp/ssl"
fi
#
# End Keycloak components
#

#
# JAVA components
#
if ! (yq_read "$PLATFORM_YML" services.aihub-job-agent.environment|grep -v "^#"|grep -q 'RAPIDMINER_JOBAGENT_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.aihub-job-agent.environment" 'RAPIDMINER_JOBAGENT_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-job-agent.environment|grep -v "^#"|grep -q 'JOBAGENT_CONTAINER_JVM_CUSTOM_OPTIONS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.aihub-job-agent.environment" 'JOBAGENT_CONTAINER_JVM_CUSTOM_OPTIONS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-job-agent.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.aihub-job-agent.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.scoring-agent.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.scoring-agent.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.scoring-agent.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.scoring-agent.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-agent-1.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.webapi-agent-1.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-agent-1.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.webapi-agent-1.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-agent-2.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.webapi-agent-2.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-agent-2.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.webapi-agent-2.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-gateway.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.webapi-gateway.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.webapi-gateway.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.webapi-gateway.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-backend.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.aihub-backend.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-backend.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.aihub-backend.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.license-proxy.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.license-proxy.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.license-proxy.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.license-proxy.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-activemq.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.aihub-activemq.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.aihub-activemq.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.aihub-activemq.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.panopticon-vizapp.environment|grep -v "^#"|grep -q 'JAVA_OPTS=-Djavax.net.ssl.trustStore');then
    yq_write "$PLATFORM_YML" "services.panopticon-vizapp.environment" 'JAVA_OPTS=-Djavax.net.ssl.trustStore=/mnt/cacerts/cacerts\ -Djavax.net.ssl.trustStorePassword=changeit'
fi
if ! (yq_read "$PLATFORM_YML" services.panopticon-vizapp.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.panopticon-vizapp.volumes" "./ssl/java_cacerts:/mnt/cacerts"
fi
# if ! (yq_read "$PLATFORM_YML" services.radoop-proxy.volumes|grep -v "^#"|grep -q '\/ca-bunde');then
#     yq_write "$PLATFORM_YML" "services.radoop-proxy.volumes" "./ssl/rh_cacerts/ca-bundle.trust.crt:/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"
#     yq_write "$PLATFORM_YML" "services.radoop-proxy.volumes" "./ssl/rh_cacerts/ca-bundle.crt:/etc/pki/tls/certs/ca-bundle.crt"
# fi
#
# End of JAVA components
#

#
# Debian components
#
if ! (yq_read "$PLATFORM_YML" services.panopticon-vizapp.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.panopticon-vizapp.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.platform-admin.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.platform-admin.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.jupyterhub.environment|grep -v "^#"|grep -q 'REQUESTS_CA_BUNDLE');then
    yq_write "$PLATFORM_YML" "services.jupyterhub.environment" "REQUESTS_CA_BUNDLE=/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.jupyterhub.environment|grep -v "^#"|grep -q 'JUPYTERHUB_CUSTOM_CA_CERTS');then
    yq_write "$PLATFORM_YML" "services.jupyterhub.environment" 'JUPYTERHUB_CUSTOM_CA_CERTS=\${JUPYTERHUB_CUSTOM_CA_CERTS}'
fi
if ! (yq_read "$PLATFORM_YML" services.grafana-proxy.environment|grep -v "^#"|grep -q 'REQUESTS_CA_BUNDLE');then
    yq_write "$PLATFORM_YML" "services.grafana-proxy.environment" "REQUESTS_CA_BUNDLE=/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.jupyterhub.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.jupyterhub.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.grafana.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.grafana.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.grafana-proxy.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.grafana-proxy.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.landing-page.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.landing-page.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.token-tool.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.token-tool.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.panopticon-vizapp-python.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.panopticon-vizapp-python.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
if ! (yq_read "$PLATFORM_YML" services.panopticon-rserve.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.panopticon-rserve.volumes" "./ssl/deb_cacerts:/etc/ssl/certs"
fi
#
# End of Debian components
#


if grep -q -E '^WEBAPI_REGISTRY_PROTOCOL=http$' "$ENV_FILE";then
    sed -i 's/^WEBAPI_REGISTRY_PROTOCOL=http$/WEBAPI_REGISTRY_PROTOCOL=https/' "$ENV_FILE"
fi
if grep -q -E "^PUBLIC_PROTOCOL=http$" "$ENV_FILE";then
    sed -i 's/^PUBLIC_PROTOCOL=http$/PUBLIC_PROTOCOL=https/' "$ENV_FILE"
fi
if grep -q "^PUBLIC_PORT=80" "$ENV_FILE";then
    sed -i 's/^PUBLIC_PORT=80/PUBLIC_PORT=443/' "$ENV_FILE"
fi
if grep -q -E "^SSO_PUBLIC_PROTOCOL=http$" "$ENV_FILE";then
    sed -i 's/^SSO_PUBLIC_PROTOCOL=http$/SSO_PUBLIC_PROTOCOL=https/' "$ENV_FILE"
fi
if grep -q "^SSO_PUBLIC_PORT=80" "$ENV_FILE";then
    sed -i 's/^SSO_PUBLIC_PORT=80/SSO_PUBLIC_PORT=443/' "$ENV_FILE"
fi
if grep -qE "^\#\sJUPYTERHUB_CUSTOM_CA_CERTS" "$ENV_FILE";then
    sed -i "s,^\#\sJUPYTERHUB_CUSTOM_CA_CERTS.*$,JUPYTERHUB_CUSTOM_CA_CERTS=$PWD/ssl/deb_cacerts/," "$ENV_FILE"
fi

mkdir -p ssl/java_cacerts ssl/rh_cacerts ssl/deb_cacerts

echo "Fixing permissions on files"
if [ "$EUID" -eq 0 ];
then
    chown -v -R 2011:0 ssl
    chmod -v a+w .env
    chmod -v a+w ssl/
    chmod -v a+r ssl/*.crt ssl/*.key ssl/*.pem || true
else
  echo -e "

Run: 
    sudo chown -R 2011:0 ssl/
    sudo chmod a+w .env
    sudo chmod a+w ssl/
    sudo chmod a+r ssl/*.crt ssl/*.key ssl/*.pem
  "
fi
