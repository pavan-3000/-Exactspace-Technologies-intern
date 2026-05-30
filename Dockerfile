FROM python:3.11-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ddd/ ./ddd/

# Node.js setup for Puppeteer
FROM node:18-alpine AS node-builder

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install --production

# Copy necessary code
COPY ddd/ ./ddd/

# Final image
FROM python:3.11-alpine

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the working directory
WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy Node.js dependencies from node-builder
COPY --from=node-builder /app/node_modules /app/node_modules

# Copy application code
COPY ddd/ ./ddd/

# Change ownership of the working directory
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the application's port (Flask default is 5000)
EXPOSE 5000

# Command to run the application (assuming a Flask app)
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]