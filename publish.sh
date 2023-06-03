#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
TEMPDIR="$(mktemp  -d -t tuweni-site-XXXXXXX)"
cd $TEMPDIR
git clone git@github.com:tmio/tuweni-website.git master-branch
git clone --branch asf-site git@github.com:tmio/tuweni-website.git asf-site-branch
git clone https://github.com/tmio/tuweni.git code

#
# Testing:
#
echo "CHANGE_ID -${CHANGE_ID}-"
echo "CHANGE_URL -${CHANGE_URL}-"
echo "BRANCH_NAME -${BRANCH_NAME}-"
echo "GIT_COMMIT -${GIT_COMMIT}-"
echo "GIT_PREVIOUS_COMMIT -${GIT_PREVIOUS_COMMIT}-"

if [ "X${GIT_COMMIT}" = "X${GIT_PREVIOUS_COMMIT}" ]; then
	echo "Commit ${GIT_COMMIT} equal to previous commit ${GIT_PREVIOUS_COMMIT}: we are done"
#    exit 0
fi

#
# Install RVM if needed
#
curl -sSL https://get.rvm.io | bash -s stable
source "$HOME/.rvm/scripts/rvm"
rvm install 2.7.0
rvm use 2.7.0

#
# Run the jekyll script to generate HTML for tuweni.apache.org
#
cd master-branch
echo "Building site..."
gem install bundler -v 1.16.2
bundle install && bundle exec jekyll build
if [ $? -ne 0 ]; then
	echo "Build failed!"
    exit 1
fi
cd ..

#
# Copy the generated html to the asf-site branch
#
cd asf-site-branch
git checkout asf-site
git fetch origin asf-site
git pull origin asf-site

cp -R ../master-branch/target/* .
cd ..

#
# Generate javadocs
#
cd code
gradle setup
./gradlew dokkaHtml
mkdir -p ../asf-site-branch/docs
cp build/docs/style.css ../asf-site-branch/style.css
cp -R build/docs/tuweni/* ../asf-site-branch/docs
cd ..
cd asf-site-branch

#
# Copy favicon to default location
#
cp assets/themes/apache/img/tuweni_face.ico favicon.ico


#
# Commit and push to github
#
echo "Adding content..."
git add -v .
echo "Commit"
git status

git commit -v -m "Publishing website changes"
if [ $? -ne 0 ]; then
    echo "Commit failed."
    exit 2
fi
echo "Pushing to github..."
git push -v origin asf-site
if [ $? -ne 0 ]; then
    echo "Push failed."
    exit 3
fi
rm -Rf $TEMPDIR
echo "Done."



