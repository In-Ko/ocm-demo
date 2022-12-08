#!/usr/bin/env zsh


# IMPORTANT NOTES for Demo:
# Script MUST be started from a empty dir via this command: "sh ../ocmDemo/ocm-flux-demo.sh"
# demoDir must be completely empty
# demoDownloadDir must be completely empty


# Prep 
. ../ocmDemo/demo-helper.sh

# Declare some constants
workDir="ocm-component"
compName="github.com/acme/podinfo"
compVersion="v1.0.0"
GH_PAT=xxx
GH_USER=In-Ko
GH_USER_LC=in-ko

# Start
clear
echo "Open Component Model Demo"
echoDescr "Prerequisites for running the demo.
- 'OCM', 'kubectl, 'git', 'kind', 'flux' CLIs."
wait

# Create new DIR for the Component. Deletes DIR if it already exists and then creates a new one.
echo " "
echoDescr "First off, we need a new directory for the OCM component."
res=$(check_dir $workDir)
  if [ $res = 0 ]; then
    rm -r $workDir
  fi
command="mkdir $workDir && tree"  
pe "$command"
wait

# create initial component archive in the new folder
echo " "
echoDescr "Switch dir and create a new component archive with the OCM CLI"
command="cd $workDir"  
pe "$command"
command="ocm create componentarchive $compName $compVersion --provider acme --type 'directory' --scheme 'v2'"
pei "$command"
wait

# check structure
echo " "
echoDescr "Now let's check the structure"
pei "tree"
wait

# Check the component descriptor
echo " "
echoDescr "Let's check the component descriptor."
command="cat component-archive/component-descriptor.yaml"
pe "$command"
wait

# add first resource: podinfo image
echo " "
echoDescr "We can add resources to the componentarchive using yaml files.
Let's use one for the podinfo docker image."
command="cat ../../ocmDemo/res/image_resource.yaml"
pe "$command"

echo " "
echo " "
command="ocm add resource ./component-archive ../../ocmDemo/res/image_resource.yaml"
pe "$command"


# OCM CLI to check if resource has been added
echo " "
echoDescr "We can use the OCM CLI to check if the resource has been added."
command="ocm get resources ./component-archive"
pe "$command"

# Check what happened in the component descriptor
echo " "
echoDescr "Let's also check what happened in the component descriptor."
command="cat component-archive/component-descriptor.yaml"
pe "$command"


# add second resource: local yaml file (deployment.yaml)
# Check out the deployment.yaml
echo " "
echoDescr "Now let's add another resource.\n
This time a local YAML file, which looks like this:"
command="cat ../../ocmDemo/res/deployment.yaml"
pe "$command"

# check the corresponding resource file
echo " "
echo " "
echoDescr "This is how the corresponding resource file looks like:"
command="cat ../../ocmDemo/res/deployment_resource.yaml"
pe "$command"

echo " "
echo " "
command="ocm add resource ./component-archive ../../ocmDemo/res/deployment_resource.yaml"
pe "$command"

# OCM CLI to check if resource has been added
echo " "
echoDescr "We can use the OCM CLI to check if the resource has been added."
command="ocm get resources ./component-archive"
pe "$command"

# Check what happened in the component descriptor
echo " "
echoDescr "Let's also check what happened in the component descriptor."
command="cat component-archive/component-descriptor.yaml"
pe "$command"

# And check again the whole structure
echo " "
echoDescr "The whole component archive now looks like this:"
command="tree"
pe "$command"

# Checking the blob
echo " "
echoDescr "Just to be sure: Let's look at the blob and check if it's really the deployment.yaml:"
#file=$(ls ./component-archive/blobs/*"sha"* | head -n 1)
command='cat ./component-archive/blobs/sha256* | gzip -d'
pe "$command"

# Create a new rsakeypair
echo " "
echoDescr "As we want to sign our component, let's create a new RSA Key Pair.\n
The key pair will be created in the working directory.\n
Note that we could also bring an existing key."
command="ocm create rsakeypair"
pe "$command"

# Sign the component
echo " "
echoDescr "Use the generated RSA Key to sing the component."
command="ocm sign component --signature inko --private-key rsa.priv --public-key rsa.pub ./component-archive"
pe "$command"

# Check what happened in the component descriptor
echo " "
echoDescr "Let's also check again what happened in the component descriptor."
command="cat component-archive/component-descriptor.yaml"
pe "$command"

# Verify the signature
echo " "
echoDescr "Verify the component, using the public key."
command="ocm verify component -s inko -k rsa.pub ./component-archive"
pe "$command"


# Upload component to ghcr package registry
# Background Commands:
# Docker Login to my personal github account, we will use the package registry of that
echo " "
echoDescr "Upload component to GitHub Package Registry. Login via docker CLI (this login info used then by OCM)."
wait
echo " "
echo $GH_PAT | docker login ghcr.io -u $GH_USER --password-stdin
command="ocm transfer component ./component-archive ghcr.io/$GH_USER_LC"
pe "$command"


# Verify the signature of remote component
echo " "
echoDescr "Verify the component from the remote location."
command="ocm verify component -s inko -k rsa.pub --repo ghcr.io/$GH_USER_LC github.com/acme/podinfo"
pe "$command"

echo " "
echoDescr "This concludes the OCM CLI demo."
echo " "
echo " "

# Command to download the DIR of the Component, cCreates a directory structure with the component
# echo " "
# echoDescr "And let's try to download the component again as a directory structure"
# cd ..
# cd ..
# wait
# cd demoDownloadDir
# wait
# command="ocm download componentversion ghcr.io/$GH_USER_LC//github.com/acme/podinfo:$compVersion --type directory"
# pe "$command"
