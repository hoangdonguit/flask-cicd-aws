from flask import Flask, jsonify
import socket

app = Flask(__name__)

@app.route("/")
def home():
    return f"""
    <html>
    <head><title>Flask CI/CD Demo</title></head>
    <body style="font-family: sans-serif; max-width: 600px; margin: 60px auto; padding: 20px; background-color: #f4f4f9;">
        <h1 style="color: #2c3e50;">Chào Đồng, Flask đã chạy!</h1>
        <p>Dự án này được deploy tự động qua: <b>GitHub Actions → Docker Hub → AWS EC2</b></p>
        <hr>
        <p><strong>Hostname (ID Container):</strong> {socket.gethostname()}</p>
        <p><strong>Phiên bản:</strong> 1.0.0</p>
    </body>
    </html>
    """

@app.route("/health")
def health():
    # Endpoint này dùng để kiểm tra app có sống hay không
    return jsonify({"status": "ok", "version": "1.0.0", "message": "I am healthy!"})

if __name__ == "__main__":
    # Chạy trên mọi IP (0.0.0.0) và cổng 5000
    app.run(host="0.0.0.0", port=5000)