
import os
import streamlit as st
from streamlit import session_state as sst

st.set_page_config(layout='wide', page_title='DataOps')

st.markdown(f"## :blue[DataOps]")

st.text('Hello World')
st.text(f"Environment: {os.environ.get('APP_ENV')}")
st.text(f"Root Path: {os.environ.get('ROOT_PATH')}")
st.text(f"Port: {os.environ.get('APP_PORT')}")
