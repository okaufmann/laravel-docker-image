#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-cli}
env=${APP_ENV}
migrate=${RUN_MIGRATIONS:-false}
seed=${SEED_DB:-false}
cache_routes=${CACHE_ROUTES:-true}
user=$(whoami)

echo "run using variables:"
echo "role=$role"
echo "env=$env"
echo "migrate=$migrate"
echo "seed=$seed"
echo "cache_routes=$cache_routes"
echo "current user=$user"
php -v

ls -la /code

echo "link storage"
php /code/artisan storage:link

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
    exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

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