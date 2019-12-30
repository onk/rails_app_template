#!/bin/sh
APP_NAME=costtie
EDGE=0
rm -rf "${APP_NAME}"
mkdir "${APP_NAME}"
cd ./"${APP_NAME}"

git init .

if [ "${EDGE}" = 0 ]; then
cat <<EOF > Gemfile
source "https://rubygems.org"
gem "rails"
EOF
else
cat <<EOF > Gemfile
source "https://rubygems.org"
gem "rails", github: "rails/rails"
gem "arel", github: "rails/arel"
EOF
fi

git add Gemfile
git commit -n -m "first commit"

bundle config set --local path "~/.bundle"
bundle install --jobs=4 --without=
git add -A
git commit -n -m "add rails and bundle install"

if [ "${EDGE}" = 0 ]; then
bundle exec rails new . -f -m ../costtie_template.rb --database=mysql --skip-bundle --skip-test --skip-action-cable
else
bundle exec rails new . -f -m ../costtie_template.rb --database=mysql --skip-bundle --skip-test --edge --skip-action-cable
fi

git add -A
git commit -n -m "rails webpacker:install"
