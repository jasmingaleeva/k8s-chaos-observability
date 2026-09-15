"""
Locust Load Testing Scenario for Google Online Boutique
Simulates realistic e-commerce user behavior:
1. Browsing homepage
2. Viewing product catalog items
3. Adding products to cart
4. Viewing cart
5. Completing checkout
"""

import random
from locust import HttpUser, task, between

# Sample product IDs available in Google Online Boutique catalog
PRODUCT_IDS = [
    "OLJCESPC7Z",
    "66VCHSJNUP",
    "1YMWWN1N4O",
    "L9ECAV7KIM",
    "2ZYFJ3GM2N",
    "0PUK6TGMSL",
    "LS4PSXUNUM",
]

CURRENCIES = ["USD", "EUR", "GBP", "JPY", "CAD"]


class BoutiqueCustomerUser(HttpUser):
    wait_time = between(1, 3)

    @task(4)
    def browse_homepage(self):
        """Browse home page and list products."""
        self.client.get("/", name="GET / (Homepage)")

    @task(5)
    def view_product(self):
        """View a specific product catalog item."""
        product_id = random.choice(PRODUCT_IDS)
        self.client.get(f"/product/{product_id}", name="GET /product/[id]")

    @task(3)
    def add_to_cart(self):
        """Add a selected product to the shopping cart."""
        product_id = random.choice(PRODUCT_IDS)
        self.client.post(
            "/cart",
            data={
                "product_id": product_id,
                "quantity": random.randint(1, 3),
            },
            name="POST /cart (Add to Cart)",
        )

    @task(2)
    def view_cart(self):
        """View items currently in the cart."""
        self.client.get("/cart", name="GET /cart")

    @task(1)
    def checkout(self):
        """Complete purchase and checkout."""
        self.client.post(
            "/cart/checkout",
            data={
                "email": "devops-tester@tbank.ru",
                "street_address": "2-ya Khutorskaya ul., 38A",
                "zip_code": "127287",
                "city": "Moscow",
                "state": "Moscow",
                "country": "Russia",
                "credit_card_number": "4111111111111111",
                "credit_card_expiration_month": "12",
                "credit_card_cvv": "123",
            },
            name="POST /cart/checkout",
        )

    @task(1)
    def change_currency(self):
        """Switch display currency."""
        currency = random.choice(CURRENCIES)
        self.client.post(
            "/setCurrency",
            data={"currency_code": currency},
            name="POST /setCurrency",
        )
