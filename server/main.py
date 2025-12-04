import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse

app = FastAPI()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "models")

# List of allowed files (security)
ALLOWED_FILES = {
    "llama-squint.pte",
    "tokenizer.model",
}

@app.get("/")
def root():
    return {"message": "Model Server Running"}

@app.get("/download/{filename}")
def download_file(filename: str):
    if filename not in ALLOWED_FILES:
        raise HTTPException(status_code=404, detail="File not found")

    file_path = os.path.join(MODEL_DIR, filename)

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File missing on server")

    return FileResponse(
        path=file_path,
        filename=filename,
        media_type="application/octet-stream",
    )
