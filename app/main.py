import os

from fastapi import FastAPI

app = FastAPI(title="release-flow-lab")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/version")
def version() -> dict:
    return {"version": os.getenv("APP_VERSION", "local")}