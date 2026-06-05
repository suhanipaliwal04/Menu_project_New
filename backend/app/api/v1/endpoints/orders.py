from fastapi import APIRouter, HTTPException, Depends
from typing import List
from sqlalchemy import text
from app.core.database import get_db
import uuid

from app.schemas.order import OrderCreate, OrderResponse, OrderUpdate
from app.core.auth_roles import get_current_restaurant_admin

router = APIRouter()

@router.post("/takeaway", response_model=OrderResponse)
def create_takeaway_order(order_data: OrderCreate, db=Depends(get_db)):
    try:
        # Check if restaurant exists
        res = db.execute(text("SELECT restaurant_id FROM restaurants WHERE restaurant_id = :rid"), {"rid": str(order_data.restaurant_id)}).fetchone()
        if not res:
            raise HTTPException(status_code=404, detail="Restaurant not found")

        # Insert order
        order_id_res = db.execute(text("""
            INSERT INTO orders (restaurant_id, customer_name, customer_phone, time_slot, total_amount, status)
            VALUES (:rid, :cname, :cphone, :tslot, :tamount, 'PENDING')
            RETURNING order_id, status, created_at, updated_at
        """), {
            "rid": str(order_data.restaurant_id),
            "cname": order_data.customer_name,
            "cphone": order_data.customer_phone,
            "tslot": order_data.time_slot,
            "tamount": order_data.total_amount
        })
        order_row = order_id_res.fetchone()
        db.commit()

        order_id = str(order_row[0])

        # Insert order items
        if order_data.items:
            for item in order_data.items:
                db.execute(text("""
                    INSERT INTO order_items (order_id, item_id, item_name, quantity, price)
                    VALUES (:oid, :iid, :iname, :qty, :prc)
                """), {
                    "oid": order_id,
                    "iid": str(item.item_id) if item.item_id else None,
                    "iname": item.item_name,
                    "qty": item.quantity,
                    "prc": item.price
                })
            db.commit()

        # Fetch inserted order to return
        return get_order_by_id(order_id, db)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/restaurants/{restaurant_id}/orders", response_model=List[OrderResponse])
def get_admin_orders(restaurant_id: uuid.UUID, admin=Depends(get_current_restaurant_admin), db=Depends(get_db)):
    try:
        # Fetch orders
        orders_res = db.execute(text("""
            SELECT order_id, restaurant_id, customer_name, customer_phone, time_slot, total_amount, status, created_at, updated_at
            FROM orders
            WHERE restaurant_id = :rid
            ORDER BY created_at DESC
        """), {"rid": str(restaurant_id)}).fetchall()

        orders_list = []
        for row in orders_res:
            oid = str(row[0])
            # Fetch items for this order
            items_res = db.execute(text("""
                SELECT order_item_id, order_id, item_id, item_name, quantity, price
                FROM order_items
                WHERE order_id = :oid
            """), {"oid": oid}).fetchall()

            items = []
            for irow in items_res:
                items.append({
                    "order_item_id": irow[0],
                    "order_id": irow[1],
                    "item_id": irow[2],
                    "item_name": irow[3],
                    "quantity": irow[4],
                    "price": float(irow[5])
                })

            orders_list.append({
                "order_id": row[0],
                "restaurant_id": row[1],
                "customer_name": row[2],
                "customer_phone": row[3],
                "time_slot": row[4],
                "total_amount": float(row[5]),
                "status": row[6],
                "created_at": row[7],
                "updated_at": row[8],
                "items": items
            })

        return orders_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/admin/orders/{order_id}", response_model=OrderResponse)
def update_order_status(order_id: uuid.UUID, update_data: OrderUpdate, admin=Depends(get_current_restaurant_admin), db=Depends(get_db)):
    try:
        res = db.execute(text("""
            UPDATE orders
            SET status = :status
            WHERE order_id = :oid
            RETURNING order_id
        """), {"status": update_data.status, "oid": str(order_id)})
        
        if not res.fetchone():
            raise HTTPException(status_code=404, detail="Order not found")
            
        db.commit()
        return get_order_by_id(str(order_id), db)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

def get_order_by_id(order_id: str, db):
    row = db.execute(text("SELECT order_id, restaurant_id, customer_name, customer_phone, time_slot, total_amount, status, created_at, updated_at FROM orders WHERE order_id = :oid"), {"oid": order_id}).fetchone()
    if not row:
        return None

    items_res = db.execute(text("SELECT order_item_id, order_id, item_id, item_name, quantity, price FROM order_items WHERE order_id = :oid"), {"oid": order_id}).fetchall()
    
    items = []
    for irow in items_res:
        items.append({
            "order_item_id": irow[0],
            "order_id": irow[1],
            "item_id": irow[2],
            "item_name": irow[3],
            "quantity": irow[4],
            "price": float(irow[5])
        })

    return {
        "order_id": row[0],
        "restaurant_id": row[1],
        "customer_name": row[2],
        "customer_phone": row[3],
        "time_slot": row[4],
        "total_amount": float(row[5]),
        "status": row[6],
        "created_at": row[7],
        "updated_at": row[8],
        "items": items
    }
