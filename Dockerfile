FROM python:3.8-slim-buster


WORKDIR /usr/src/app
COPY . .
RUN chmod -R 777 /usr/src/app
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Set default environment to 'dev' and default port on which each container runs to 8501
# ENV APP_ENV='dev'
# ENV APP_PORT=5000
# RUN echo "env: $APP_ENV, port: $APP_PORT"

ENTRYPOINT ["./launch_app.sh"]

# Base command to run the container
#  docker container run -p 8000:6000 -d --name snow-con-ui-con-1 snow-con-ui
# Command to run on stage env with app port to 8000 mapped to 5000
# docker container run -p 8000:6000 -d -e APP_ENV=stage -e APP_PORT=6000 --name snow-con-ui-con-1 snow-con-ui