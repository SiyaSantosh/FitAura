from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
from db.connection import get_connection

model = SentenceTransformer('all-MiniLM-L6-v2')

def get_all_approved_products():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT product_id, product_name, description, category, gender, price
        FROM products
        WHERE is_verified = 1 AND is_visible = 1
    """)
    products = cursor.fetchall()
    conn.close()
    return products

def get_search_based_recommendations(user_id: int, limit: int = 10):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT search_query FROM user_interactions
        WHERE user_id = %s AND interaction_type = 'search'
        AND search_query IS NOT NULL
        ORDER BY timestamp DESC LIMIT 5
    """, (user_id,))
    searches = cursor.fetchall()
    conn.close()

    products = get_all_approved_products()
    if not products:
        return []

    if not searches:
        return get_trending_products(limit)

    combined_query = " ".join([s['search_query'] for s in searches])
    query_embedding = model.encode([combined_query])

    product_texts = [
        f"{p['product_name']} {p['description'] or ''} {p['category'] or ''} {p['gender']}"
        for p in products
    ]
    product_embeddings = model.encode(product_texts)

    scores = cosine_similarity(query_embedding, product_embeddings)[0]
    top_indices = np.argsort(scores)[::-1][:limit]

    return [products[i] for i in top_indices]


def get_trending_products(limit: int = 10):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT p.product_id, p.product_name, p.description,
               p.category, p.gender, p.price,
               COUNT(oi.product_id) as order_count
        FROM products p
        LEFT JOIN order_items oi ON p.product_id = oi.product_id
        LEFT JOIN orders o ON oi.order_id = o.order_id
        WHERE p.is_verified = 1 AND p.is_visible = 1
        GROUP BY p.product_id
        ORDER BY order_count DESC
        LIMIT %s
    """, (limit,))
    result = cursor.fetchall()
    conn.close()
    return result


def get_similar_products(product_id: int, limit: int = 6):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT product_id, product_name, description, category, gender, price
        FROM products WHERE product_id = %s
    """, (product_id,))
    current = cursor.fetchone()
    conn.close()

    if not current:
        return []

    products = get_all_approved_products()
    products = [p for p in products if p['product_id'] != product_id]

    if not products:
        return []

    query_text = f"{current['product_name']} {current['description'] or ''} {current['category'] or ''}"
    query_embedding = model.encode([query_text])

    product_texts = [
        f"{p['product_name']} {p['description'] or ''} {p['category'] or ''} {p['gender']}"
        for p in products
    ]
    product_embeddings = model.encode(product_texts)

    scores = cosine_similarity(query_embedding, product_embeddings)[0]
    top_indices = np.argsort(scores)[::-1][:limit]

    return [products[i] for i in top_indices]