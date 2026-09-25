.PHONY: help setup dev backend admin build lint test api-generate

help: ## Muestra los objetivos disponibles
	@printf "Uso: make <objetivo>\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

setup: ## Instala dependencias de backend y panel admin (una sola vez)
	@echo "==> Restaurando dependencias de .NET..."
	dotnet restore backend/src/QuickBite.sln
	@echo "==> Instalando dependencias del panel admin (npm)..."
	cd admin && npm install
	@if [ ! -f admin/.env ]; then cp admin/.env.example admin/.env && echo "==> .env creado a partir de .env.example"; fi

backend: ## Arranca solo la API REST .NET
	dotnet run --project backend/src/QuickBite.Api

admin: ## Arranca solo el panel admin (Vite dev server)
	cd admin && npm run dev

dev: setup ## Arranca API + panel admin a la vez
	@echo "==> Arrancando API REST y panel admin..."
	@dotnet run --project backend/src/QuickBite.Api &
	@cd admin && npm run dev

build: ## Compila backend y panel admin (producción)
	dotnet build backend/src/QuickBite.sln
	cd admin && npm run build

lint: ## Verifica estilo: oxlint en admin, análisis estricto en backend
	cd admin && npm run lint
	dotnet build backend/src/QuickBite.sln -warnaserror

test: ## Ejecuta tests de backend (unitarias) con warnings como errores
	dotnet test backend/tests/QuickBite.Tests.Unit/

api-generate: ## Regenera el cliente API (Orval) del panel admin
	cd admin && npm run api:generate