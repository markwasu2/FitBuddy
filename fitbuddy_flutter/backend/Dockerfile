# Use the official Python image.
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the code
COPY app.py ./

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Run the Flask app
CMD ["python", "app.py"] 