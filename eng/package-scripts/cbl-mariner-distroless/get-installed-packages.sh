#!/usr/bin/env sh

# Custom script to get the installed packages for the distroless version of CBL-Mariner.
# This script is tied to the implementation of the distroless CBL-Mariner Dockerfiles.

version=$1
imageTag=$2
dockerfilePath=$3

scriptDir="$(dirname $(realpath $0))"
commonPackageScriptsDir="$scriptDir/../../common/package-scripts"

# This script relies on the staging location of the packages that is generated by the
# runtime-deps Dockerfile. The runtime and aspnet Dockerfiles do not install additional package and thus
# do not have have their own staging location. Because of this, it's not possible to query for the packages
# that exist for the runtime and aspnet Dockerfiles. But since they don't install their own packages, the
# runtime-deps Dockerfile can be used instead to query for the packages that are installed. So regardless of
# which Dockerfile is used, the runtime-deps Dockerfile is used to query for the packages that are installed.
# To always target the runtime-deps Dockerfile, "runtime" and "aspnet" are simply replaced with "runtime-deps".
dockerfilePath="$(echo $dockerfilePath | sed 's/\/runtime\//\/runtime-deps\//g')"
dockerfilePath="$(echo $dockerfilePath | sed 's/\/aspnet\//\/runtime-deps\//g')"

# Build the Dockerfile of the image targeting the installer stage. This relies on the fact that
# the Dockerfile has already been built and cached. This just rebuilds, utilitizing the cache, and
# provides a tag to the installer stage. The installer stage is used here because it provides the
# full version of CBL-Mariner with a shell that can be used to query the package contents of the
# staging location.
installerImageTag="tag-$RANDOM"
buildContextDir="$(dirname $dockerfilePath)"

docker build --target installer -f $dockerfilePath -t $installerImageTag $buildContextDir 1>/dev/null 2>/dev/null

# Get the installed packages using custom package manager args to query the staging location
customPkgManagerArgs="--releasever=$version --installroot /staging"
$commonPackageScriptsDir/get-installed-packages.sh -a "$customPkgManagerArgs" $installerImageTag $dockerfilePath
