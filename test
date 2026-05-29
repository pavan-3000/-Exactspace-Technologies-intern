# Multi-Stage Dockerfile

# Stage 1: Scraper (Node.js + Puppeteer + Chromium)
FROM node:18-slim AS scraper

# Install Chromium dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    ca-certificates \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Set environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy scraper script
COPY scrape.js ./

# Run scraper
ARG SCRAPE_URL
ENV SCRAPE_URL=${SCRAPE_URL}
RUN node scrape.js


# Stage 2: Flask Web Server (Python)
FROM python:3.10-slim AS server

# Set working directory
WORKDIR /app

# Copy required files from scraper stage
COPY --from=scraper /app/scraped_data.json ./

# Copy and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy Flask server script
COPY server.py ./

# Expose port 5000
EXPOSE 5000

# Start Flask server
CMD ["python", "server.py"]
