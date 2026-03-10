.PHONY: up down new migrate rollback status dump lint lint-fix docs

DATABASE_URL := mysql://app_user:app_pass@127.0.0.1:3306/app_db

up:
	docker compose up -d mysql
	docker compose run --rm dbmate wait
	docker compose run --rm dbmate up

down:
	docker compose down -v

new:
	@if [ -z "$(NAME)" ]; then echo "Usage: make new NAME=create_xxx_table"; exit 1; fi
	docker compose run --rm dbmate new $(NAME)

migrate:
	docker compose run --rm dbmate up

rollback:
	docker compose run --rm dbmate rollback

status:
	docker compose run --rm dbmate status

dump:
	docker compose run --rm dbmate dump

lint:
	docker run --rm -v $(PWD)/db/migrations:/sql sqlfluff/sqlfluff:3.3.0 lint /sql

lint-fix:
	docker run --rm -v $(PWD)/db/migrations:/sql sqlfluff/sqlfluff:3.3.0 fix /sql

docs:
	docker run --rm \
		--network host \
		-v $(PWD)/.tbls.yml:/work/.tbls.yml \
		-v $(PWD)/docs/schema:/work/docs/schema \
		ghcr.io/k1low/tbls:latest doc --force
