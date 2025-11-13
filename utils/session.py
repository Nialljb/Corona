import streamlit as st

def check_connection():
    """Check if connected to HPC cluster."""
    return st.session_state.get("connected", False) and st.session_state.get("client") is not None

def require_connection():
    """Require connection or show error and stop."""
    if not check_connection():
        st.error("❌ Not connected to HPC cluster. Please connect using the sidebar.")
        st.stop()