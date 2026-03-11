FROM python:3.11-slim

WORKDIR /app

# Install required python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all application files
COPY . .

# Ensure entrypoint script is executable
RUN chmod +x docker-entrypoint.sh

# Expose port for the Python simple HTTP server
EXPOSE 80

# Run the entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
