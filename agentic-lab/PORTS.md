# Dynamic Port Allocation Guide

This document explains how to run multiple concurrent instances of the Bobverse application using automatic port allocation.

## Overview

The application now supports running up to **20 concurrent instances** simultaneously. Each instance automatically receives unique ports for both the backend and frontend services.

## Port Ranges

- **Backend Ports:** 8000-8019 (20 ports)
- **Frontend Ports:** 30402-30421 (20 ports)

Each instance gets a paired set of ports. For example:
- Instance 1: Backend 8000, Frontend 30402
- Instance 2: Backend 8001, Frontend 30403
- Instance 3: Backend 8002, Frontend 30404
- ... and so on

## Usage

### Starting a Single Instance

```bash
make start
```

The system will:
1. Find the next available backend port (8000-8019)
2. Find the next available frontend port (30402-30421)
3. Update the frontend configuration automatically
4. Display the allocated ports
5. Start both services

**Example Output:**
```
🔍 Finding available ports...

✅ Ports allocated successfully!
   Backend:  http://localhost:8000
   Frontend: http://localhost:30402
   API URL:  http://localhost:8000/api

🚀 Starting backend and frontend...
```

### Running Multiple Instances

To run multiple instances concurrently, simply open separate terminal windows and run `make start` in each:

**Terminal 1:**
```bash
cd /path/to/agentic-lab
make start
# Gets ports: Backend 8000, Frontend 30402
```

**Terminal 2:**
```bash
cd /path/to/agentic-lab
make start
# Gets ports: Backend 8001, Frontend 30403
```

**Terminal 3:**
```bash
cd /path/to/agentic-lab
make start
# Gets ports: Backend 8002, Frontend 30404
```

Continue this pattern for up to 20 concurrent instances.

### Running Backend or Frontend Only

**Backend Only:**
```bash
make backend
# Automatically allocates a port from 8000-8019
```

**Frontend Only:**
```bash
make frontend
# Automatically allocates a port from 30402-30421
# Note: Assumes backend is running on port 8000
```

## Port Management Commands

### List Running Instances

View all currently running instances and their ports:

```bash
make list-instances
```

**Example Output:**
```
🔍 Scanning for running instances...

Backend instances:
  ✓ Port 8000 - http://localhost:8000
  ✓ Port 8001 - http://localhost:8001
  ✓ Port 8003 - http://localhost:8003

Frontend instances:
  ✓ Port 30402 - http://localhost:30402
  ✓ Port 30403 - http://localhost:30403
  ✓ Port 30405 - http://localhost:30405
```

### Check Port Availability

See how many ports are available vs. in use:

```bash
make show-ports
```

**Example Output:**
```
📊 Port Allocation Status

Backend ports (8000-8019):
  Available: 17
  In use: 3

Frontend ports (30402-30421):
  Available: 17
  In use: 3
```

## How It Works

### Port Detection Algorithm

The Makefile uses a shell function that:

1. Iterates through the port range (e.g., 8000-8019)
2. Checks if each port is in use using `lsof` and `netstat`
3. Returns the first available port
4. If no ports are available, displays an error message

### Configuration Updates

When starting an instance:

1. The system detects available ports
2. Updates `frontend/.env.development` with:
   - `PORT=<selected_frontend_port>`
   - `API_URL=http://localhost:<selected_backend_port>/api`
3. Passes ports to both backend (uvicorn) and frontend (webpack)

### Environment File

The `frontend/.env.development` file is automatically updated on each startup. This ensures:
- The frontend knows which port to use
- The frontend knows which backend API URL to connect to
- Each instance is properly configured

## Troubleshooting

### Error: No Available Ports

If you see this error:
```
❌ Error: No available backend ports in range 8000-8019
```

**Solutions:**
1. Stop some running instances to free up ports
2. Check running instances: `make list-instances`
3. Manually kill processes using ports: `lsof -ti:8000 | xargs kill -9`

### Port Already in Use

If a port is already in use by another application:
- The system will automatically skip it and use the next available port
- No manual intervention needed

### Checking Port Usage

To manually check if a port is in use:

```bash
# Check specific port
lsof -i :8000

# Check all ports in range
for port in {8000..8019}; do lsof -i :$port; done
```

### Killing All Instances

To stop all running instances:

```bash
# Kill all backend instances
for port in {8000..8019}; do lsof -ti:$port | xargs kill -9 2>/dev/null; done

# Kill all frontend instances
for port in {30402..30421}; do lsof -ti:$port | xargs kill -9 2>/dev/null; done
```

## Platform Compatibility

### Linux
✅ Fully supported - uses `lsof` and `netstat`

### macOS
✅ Fully supported - uses `lsof` and `netstat`

### Windows (WSL)
✅ Supported - uses `lsof` and `netstat` within WSL environment

### Windows (Native)
⚠️ Requires WSL or manual port management

## Best Practices

### Development Workflow

1. **Start instances as needed:**
   ```bash
   make start  # Terminal 1
   make start  # Terminal 2
   make start  # Terminal 3
   ```

2. **Monitor running instances:**
   ```bash
   make list-instances
   ```

3. **Check capacity before starting more:**
   ```bash
   make show-ports
   ```

4. **Stop instances when done:**
   - Press `Ctrl+C` in each terminal
   - Or use the kill commands above

### Testing Multiple Instances

When testing with multiple instances:

1. Each instance has its own database (shared `bobverse.db`)
2. Each instance has independent frontend state
3. API calls go to the correct backend via `API_URL`
4. Browser sessions are isolated by port

### Resource Considerations

Running 20 concurrent instances requires:
- **CPU:** ~2-4 cores recommended
- **RAM:** ~8-16 GB recommended
- **Disk:** Minimal (shared database)
- **Network:** 40 ports (20 backend + 20 frontend)

## Advanced Usage

### Custom Port Ranges

To modify the port ranges, edit the Makefile:

```makefile
# Port allocation configuration
BACKEND_PORT_START := 8000
BACKEND_PORT_END := 8019
FRONTEND_PORT_START := 30402
FRONTEND_PORT_END := 30421
```

### Scripted Instance Management

Create a script to start multiple instances:

```bash
#!/bin/bash
# start-instances.sh

NUM_INSTANCES=5

for i in $(seq 1 $NUM_INSTANCES); do
    echo "Starting instance $i..."
    gnome-terminal -- bash -c "cd $(pwd) && make start; exec bash"
    sleep 2
done
```

### Docker/Container Support

For containerized deployments, consider:
- Mapping host ports to container ports
- Using environment variables for port configuration
- Implementing service discovery for dynamic ports

## FAQ

**Q: Can I run more than 20 instances?**
A: Yes, but you'll need to expand the port ranges in the Makefile.

**Q: What happens if I run out of ports?**
A: The system will display an error and refuse to start. Stop some instances first.

**Q: Can I specify a specific port?**
A: Not with the current implementation. The system always uses the next available port.

**Q: Do all instances share the same database?**
A: Yes, by default they share `bobverse.db`. For isolation, you'd need to modify the backend configuration.

**Q: How do I access a specific instance?**
A: Use `make list-instances` to see all running instances and their URLs.

## Support

For issues or questions:
1. Check `make help` for available commands
2. Review this documentation
3. Check the Makefile for implementation details
4. Consult the main README.md for general setup

## Summary

The dynamic port allocation system enables:
- ✅ Running up to 20 concurrent instances
- ✅ Automatic port detection and allocation
- ✅ Zero configuration required
- ✅ Easy monitoring and management
- ✅ Cross-platform compatibility

Simply run `make start` in multiple terminals, and the system handles the rest!