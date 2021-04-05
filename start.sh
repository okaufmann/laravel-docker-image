#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-cli}
container_debug=${CONTAINER_DEBUG:-false}
env=${APP_ENV}
migrate=${RUN_MIGRATIONS:-false}
seed=${SEED_DB:-false}
cache_routes=${CACHE_ROUTES:-true}
link_storage=${LINK_STORAGE:-false}
user=$(whoami)

echo "run using variables:"
echo "role=$role"
echo "container_debug=$container_debug"
echo "env=$env"
echo "migrate=$migrate"
echo "seed=$seed"
echo "cache_routes=$cache_routes"
echo "link_storage=$link_storage"
echo "current user=$user"

if [ "$container_debug" == true ]; then
    php -v
    php -m
    ls -la /code
fi

if [ "$link_storage" == true ]; then
    echo "link storage"
    php /code/artisan storage:link
fi

if [ "$migrate" == true ]; then
    if [ "$seed" == true ]; then
        echo "running migrations and seed db"
        (cd /code && php artisan migrate --force --seed)
    else
        echo "running migrations"
        (cd /code && php artisan migrate --force)
    fi
fi

if [ "$role" = "app" ]; then
    if [ "$env" == "production" ]; then

        echo "Caching configuration..."
        export PHP_OPCACHE_ENABLE=1

        if [ "$cache_routes" == true ]; then
            (cd /code && php artisan route:cache)
        fi

        (cd /code && php artisan config:cache && php artisan view:cache)
    fi

    # starts nginx and php-fpm
    exec /usr/bin/supervisord -n -c /etc/supervisor/app.conf

    elif [ "$role" = "cli" ]; then

    exec "$@"

    elif [ "$role" = "queue" ]; then

    echo "Running the queue..."
    exec /usr/bin/supervisord -n -c /etc/supervisor/queue.conf

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