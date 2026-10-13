import pandas as pd
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw" / "Online Retail.xlsx"
OUT = ROOT / "data" / "processed"
OUT.mkdir(parents=True, exist_ok=True)

if not RAW.exists():
    raise FileNotFoundError(f"Download Online Retail.xlsx from UCI and place it at: {RAW}")

df = pd.read_excel(RAW)
df.columns = [c.strip() for c in df.columns]

df["InvoiceNo"] = df["InvoiceNo"].astype(str).str.strip()
df["StockCode"] = df["StockCode"].astype(str).str.strip()
df["Description"] = df["Description"].fillna("UNKNOWN PRODUCT").astype(str).str.strip()
df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], errors="coerce")
df["CustomerID"] = pd.to_numeric(df["CustomerID"], errors="coerce")
df["Quantity"] = pd.to_numeric(df["Quantity"], errors="coerce").fillna(0).astype(int)
df["UnitPrice"] = pd.to_numeric(df["UnitPrice"], errors="coerce").fillna(0).astype(float)

# Core sales scope: completed positive-quantity transactions with positive price.
sales = df[
    ~df["InvoiceNo"].str.upper().str.startswith("C") &
    (df["Quantity"] > 0) &
    (df["UnitPrice"] > 0) &
    df["InvoiceDate"].notna()
].copy()

def category(description):
    s = description.upper()
    rules = [
        ("Kitchen & Dining", ["MUG", "CUP", "PLATE", "BOWL", "CUTLERY", "CAKE", "BAKING", "TEA"]),
        ("Home Decor", ["HEART", "LANTERN", "CANDLE", "HOLDER", "ORNAMENT", "FRAME", "MIRROR"]),
        ("Bags & Accessories", ["BAG", "PURSE", "WALLET", "UMBRELLA"]),
        ("Stationery", ["PEN", "PENCIL", "NOTEBOOK", "CARD", "PAPER", "STICKER"]),
        ("Toys & Kids", ["TOY", "CHILD", "DOLL", "GAME", "PUZZLE", "LUNCH BOX"]),
        ("Gifts & Seasonal", ["GIFT", "CHRISTMAS", "EASTER", "PARTY", "BUNTING"]),
        ("Kitchen Storage", ["JAR", "BOX", "TIN", "BASKET", "STORAGE"]),
    ]
    for cat, words in rules:
        if any(w in s for w in words):
            return cat
    return "Other"

sales["category_name"] = sales["Description"].map(category)

# Categories
cat_names = sorted(sales["category_name"].unique())
categories = pd.DataFrame({
    "category_id": range(1, len(cat_names)+1),
    "category_name": cat_names,
    "category_source": "derived_keyword"
})
cat_map = dict(zip(categories.category_name, categories.category_id))

# Products: use median observed price as product master price.
products = (
    sales.groupby(["StockCode","Description","category_name"], as_index=False)
         .agg(unit_price=("UnitPrice","median"))
         .rename(columns={"StockCode":"product_id","Description":"product_name"})
)
products["category_id"] = products["category_name"].map(cat_map)
products["active"] = True
products = products[["product_id","product_name","category_id","unit_price","active"]]

# Stores: virtual regions based on country. This is an analytical enrichment.
def region(country):
    if country == "United Kingdom":
        return "UK"
    if country in {"France","Germany","Spain","Portugal","Belgium","Netherlands","Italy","Switzerland","Austria","Denmark","Finland","Sweden","Norway","Ireland"}:
        return "Europe"
    if country in {"Australia","Japan","Singapore","Hong Kong"}:
        return "APAC"
    return "International"

country_to_store = {}
for c in sorted(sales["Country"].dropna().unique()):
    country_to_store[c] = region(c)

stores = pd.DataFrame(sorted(set(country_to_store.values())), columns=["region"])
stores["store_id"] = range(1, len(stores)+1)
stores["store_name"] = stores["region"] + " Virtual Store"
stores["country_group"] = stores["region"]
stores["store_type"] = "virtual_region"
stores["store_source"] = "derived_country"
stores = stores[["store_id","store_name","region","country_group","store_type","store_source"]]
region_to_store = dict(zip(stores.region, stores.store_id))

# Customers
cust = sales.dropna(subset=["CustomerID"]).copy()
cust["CustomerID"] = cust["CustomerID"].astype(int)
customers = (
    cust.groupby("CustomerID")
        .agg(country=("Country","first"),
             first_order_date=("InvoiceDate","min"),
             last_order_date=("InvoiceDate","max"))
        .reset_index()
        .rename(columns={"CustomerID":"customer_id"})
)
customers["first_order_date"] = customers["first_order_date"].dt.date
customers["last_order_date"] = customers["last_order_date"].dt.date

# Orders: one row per invoice; anonymous invoices retain NULL customer.
sales["store_id"] = sales["Country"].map(lambda x: region_to_store[country_to_store[x]])
order_base = (
    sales.groupby("InvoiceNo", as_index=False)
         .agg(customer_id=("CustomerID","first"),
              store_id=("store_id","first"),
              order_date=("InvoiceDate","first"))
)
order_base["customer_id"] = order_base["customer_id"].where(order_base["customer_id"].notna(), np.nan)
order_base["customer_id"] = order_base["customer_id"].astype("Int64")
order_base["order_status"] = "Completed"
orders = order_base.rename(columns={"InvoiceNo":"order_id"})[
    ["order_id","customer_id","store_id","order_date","order_status"]
]

order_items = sales.rename(columns={
    "InvoiceNo":"order_id",
    "StockCode":"product_id"
})[["order_id","product_id","Quantity","UnitPrice"]].rename(
    columns={"Quantity":"quantity","UnitPrice":"unit_price"}
)

# Derived inventory planning snapshot:
# estimated opening stock = max(50, 2 x observed units sold over the period).
# This is a planning assumption, not source-system inventory history.
prod_sales = sales.groupby(["store_id","StockCode"], as_index=False)["Quantity"].sum()
prod_sales = prod_sales.rename(columns={"StockCode":"product_id","Quantity":"units_sold"})
prod_sales["opening_stock"] = np.maximum(50, prod_sales["units_sold"] * 2)
prod_sales["closing_stock"] = prod_sales["opening_stock"] - prod_sales["units_sold"]
prod_sales["reorder_level"] = np.maximum(10, np.ceil(prod_sales["units_sold"] * 0.10)).astype(int)
prod_sales["snapshot_date"] = sales["InvoiceDate"].max().date()
prod_sales["stock_status"] = np.select(
    [
        prod_sales["closing_stock"] <= 0,
        prod_sales["closing_stock"] <= prod_sales["reorder_level"]
    ],
    ["OUT_OF_STOCK","LOW_STOCK"],
    default="HEALTHY"
)
inventory = prod_sales[
    ["store_id","product_id","snapshot_date","opening_stock","units_sold",
     "closing_stock","reorder_level","stock_status"]
]

categories.to_csv(OUT/"categories.csv", index=False)
stores.to_csv(OUT/"stores.csv", index=False)
products.to_csv(OUT/"products.csv", index=False)
customers.to_csv(OUT/"customers.csv", index=False)
orders.to_csv(OUT/"orders.csv", index=False, date_format="%Y-%m-%d %H:%M:%S")
order_items.to_csv(OUT/"order_items.csv", index=False)
inventory.to_csv(OUT/"inventory.csv", index=False, date_format="%Y-%m-%d")

print(f"Prepared {len(sales):,} sales rows.")
print(f"Products: {len(products):,}; Customers: {len(customers):,}; Orders: {len(orders):,}")
print(f"Stores: {len(stores):,}; Categories: {len(categories):,}; Inventory rows: {len(inventory):,}")
