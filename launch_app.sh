#!/bin/bash

# if APP_PORT is not set, use 5000 as default
if [ -z "$APP_PORT" ]; then
    export APP_PORT=5000
fi

# if APP_ENV is not set, use development as default
if [ -z "$APP_ENV" ]; then
    export APP_ENV=dev
fi

export ROOT_PATH=$(pwd)

# Launch the Streamlit app
python -m streamlit run app.py --server.address=0.0.0.0 --server.port $APP_PORT
