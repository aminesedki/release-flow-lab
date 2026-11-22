import os

from fastapi import FastAPI

app = FastAPI(title="release-flow-lab")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": os.getenv("HOSTNAME", "release-flow-lab")}


@app.get("/greeting")
def greeting() -> dict:
    return {"greeting": "hello from release-flow-lab", "version": os.getenv("APP_VERSION", "local")}


@app.get("/version")
def version() -> dict:
    return {"version": os.getenv("APP_VERSION", "local")}