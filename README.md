# SonarQube OSS on OpenShift

***Current version SonarQube 7.7 OSS, tested on OpenShift 3.11***

This repository contains the needed files to build and deploy SonarQube OSS on OpenShift.  There are simple ways to integrate into LDAP as well for a centralized SonarQube deployment.  You may also find the image on Docker Hub.

## Prerequisites

PostgreSQL is deployed as a DeploymentConfig and requires access to a PersistentVolume for its backing storage.

## Container Image Additions

The container, found at [https://hub.docker.com/r/kenmoini/openshift-sonarqube](https://hub.docker.com/r/kenmoini/openshift-sonarqube) has some additional bits stuffed into the image.

### Included Plugins

The [PMD](https://pmd.github.io/), GitHub, and GitLab plugins are included with the container image.  LDAP is a mainline plugin provided by Sonarsource.  These are pulled in via the ```plugins.sh``` file being run when the Docker image is created.  Upon updating the base container image, it is likely that you will also need to update versioning in this file.

### LDAP and Self-Signed Certificates

JavaX doesn't accept self-signed certificates when using LDAPS connectivity.  In order to get past this for normal LDAP deployments, you must import the certificates into the JRE keystore.

To do this, there is a script, ```ss-ca-puller.sh```, that will loop through a list of hosts, connect and retrieve their SSL certificate, then add it to the JRE keystore.

To add your own self-signed SSL certificates to the keystore you will need to modify the domain list in this Dockerfile and build the Docker image yourself - I do so everytime I use this for a workshop because the LDAP/RH IDM server is ephemeral and certificates change from workshop to workshop.  Step-by-step instructions are below.

## Deployment - Automated

The deployment script ```./deploy.sh``` can also take preset environmental variables to provision without prompting the user.  To do so, copy over the ```example.vars.sh``` file, set the variables, source and run the deployer.

```bash
$ cp example.vars.sh vars.sh
$ vim vars.sh
$ source ./vars.sh && ./deployer.sh
```

## Deployment - Interactive

There's a simple deployment script that can either prompt a user for variables or take them set in the Bash script.  As long as you have an OpenShift Cluster then you can simply run:

```bash
$ ./deployer.sh
```

And answer the prompts to deploy SonarQube on OpenShift.

## Deployment - Manual

Create a new project

```bash
$ oc new-project cicd-sonarqube
```

Process the SonarQube Template, either Persistent or Ephemeral, with the option of Edge TLS secured Routes:

```bash
$ oc process -f sonarqube-template.yml | oc apply -f- # Ephemeral
$ oc process -f sonarqube-template-secure.yml | oc apply -f- # Ephemeral with SSL
$ oc process -f sonarqube-persistent-template.yml | oc apply -f- # Persistent
$ oc process -f sonarqube-persistent-template-secure.yml | oc apply -f- # Persistent with SSL
```

Deploying via the Automated or Interactive steps is preferred (read: easier), or by importing the YAML via the Web GUI as there are a number of configuration parameters available.

## LDAP Configuration

By default, LDAP is disabled and only the default Administrator is active - credentials are admin/admin.  Highly suggest you change that.

LDAP is configured when deploying the SonarQube Template.  Most parameters are configured with default values to work with Red Hat Identity Management (LDAP) and only need specifically setting the following:

- **SONAR_AUTH_REALM / SonarQube Authentication Realm** - Set to LDAP (case matters...gotta be caps...)
- **SONAR_LDAP_BIND_PASSWORD / LDAP Bind Password**
- **SONAR_LDAP_URL / LDAP Server URL**
- **SONAR_LDAP_REALM / LDAP Realm**
- **SONAR_LDAP_USER_BASEDN / LDAP User Base DN** - Mostly just replace with your realm at the dc= definitions
- **SONAR_LDAP_GROUP_BASEDN / LDAP Group Base DN** - Also just replace your realm where the dc= definitions are

Setting LDAP after SonarQube is deployed is not very easy to do as it requires setting files...well, I guess a ConfigMap would do it pretty easily, yeah...

## LDAP and Self-Signed SSL CA Certificates

Odds are your IDM/LDAP server generated a new Certificate Authority and chain which is self-signed.  The Java Runtime Environment (JRE) that SonarQube uses will not recognize your self-signed certificate and fail to connect to LDAPS.

In order to add your self-signed certificate from your IDM/LDAP server you must do the following:

1. Fork this repository
2. Modify the ```Dockerfile``` where noted to, replacing the url:port with that of your own IDM/LDAP server
3. Connect your repository to Docker Hub, build a container image using your forked repo
4. Modify the OpenShift manifests (eg the *sonarqube-\*template.yml* files, line 19) to point to your image from Docker Hub
5. Deploy SonarQube with the LDAP configuration parameters listed above