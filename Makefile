SHELL := /bin/bash

FRONTEND_DIR := frontend

.PHONY: dev dev-down api worker fmt lint type test migrate openapi fe-web fe-web-server fe-build-web fe-analyze

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

fe-web:
	cd $(FRONTEND_DIR) && flutter run -d chrome --no-web-resources-cdn

fe-web-server:
	cd $(FRONTEND_DIR) && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787 --no-web-resources-cdn

fe-build-web:
	cd $(FRONTEND_DIR) && flutter build web --no-web-resources-cdn

fe-analyze:
	cd $(FRONTEND_DIR) && flutter analyze
