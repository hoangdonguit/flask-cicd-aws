import os
import socket

from flask import Flask, jsonify

APP_NAME = "flask-cicd-aws"


def get_runtime_metadata() -> dict[str, str]:
    image_tag = os.getenv("IMAGE_TAG", "dev")
    app_version = os.getenv("APP_VERSION", image_tag)

    return {
        "app": APP_NAME,
        "version": app_version,
        "image_tag": image_tag,
        "environment": os.getenv("DEPLOY_ENV", "local"),
        "hostname": socket.gethostname(),
        "deploy_time": os.getenv("DEPLOY_TIME", "unknown"),
    }


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/")
    def home():
        metadata = get_runtime_metadata()
        return jsonify(
            {
                **metadata,
                "status": "running",
            }
        )

    @app.get("/health")
    def health():
        metadata = get_runtime_metadata()
        return jsonify(
            {
                "app": metadata["app"],
                "status": "ok",
                "version": metadata["version"],
            }
        )

    @app.get("/version")
    def version():
        metadata = get_runtime_metadata()
        return jsonify(
            {
                "app": metadata["app"],
                "version": metadata["version"],
                "image_tag": metadata["image_tag"],
            }
        )

    @app.get("/metadata")
    def metadata():
        return jsonify(get_runtime_metadata())

    return app


app = create_app()


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
