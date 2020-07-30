#!/usr/bin/env bash

# default the variables if not set
DEBUG=${DEBUG:="false"}
SOURCE=${SOURCE:="unknown"}
DYNATRACE_MONITORING=${DYNATRACE_MONITORING:="true"}
KEPTN_VERSION=${KEPTN_VERSION:="0.7.0"}
KEPTN_DISTR="linux"

# optinal values with no defaults
# DYNATRACE_SLI_FILE  
# JMETER_FILE

# Required parameters
KEPTN_URL=${KEPTN_URL:?'KEPTN_URL ENV variable missing.'}
KEPTN_TOKEN=${KEPTN_TOKEN:?'KEPTN_TOKEN ENV variable missing.'}
PROJECT=${PROJECT:?'PROJECT ENV variable missing.'}
SERVICE=${SERVICE:?'SERVICE ENV variable missing.'}
STAGE=${STAGE:?'STAGE ENV variable missing.'}
SHIPYARD_FILE=${SHIPYARD_FILE:?'SLO_FILE ENV variable missing'}
SLO_FILE=${SLO_FILE:?'SLO_FILE ENV variable missing'}

# validate inputs
if [ "${KEPTN_URL: -4}" != "/api" ]; then
  echo "Aborting: KEPTN_URL must end with /api"
  exit 1
fi

if [ ! -f "$SHIPYARD_FILE" ]; then
    echo "Aborting: $SHIPYARD_FILE does not exist."
    exit 1
fi
if [ ! -f "$SLO_FILE" ]; then
    echo "Aborting: $SLO_FILE does not exist."
    exit 1
fi

if [ "$DYNATRACE_MONITORING" == "true" ]; then
  if [ ! -f "$DYNATRACE_SLI_FILE" ]; then
      echo "Aborting: $DYNATRACE_SLI_FILE does not exist."
      exit 1
  fi
fi

echo "================================================================="
echo "Keptn Prepare Project"
echo ""
echo "KEPTN_URL            = $KEPTN_URL"
echo "PROJECT              = $PROJECT"
echo "SERVICE              = $SERVICE"
echo "STAGE                = $STAGE"
echo "SOURCE               = $SOURCE"
echo "SHIPYARD_FILE        = $SHIPYARD_FILE"
echo "SLO_FILE             = $SLO_FILE"
echo "DYNATRACE_MONITORING = $DYNATRACE_MONITORING"
echo "DYNATRACE_SLI_FILE   = $DYNATRACE_SLI_FILE"
echo "JMETER_FILE          = $JMETER_FILE"
echo "DEBUG                = $DEBUG"
echo "================================================================="

echo "Downloading keptn $KEPTN_VERSION for $KEPTN_DISTR from GitHub..."
curl -s -L "https://github.com/keptn/keptn/releases/download/${KEPTN_VERSION}/${KEPTN_VERSION}_keptn-${KEPTN_DISTR}.tar" --output keptn-install-${KEPTN_VERSION}.tar
tar -C /tmp -xvf keptn-install-${KEPTN_VERSION}.tar
rm keptn-install-${KEPTN_VERSION}.tar
echo "Moving keptn binary to /usr/local/bin/keptn"
chmod +x /tmp/keptn
mv /tmp/keptn /usr/local/bin/keptn
keptn version

# authorize keptn cli
keptn auth --api-token "$KEPTN_TOKEN" --endpoint "$KEPTN_URL"
if [ $? -ne 0 ]; then
    echo "Aborting: Failed to authenticate Keptn CLI"
    exit 1
fi

# onboard project
if [ $(keptn get project $PROJECT | wc -l) -ne 2 ]; then
  keptn create project $PROJECT --shipyard=$SHIPYARD_FILE
else
  echo "Project $PROJECT already onboarded. Skipping create project"
fi

# onboard service
if [ $(keptn get service $SERVICE --project $PROJECT | wc -l) -ne 2 ]; then
  keptn create service $SERVICE --project=$PROJECT
else
  echo "Service $SERVICE already onboarded. Skipping create service"
fi

# configure Dynatrace monitoring
if [ "$DYNATRACE_MONITORING" == "true" ]; then
  keptn configure monitoring dynatrace --project=$PROJECT
  keptn add-resource --project=$PROJECT --stage=$STAGE --service=$SERVICE --resource=$DYNATRACE_SLI_FILE --resourceUri=dynatrace/sli.yaml
fi

# always add SLO resources
keptn add-resource --project=$PROJECT --stage=$STAGE --service=$SERVICE --resource=$SLO_FILE --resourceUri=slo.yaml

echo "================================================================="
echo "Completed Keptn Prepare Project"
echo "================================================================="
