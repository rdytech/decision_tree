#!/bin/bash
set -e

echo '--- setting ruby version'
rbenv install -s 2.2.2
rbenv local 2.2.2
rbenv rehash
gem install bundler --no-rdoc --no-ri

echo '--- bundling'
bundle install -j $(nproc) --without production --quiet

echo '--- running specs'
REVISION=https://github.com/$BUILDBOX_PROJECT_SLUG/commit/$BUILDBOX_COMMIT
if bundle exec rake spec; then
  echo "[Successful] $BUILDBOX_PROJECT_SLUG - Build - $BUILDBOX_BUILD_URL - Commit - $REVISION" | hipchat_room_message -t $HIPCHAT_TOKEN -r $HIPCHAT_ROOM -f "Buildbox" -c "green"
else
  echo "[Failed] Build $BUILDBOX_PROJECT_SLUG - Build - $BUILDBOX_BUILD_URL - Commit - $REVISION" | hipchat_room_message -t $HIPCHAT_TOKEN -r $HIPCHAT_ROOM -f "Buildbox" -c "red"
  exit 1;
fi
