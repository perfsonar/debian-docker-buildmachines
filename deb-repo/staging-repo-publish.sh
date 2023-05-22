#!/usr/bin/env bash
# This script publishes the packages build locally to the remote public repository
# It is meant to be run after new packages have been built

## reprepro defaults
export REPREPRO_BASE_DIR=/var/local/repo
REPO_SERVER=perfsonar-repo.geant.org

## Get repositories content
set +x
uptime
uname -a

echo "Local repositories are in $REPREPRO_BASE_DIR here is their current content"
ls -la $REPREPRO_BASE_DIR
ls -la $REPREPRO_BASE_DIR/dists

for DIST in 5.0; do
    for RELEASE in staging snapshot; do
        echo
        # Check the current content of the repository
        REPO="perfsonar-${DIST}-${RELEASE}"
        echo "Listing content of the local repository ${REPO}"
        reprepro list ${REPO}
        echo -n "Total number of packages in ${REPO}: "
        reprepro list ${REPO} | wc -l
        echo "––––––––––––––––––––––––––––––"
    done
done

echo
echo "Push the repository to the public repo server, in a staging space, deleting extraneous files"
rsync -av --delete $REPREPRO_BASE_DIR/ jenkins@ps-deb-repo.qalab.geant.net:/var/www/html/repo-from-d10/
rsync -av --delete $REPREPRO_BASE_DIR/ jenkins@{REPO_SERVER}:/var/www/html/repo-from-d10/
# Update the staging repo description page
ssh jenkins@ps-deb-repo.qalab.geant.net "~/deb-repo-info.pl -repo /var/www/html/repo-from-d10 -html > /var/www/html/repo-from-d10/index.html"
ssh jenkins@${REPO_SERVER} "~/deb-repo-info.pl -repo /var/www/html/repo-from-d10 -html > /var/www/html/repo-from-d10/index.html"
echo
echo "Copy new packages into the final public repository (snapshot and staging only) and update the description page"
OUT=`ssh jenkins@{REPO_SERVER} "reprepro --waitforlock 12 -b /var/www/html/debian update perfsonar-5.0-snapshot perfsonar-5.0-staging" 2>&1`
OUT=`ssh jenkins@ps-deb-repo.qalab.geant.net "reprepro --waitforlock 12 -b /var/www/html/debian update perfsonar-5.0-snapshot perfsonar-5.0-staging" 2>&1`
if [ ! $? -eq 0 ]; then
    echo
    echo "$OUT"
    echo "The main repository didn't want to take in the new snapshot and staging packages.  Update failed!"
    exit 1
fi
echo
echo "$OUT"
ssh jenkins@{REPO_SERVER} "~/deb-repo-info.pl -repo /var/www/html/debian -html > /var/www/html/debian/index.html"
ssh jenkins@ps-deb-repo.qalab.geant.net "~/deb-repo-info.pl -repo /var/www/html/debian -html > /var/www/html/debian/index.html"

# GÉANT repoo testing instance, should be removed when moving into production
#for server in test
#for server in test uat
#    do
#    echo
#    echo "Publish to the mirror of downloads.perfsonar.net public host (${server}-pspackages.geant.net)"
#    ssh jenkins@ps-deb-repo.qalab.geant.net "rsync -av --delete /var/www/html/debian/ psrepo@${server}-pspackages.geant.net:/var/www/html/debian/"
#done

