#!/usr/bin/env bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
#
# source: https://github.com/docker-library/mysql/blob/master/5.7/docker-entrypoint.sh#L21
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# automatically try load all env vars ending in _FILE to be a secret
for i in $(printenv)
do
    if [[ $i == *"_FILE"* ]]; then
    varName="$(echo $i | cut -d'=' -f1)"

   # replace last _FILE with nothing
    empty=''
    new=$(echo $varName | sed  "s/_FILE$/$empty/g")

    file_env $new
fi
done
exit

role=${CONTAINER_ROLE:-cli}
env=${APP_ENV}
migrate=${RUN_MIGRATIONS:-false}
seed=${SEED_DB:-false}

echo run using variables:
echo role=$role
echo env=$env
echo migrate=$migrate
echo seed=$seed

if [ "$migrate" == true ]; then
    if [ "$seed" == true ]; then
        echo "running migrations and seed db"
        (cd /code && php artisan migrate --force --seed)
    else
        echo "running migrations"
        (cd /code && php artisan migrate --force)
    fi
fi

if [ "$env" == "production" ]; then

    # https://github.com/blacklabelops/confluence/blob/master/docker-entrypoint.sh#L261
    source /usr/local/bin/dockerwait

    echo "Caching configuration..."
    export PHP_OPCACHE_ENABLE=1

    (cd /code && php artisan config:cache && php artisan route:cache && php artisan view:cache)
fi

if [ "$role" = "app" ]; then

    # starts nginx and php-fpm
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