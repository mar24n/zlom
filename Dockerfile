# Production Dockerfile for Flask app with Gunicorn
# Use a slim Python base image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    FLASK_ENV=production \
    FLASK_SECRET_KEY=change-me-in-prod \
    PORT=5030 \
    GUNICORN_CMD_ARGS="--workers=2 --threads=4 --timeout=60 --graceful-timeout=30 --log-level=info"

# Set working directory
WORKDIR /app

# Install system dependencies (for building some wheels and SQLite if needed)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       ca-certificates \
       curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first and install
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Create a non-root user and fix permissions
RUN useradd -m -u 10001 appuser \
    && chown -R appuser:appuser /app

# Ensure SQLite file exists and is writable (optional; will be created at runtime if missing)
# Create a volume for persistence of the database
VOLUME ["/app/messages.db"]

# Expose the application port
EXPOSE 5030

# Switch to non-root user
USER appuser

# Default command: run Gunicorn serving the Flask app object "app" from app.py
# Bind to the given PORT env var (default 5030) and 0.0.0.0
CMD ["sh", "-c", "gunicorn -b 0.0.0.0:80 app:app"]
