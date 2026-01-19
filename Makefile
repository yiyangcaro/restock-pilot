.PHONY: up down logs psql migrate

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

psql:
	PGPASSWORD=rp psql -h localhost -p 5432 -U rp -d restock_pilot

migrate:
	./scripts/migrate.sh
