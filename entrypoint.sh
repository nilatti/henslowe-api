#!/bin/sh
set -e
if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

bundle exec rake db:migrate RAILS_ENV=production
exec bundle exec "$@"