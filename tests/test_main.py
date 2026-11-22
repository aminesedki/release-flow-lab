from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    body = client.get("/health").json()
    assert body["status"] == "ok"
    assert body["service"]


def test_greeting_default():
    body = client.get("/greeting").json()
    assert body["greeting"] == "hello from release-flow-lab"
    assert body["version"] == "local"


def test_version_default():
    assert client.get("/version").json()["version"] == "local"