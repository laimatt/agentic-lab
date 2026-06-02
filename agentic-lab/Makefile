# Port allocation configuration
BACKEND_PORT_START := 8000
BACKEND_PORT_END := 8029
FRONTEND_PORT_START := 30402
FRONTEND_PORT_END := 30431

# Install system dependencies (requires sudo)
install-system-deps:
	@echo "Installing system dependencies..."
	@if [ ! -f install-system-deps.sh ]; then \
		echo "Error: install-system-deps.sh not found"; \
		exit 1; \
	fi
	@chmod +x install-system-deps.sh
	@sudo ./install-system-deps.sh

# Environment setup
setup:
	@echo "Setting up Python virtual environment..."
	@if [ -f .python-version ]; then \
		PYTHON_VERSION=$$(cat .python-version | cut -d. -f1,2); \
		if command -v python$$PYTHON_VERSION >/dev/null 2>&1; then \
			echo "Using python$$PYTHON_VERSION from .python-version"; \
			python$$PYTHON_VERSION -m venv .ve; \
		elif command -v python3 >/dev/null 2>&1; then \
			INSTALLED_VERSION=$$(python3 --version 2>&1 | awk '{print $$2}' | cut -d. -f1,2); \
			echo "python$$PYTHON_VERSION not found, using python3 (version $$INSTALLED_VERSION)"; \
			if [ "$$(echo "$$INSTALLED_VERSION >= 3.10" | bc -l)" -eq 1 ] && [ "$$(echo "$$INSTALLED_VERSION <= 3.13" | bc -l)" -eq 1 ]; then \
				python3 -m venv .ve; \
			else \
				echo "Error: Python version $$INSTALLED_VERSION is not supported. Please install Python 3.10-3.13"; \
				exit 1; \
			fi; \
		else \
			echo "Error: Python 3 not found. Please install Python 3.10-3.13"; \
			exit 1; \
		fi; \
	else \
		echo "No .python-version file found, using python3"; \
		python3 -m venv .ve; \
	fi
	@echo "Installing Python dependencies..."
	. .ve/bin/activate && pip install -r requirements.txt
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			echo "Creating .env from .env.example..."; \
			cp .env.example .env; \
		else \
			echo "Creating .env file..."; \
			echo "APP_ENV=dev" > .env; \
			echo "JWT_SECRET_KEY=dev-jwt-secret-key-change-in-production" >> .env; \
			echo "SECRET_KEY=dev-secret-key-change-in-production" >> .env; \
		fi; \
	else \
		echo ".env file already exists, skipping..."; \
	fi
	@if [ ! -f .env.dev ]; then \
		echo "Creating .env.dev file..."; \
		cp .env .env.dev; \
	fi
	@if [ ! -f frontend/.env.development ]; then \
		echo "Creating frontend/.env.development file..."; \
		echo "# Ports will be set dynamically on startup" > frontend/.env.development; \
		echo "PORT=30402" >> frontend/.env.development; \
		echo "API_URL=http://localhost:8000/api" >> frontend/.env.development; \
	fi
	@echo "Installing frontend dependencies..."
	cd frontend && npm install
	@echo ""
	@echo "✅ Setup complete! Next steps:"
	@echo "   1. Run 'make init-db' to initialize the database"
	@echo "   2. Run 'make start' to start the application"
	

# Database initialization
init-db:
	. .ve/bin/activate && [ ! -f bobverse.db ] || mv -f bobverse.db bobverse.db.bak && python3 init_sqlite_db.py --auto-login

# Run backend tests
test-backend:
	. .ve/bin/activate && export APP_ENV=test && \
	export JWT_SECRET_KEY=test-jwt-secret-key && \
	export SECRET_KEY=test-secret-key && \
	python -m pytest -v ./tests

# Run backend only
backend:
	@BACKEND_PORT=$$(for port in $$(seq $(BACKEND_PORT_START) $(BACKEND_PORT_END)); do \
		if ! lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 && \
		   ! netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo $$port; \
			break; \
		fi; \
	done); \
	if [ -z "$$BACKEND_PORT" ]; then \
		echo "❌ Error: No available backend ports in range $(BACKEND_PORT_START)-$(BACKEND_PORT_END)"; \
		exit 1; \
	fi; \
	echo "🚀 Starting backend on port $$BACKEND_PORT..."; \
	. .ve/bin/activate && uvicorn bobverse.app:app --host 0.0.0.0 --port $$BACKEND_PORT --reload

# Run frontend only
frontend:
	@FRONTEND_PORT=$$(for port in $$(seq $(FRONTEND_PORT_START) $(FRONTEND_PORT_END)); do \
		if ! lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 && \
		   ! netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo $$port; \
			break; \
		fi; \
	done); \
	if [ -z "$$FRONTEND_PORT" ]; then \
		echo "❌ Error: No available frontend ports in range $(FRONTEND_PORT_START)-$(FRONTEND_PORT_END)"; \
		exit 1; \
	fi; \
	echo "🚀 Starting frontend on port $$FRONTEND_PORT..."; \
	echo "PORT=$$FRONTEND_PORT" > frontend/.env.development; \
	echo "API_URL=http://localhost:8000/api" >> frontend/.env.development; \
	cd frontend && PORT=$$FRONTEND_PORT npm start

# Run both backend and frontend
start:
	@echo "🔍 Finding available ports..."
	@BACKEND_PORT=$$(for port in $$(seq $(BACKEND_PORT_START) $(BACKEND_PORT_END)); do \
		if ! lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 && \
		   ! netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo $$port; \
			break; \
		fi; \
	done); \
	if [ -z "$$BACKEND_PORT" ]; then \
		echo "❌ Error: No available backend ports in range $(BACKEND_PORT_START)-$(BACKEND_PORT_END)"; \
		exit 1; \
	fi; \
	FRONTEND_PORT=$$(for port in $$(seq $(FRONTEND_PORT_START) $(FRONTEND_PORT_END)); do \
		if ! lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 && \
		   ! netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo $$port; \
			break; \
		fi; \
	done); \
	if [ -z "$$FRONTEND_PORT" ]; then \
		echo "❌ Error: No available frontend ports in range $(FRONTEND_PORT_START)-$(FRONTEND_PORT_END)"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "✅ Ports allocated successfully!"; \
	echo "   Backend:  http://localhost:$$BACKEND_PORT"; \
	echo "   Frontend: http://localhost:$$FRONTEND_PORT"; \
	echo "   API URL:  http://localhost:$$BACKEND_PORT/api"; \
	echo ""; \
	echo "PORT=$$FRONTEND_PORT" > frontend/.env.development; \
	echo "API_URL=http://localhost:$$BACKEND_PORT/api" >> frontend/.env.development; \
	echo "🚀 Starting backend and frontend..."; \
	echo ""; \
	trap 'kill 0' INT; \
	. .ve/bin/activate && uvicorn bobverse.app:app --host 0.0.0.0 --port $$BACKEND_PORT --reload & \
	cd frontend && PORT=$$FRONTEND_PORT npm start & \
	wait

# Clean the project (remove database and other generated files)
clean:
	@echo "Cleaning project..."
	rm -f bobverse.db
	rm -f test_bobverse.db
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +

# List running instances
list-instances:
	@echo "🔍 Scanning for running instances..."
	@echo ""
	@echo "Backend instances:"
	@for port in $$(seq $(BACKEND_PORT_START) $(BACKEND_PORT_END)); do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo "  ✓ Port $$port - http://localhost:$$port"; \
		fi; \
	done
	@echo ""
	@echo "Frontend instances:"
	@for port in $$(seq $(FRONTEND_PORT_START) $(FRONTEND_PORT_END)); do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo "  ✓ Port $$port - http://localhost:$$port"; \
		fi; \
	done
	@echo ""

# Show available ports
show-ports:
	@echo "📊 Port Allocation Status"
	@echo ""
	@echo "Backend ports ($(BACKEND_PORT_START)-$(BACKEND_PORT_END)):"
	@AVAILABLE=0; USED=0; \
	for port in $$(seq $(BACKEND_PORT_START) $(BACKEND_PORT_END)); do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			USED=$$((USED + 1)); \
		else \
			AVAILABLE=$$((AVAILABLE + 1)); \
		fi; \
	done; \
	echo "  Available: $$AVAILABLE"; \
	echo "  In use: $$USED"
	@echo ""
	@echo "Frontend ports ($(FRONTEND_PORT_START)-$(FRONTEND_PORT_END)):"
	@AVAILABLE=0; USED=0; \
	for port in $$(seq $(FRONTEND_PORT_START) $(FRONTEND_PORT_END)); do \
		if lsof -Pi :$$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			USED=$$((USED + 1)); \
		else \
			AVAILABLE=$$((AVAILABLE + 1)); \
		fi; \
	done; \
	echo "  Available: $$AVAILABLE"; \
	echo "  In use: $$USED"
	@echo ""

# Show help
help:
	@echo "Bobverse - Available Make Commands"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make install-system-deps  Install system dependencies (Python, Node.js, build tools) - Linux only, requires sudo"
	@echo "  make setup                Install Python and npm dependencies, create config files"
	@echo "  make init-db              Initialize/reset database with seed data"
	@echo ""
	@echo "Running the Application:"
	@echo "  make start                Start both backend and frontend (auto-allocates ports)"
	@echo "  make backend              Start backend only (auto-allocates port from $(BACKEND_PORT_START)-$(BACKEND_PORT_END))"
	@echo "  make frontend             Start frontend only (auto-allocates port from $(FRONTEND_PORT_START)-$(FRONTEND_PORT_END))"
	@echo ""
	@echo "Port Management:"
	@echo "  make list-instances       List all running instances with their ports"
	@echo "  make show-ports           Show port allocation status"
	@echo ""
	@echo "Testing:"
	@echo "  make test-backend         Run backend tests"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean                Remove database and cache files"
	@echo "  make help                 Show this help message"
	@echo ""
	@echo "💡 Multiple Instances:"
	@echo "  You can run up to 20 concurrent instances by running 'make start' in separate terminals."
	@echo "  Each instance will automatically get unique backend and frontend ports."
	@echo ""
	@echo "Quick Start (Linux):"
	@echo "  make install-system-deps && make setup && make init-db && make start"
	@echo ""
	@echo "Quick Start (Other Platforms):"
	@echo "  make setup && make init-db && make start"

.PHONY: install-system-deps setup init-db test-backend backend frontend start clean help list-instances show-ports
