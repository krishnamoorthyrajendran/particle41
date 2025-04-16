# SimpleTimeService

A minimalist Python microservice that returns the current timestamp and client IP address in JSON format.

## Features

- Returns JSON with current timestamp and client IP address
- Containerized for easy deployment
- Runs as a non-root user for enhanced security
- Built with Flask for simplicity

## Prerequisites

- Docker

## Building the Container

```bash
docker build -t simpletimeservice .
```

## Running the Container

```bash
docker run -p 3000:3000 simpletimeservice
```

The service will be available at http://localhost:3000

## Docker Hub Image

You can also pull the pre-built image from Docker Hub:

```bash
docker pull yourusername/simpletimeservice
docker run -p 3000:3000 yourusername/simpletimeservice
```

## API

### GET /

Returns a JSON object with the current timestamp and the client's IP address:

```json
{
  "timestamp": "2025-04-16T12:34:56.789000",
  "ip": "127.0.0.1"
}
```

## Repository Structure

- `main.py` - The main application code
- `requirements.txt` - Python dependencies
- `Dockerfile` - Instructions for building the Docker image
- `README.md` - Documentation
