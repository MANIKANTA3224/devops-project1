from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello! Your CI/CD pipeline works perfectly 🎉"

if __name__ == "__main__":
    app.run()
