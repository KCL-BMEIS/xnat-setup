#!/usr/bin/env bash

# urghhh.... changed to github some of the repos
bitbucket_repo="https://api.bitbucket.org/2.0/repositories"
github_repo="https://github.com/NrgXnat"
linux_dir=$(dirname "$0")
cd "$linux_dir"
cd ..
install_dir=$(pwd)
source "$install_dir/xnat.cfg"
newline=$'\n'
warning_messages="################### Warning messages: $newline"

cd "$install_dir/plugins"

download_jar() {
  local url="$1"
  local cleanup_pattern="$2"
  local out="$3"
  local label="$4"
  local tmp

  rm -f ./*"$cleanup_pattern"*
  tmp="$(mktemp)"

  if curl -f -L -A "Mozilla/5.0" \
      --header "Referer: ${bitbucket_repo}" \
      -o "$tmp" \
      "$url" \
      && file "$tmp" | grep -qiE 'Zip archive data|Java archive' \
      && unzip -t "$tmp" >/dev/null 2>&1
  then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"
    echo "error"
    warning_messages="${warning_messages} warning: could not download ${label}:${newline}   ${url}${newline}"
    return 1
  fi
}

if [ "$batch_launch" = true ]; then
  download_jar \
    "${bitbucket_repo}/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-${batch_launch_version}-xpl.jar" \
    "batch-launc" \
    "batch-launch-${batch_launch_version}.jar" \
    "batch launch plugin"
fi

if [ "$container_service" = true ]; then
  download_jar \
  "${github_repo}/container-service/releases/download/${container_service_version}/container-service-${container_service_version}-fat.jar" \
    "container-ser" \
    "container-service-${container_service_version}-fat.jar" \
    "container service plugin"
fi

if [ "$dqr" = true ]; then
  #https://github.com/NrgXnat/dicom-query-retrieve/releases/download/3.1.0/dicom-query-retrieve-3.1.0-xpl.jar
  #    "${bitbucket_repo}/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-${dqr_version}-xpl.jar" \
  download_jar \
      "${github_repo}/dicom-query-retrieve/releases/download/${dqr_version}/dicom-query-retrieve-${dqr_version}-xpl.jar" \
    "dicom-query-retrieve" \
    "dicom-query-retrieve-${dqr_version}-xpl.jar" \
    "dqr plugin"
fi

if [ "$xsync" = true ]; then
  download_jar \
    "${bitbucket_repo}/xnatdev/xsync/downloads/xsync-plugin-all-${xsync_version}.jar" \
    "xsync" \
    "xsync-plugin-all-${xsync_version}.jar" \
    "xsync plugin"
fi

if [ "$ldap" = true ]; then
  download_jar \
    "${bitbucket_repo}/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-${ldap_version}.jar" \
    "ldap-auth" \
    "ldap-auth-plugin-${ldap_version}.jar" \
    "ldap plugin"
fi

if [ "$ohif_viewer" = true ]; then
  download_jar \
    "https://xnat.org/files/ohif-viewer-xnat-plugin/ohif-viewer-${ohif_viewer_version}-fat.jar" \
    "ohif-viewer" \
    "ohif-viewer-${ohif_viewer_version}.jar" \
    "ohif viewer plugin"
fi

if [ "$jupyter" = true ]; then
  download_jar \
    "${github_repo}/xnat-jupyterhub-plugin/releases/download/v${jupyter_version}/xnat-jupyterhub-plugin-${jupyter_version}.jar" \
    "jupyter" \
    "xnat-jupyterhub-plugin-${jupyter_version}.jar" \
    "jupyterhub plugin"
fi

echo "$warning_messages"

cd "$linux_dir"