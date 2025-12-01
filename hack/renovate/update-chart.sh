#!/bin/bash
# hack/renovate/update-chart.sh

set -e

CHART_DIR="$1"
DEP_NAME="$2"
NEW_VERSION="$3"
UPDATE_TYPE="$4"        # major, minor, or patch
IS_SECURITY="${5:-false}"  # true or false

if [ -z "$CHART_DIR" ] || [ -z "$DEP_NAME" ] || [ -z "$NEW_VERSION" ] || [ -z "$UPDATE_TYPE" ]; then
  echo "Usage: $0 <chart_dir> <dep_name> <new_version> <update_type> [is_security]"
  exit 1
fi

cd "$CHART_DIR"

CURRENT_VERSION=$(yq e '.version' Chart.yaml)
if [ "$UPDATE_TYPE" = "major" ]; then
  NEW_CHART_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{print $1"."$2+1".0"}')
else
  NEW_CHART_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{print $1"."$2"."$3+1}')
fi

yq e ".version = \"$NEW_CHART_VERSION\"" -i Chart.yaml

KIND=changed

if [ "$IS_SECURITY" = "true" ]; then
  yq e ".annotations.\"artifacthub.io/containsSecurityUpdates\" = \"true\"" -i Chart.yaml
else
  yq e ".annotations.\"artifacthub.io/containsSecurityUpdates\" = \"false\"" -i Chart.yaml
fi

CHANGELOG="- kind: $KIND
  description: |
    chore: update $DEP_NAME to $NEW_VERSION"

yq e ".annotations.\"artifacthub.io/changes\" = \"$CHANGELOG\"" -i Chart.yaml

echo "Updated Chart.yaml: $CURRENT_VERSION -> $NEW_CHART_VERSION (update_type: $UPDATE_TYPE, security: $IS_SECURITY)"
