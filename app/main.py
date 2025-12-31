from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/hello")
def hello():
    env = os.getenv("APP_ENV", "dev")
    return {"message": "Hello DevSecOps", "env": env}

