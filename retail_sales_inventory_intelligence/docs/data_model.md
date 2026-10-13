# Data Model

```text
categories 1 ──── * products
customers  1 ──── * orders
stores     1 ──── * orders
orders     1 ──── * order_items
products   1 ──── * order_items
stores     1 ──── * inventory
products   1 ──── * inventory
```

## Grain
- categories: one row per derived product category.
- products: one row per StockCode.
- customers: one row per known CustomerID.
- stores: one row per derived virtual region.
- orders: one row per InvoiceNo.
- order_items: one row per invoice/product line.
- inventory: one row per store/product planning snapshot.

## Key design choice
`orders` and `order_items` preserve the transaction grain from the source while dimensions are separated for relational analysis.
