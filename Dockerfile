FROM python:3.11-slim AS base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a non-root user and set the working directory
RUN adduser --disabled-password appuser
WORKDIR /app

# Copy only necessary files
COPY requirements.txt ./
COPY package.json ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Node.js and dependencies
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install --no-fund --no-audit --production

# Copy remaining project files
COPY . .

# Change to non-root user
USER appuser

# Expose the port (default for Flask is 5000)
EXPOSE 5000

# Start the Flask application
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]