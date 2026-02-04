SHELL := /bin/bash

.PHONY: dev dev-down api worker fmt lint type test migrate openapi

dev:
	docker compose up -d --build

dev-down:
	docker compose down -v

api:
	uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000

worker:
	rq worker -u $${REDIS_URL:-redis://localhost:6379/0} default

fmt:
	ruff check --fix backend || true
	black backend
	isort backend

lint:
	ruff check backend

type:
	mypy backend

test:
	pytest -q

migrate:
	alembic -c backend/alembic.ini upgrade head

openapi:
	python -c "import json; from backend.app.main import app; print(json.dumps(app.openapi(), indent=2))" > openapi.json

