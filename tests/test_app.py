import pytest
from flask.testing import FlaskClient

from app import APP_NAME, create_app, get_runtime_metadata


@pytest.fixture
def client(monkeypatch: pytest.MonkeyPatch) -> FlaskClient:
    monkeypatch.setenv("APP_VERSION", "test-version")
    monkeypatch.setenv("IMAGE_TAG", "sha-test123")
    monkeypatch.setenv("DEPLOY_ENV", "test")
    monkeypatch.setenv("DEPLOY_TIME", "2026-07-17T10:00:00Z")
    monkeypatch.setattr("app.socket.gethostname", lambda: "test-host")

    flask_app = create_app()
    flask_app.config.update(TESTING=True)

    return flask_app.test_client()


def test_root_endpoint_returns_runtime_summary(client: FlaskClient) -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.mimetype == "application/json"
    assert response.get_json() == {
        "app": APP_NAME,
        "version": "test-version",
        "image_tag": "sha-test123",
        "environment": "test",
        "hostname": "test-host",
        "deploy_time": "2026-07-17T10:00:00Z",
        "status": "running",
    }


def test_health_endpoint_returns_healthy_status(client: FlaskClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {
        "app": APP_NAME,
        "status": "ok",
        "version": "test-version",
    }


def test_version_endpoint_returns_version_and_image_tag(client: FlaskClient) -> None:
    response = client.get("/version")

    assert response.status_code == 200
    assert response.get_json() == {
        "app": APP_NAME,
        "version": "test-version",
        "image_tag": "sha-test123",
    }


def test_metadata_endpoint_returns_runtime_metadata(client: FlaskClient) -> None:
    response = client.get("/metadata")

    assert response.status_code == 200
    assert response.get_json() == {
        "app": APP_NAME,
        "version": "test-version",
        "image_tag": "sha-test123",
        "environment": "test",
        "hostname": "test-host",
        "deploy_time": "2026-07-17T10:00:00Z",
    }


def test_app_version_falls_back_to_image_tag(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("APP_VERSION", raising=False)
    monkeypatch.setenv("IMAGE_TAG", "sha-fallback")
    monkeypatch.setenv("DEPLOY_ENV", "test")
    monkeypatch.setenv("DEPLOY_TIME", "2026-07-17T10:00:00Z")
    monkeypatch.setattr("app.socket.gethostname", lambda: "test-host")

    metadata = get_runtime_metadata()

    assert metadata["image_tag"] == "sha-fallback"
    assert metadata["version"] == "sha-fallback"


def test_runtime_metadata_uses_safe_defaults(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    for variable in (
        "APP_VERSION",
        "IMAGE_TAG",
        "DEPLOY_ENV",
        "DEPLOY_TIME",
    ):
        monkeypatch.delenv(variable, raising=False)

    monkeypatch.setattr("app.socket.gethostname", lambda: "default-host")

    assert get_runtime_metadata() == {
        "app": APP_NAME,
        "version": "dev",
        "image_tag": "dev",
        "environment": "local",
        "hostname": "default-host",
        "deploy_time": "unknown",
    }
