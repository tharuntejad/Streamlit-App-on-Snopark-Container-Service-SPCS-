
### Starting the application  
In order to start the application, the following steps should be followed.

**Mac and Linux**  
```bash
# First make the file executable
chmod +x launch_app.sh

# Launch app on default environment(dev) and port(8501)
./launch_app.sh

# Launch app on specified environment and port
APP_ENV=<env> APP_PORT=<port no> ./launch_app.sh

# Launch app on stage
APP_ENV=stage APP_PORT=5000 ./launch_app.sh

# Launch app on prod
APP_ENV=prod APP_PORT=8000 ./launch_app.sh

```

**Commands to build and run containers**
```bash
# Build the container
docker build -t streamlit-app:latest .

# Run the container 
docker run -p 5000:8000 -d -e APP_PORT=8000 -e APP_ENV=dev --name streamlit-app-con stramlit-app

```
