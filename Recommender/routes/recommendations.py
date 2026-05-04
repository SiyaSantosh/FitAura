from fastapi import APIRouter
from services.recommender import (
    get_search_based_recommendations,
    get_trending_products,
    get_similar_products
)

router = APIRouter()

@router.get("/recommendations/{user_id}")
def recommendations(user_id: int, limit: int = 10):
    results = get_search_based_recommendations(user_id, limit)
    return {"user_id": user_id, "recommendations": results}

@router.get("/trending")
def trending(limit: int = 10):
    results = get_trending_products(limit)
    return {"recommendations": results}

@router.get("/similar/{product_id}")
def similar(product_id: int, limit: int = 6):
    results = get_similar_products(product_id, limit)
    return {"product_id": product_id, "similar": results}