from fastapi import FastAPI
from routes.recommendations import router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="FitAura Recommender API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="/api")

@app.get("/")
def health():
    return {"status": "FitAura Recommender is running"}