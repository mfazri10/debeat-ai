FROM python:3.11-slim

WORKDIR /app

# Install system build dependencies (untuk asyncpg dan C extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

EXPOSE 50051

CMD ["python", "main.py"]
