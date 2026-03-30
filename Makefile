SHELL := /bin/bash

FRONTEND_DIR := frontend

.PHONY: dev dev-down api worker fmt lint type test migrate openapi openapi-validate llm-smoke fe-web fe-web-server fe-build-web fe-analyze

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

openapi-validate:
	python -c "import json; d=json.load(open('openapi.json','r',encoding='utf-8')); assert isinstance(d.get('openapi'),str); assert '/v1/auth/login' in d.get('paths',{}); print('openapi validate ok')"

llm-smoke:
	@resp=$$(curl -sS -X POST "$${API_BASE:-http://127.0.0.1:8000}/v1/system/llm/smoke" \
		-H "Content-Type: application/json" \
		-d "{\"prompt\":\"$${PROMPT:-请回复：连接测试成功}\"}" || true); \
	if [ -z "$$resp" ]; then \
		echo "llm-smoke failed: cannot reach API at $${API_BASE:-http://127.0.0.1:8000}"; \
		exit 1; \
	fi; \
	echo "$$resp" | python -m json.tool 2>/dev/null || echo "$$resp"

fe-web:
	cd $(FRONTEND_DIR) && flutter run -d chrome --no-web-resources-cdn

fe-web-server:
	cd $(FRONTEND_DIR) && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787 --no-web-resources-cdn

fe-build-web:
	cd $(FRONTEND_DIR) && flutter build web --no-web-resources-cdn

fe-analyze:
	cd $(FRONTEND_DIR) && flutter analyze
