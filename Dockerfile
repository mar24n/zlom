# Use official Python image
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies if needed (optional)
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 10001 appuser \
    && mkdir -p /data \
    && chown -R appuser:appuser /app /data

# Make /data the volume for SQLite persistence
VOLUME ["/data"]

# Expose the app port
EXPOSE 80

# Switch to non-root user
USER appuser

# Default command: run Gunicorn serving Flask app object "app" from app.py
# Bind Gunicorn to container port 80
CMD ["sh", "-c", "gunicorn -b 0.0.0.0:80 app:app"]
