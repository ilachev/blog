up: docker-up
down: docker-down
restart: docker-down docker-up
init: docker-down-clear blog-clear docker-pull docker-build docker-up blog-init
test: blog-test
test-coverage: blog-test-coverage
test-unit: blog-test-unit
test-unit-coverage: blog-test-unit-coverage

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull

docker-build:
	docker-compose build

blog-init: blog-composer-install blog-assets-install blog-oauth-keys blog-wait-db blog-migrations blog-fixtures blog-ready

blog-clear:
	docker run --rm -v ${PWD}/blog:/app --workdir=/app alpine rm -f .ready

blog-composer-install:
	docker-compose run --rm blog-php-cli composer install

blog-assets-install:
	docker-compose run --rm blog-node yarn install
	docker-compose run --rm blog-node npm rebuild node-sass

blog-oauth-keys:
	docker-compose run --rm blog-php-cli mkdir -p var/oauth
	docker-compose run --rm blog-php-cli openssl genrsa -out var/oauth/private.key 2048
	docker-compose run --rm blog-php-cli openssl rsa -in var/oauth/private.key -pubout -out var/oauth/public.key
	docker-compose run --rm blog-php-cli chmod 644 var/oauth/private.key var/oauth/public.key

blog-wait-db:
	until docker-compose exec -T blog-postgres pg_isready --timeout=0 --dbname=app ; do sleep 1 ; done

blog-migrations:
	docker-compose run --rm blog-php-cli php bin/console doctrine:migrations:migrate --no-interaction

blog-fixtures:
	docker-compose run --rm blog-php-cli php bin/console doctrine:fixtures:load --no-interaction

blog-ready:
	docker run --rm -v ${PWD}/blog:/app --workdir=/app alpine touch .ready

blog-assets-dev:
	docker-compose run --rm blog-node npm run dev

blog-test:
	docker-compose run --rm blog-php-cli php bin/phpunit

blog-test-coverage:
	docker-compose run --rm blog-php-cli php bin/phpunit --coverage-clover var/clover.xml --coverage-html var/coverage

blog-test-unit:
	docker-compose run --rm blog-php-cli php bin/phpunit --testsuite=unit

blog-test-unit-coverage:
	docker-compose run --rm blog-php-cli php bin/phpunit --testsuite=unit --coverage-clover var/clover.xml --coverage-html var/coverage