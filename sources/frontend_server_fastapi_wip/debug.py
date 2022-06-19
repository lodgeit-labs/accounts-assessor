import uvicorn

from app.main import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7788, log_level='trace')
    #--reload  --proxy-headers --host 0.0.0.0 --port 7788  --log-level trace

