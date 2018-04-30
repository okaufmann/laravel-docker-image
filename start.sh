#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}
migrate=${RUN_MIGRATIONS:-false}

if [ "$env" != "local" ]; then

    # https://github.com/blacklabelops/confluence/blob/master/docker-entrypoint.sh#L261
    source /usr/local/bin/dockerwait

    echo "Caching configuration..."
    export PHP_OPCACHE_ENABLE=1

    (cd /code && php artisan config:cache && php artisan route:cache && php artisan view:cache)
fi

if [ "$migrate" == "true" ]; then
    echo "running migrations"
    (cd /code && php artisan migrate --force)
fi

if [ "$role" = "app" ]; then

    exec php-fpm

elif [ "$role" = "cli" ]; then

    exec "$@"

elif [ "$role" = "queue" ]; then

    echo "Running the queue..."
    php /code/artisan horizon

elif [ "$role" = "scheduler" ]; then

    echo "Starting scheduler"
    while [ true ]
    do
      php /code/artisan schedule:run --verbose --no-interaction &
      sleep 60
    done

else
    echo "Could not match the container role \"$role\""
    exit 1
fi