from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.transaction import Transaction, TransactionType
from app.schemas.transaction import TransactionCreate, TransactionOut, TransactionUpdate
from app.core.security import get_current_user

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.post("/", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
    transaction_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total_amount = transaction_in.quantity * transaction_in.price_per_unit

    new_transaction = Transaction(
        user_id=current_user.id,
        asset_name=transaction_in.asset_name,
        transaction_type=transaction_in.transaction_type,
        quantity=transaction_in.quantity,
        price_per_unit=transaction_in.price_per_unit,
        total_amount=total_amount,
    )
    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)
    return new_transaction


@router.get("/", response_model=list[TransactionOut])
def list_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.transaction_date.desc())
        .all()
    )
    return transactions


@router.get("/{transaction_id}", response_model=TransactionOut)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction = (
        db.query(Transaction)
        .filter(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
        .first()
    )
    if not transaction:
        raise HTTPException(status_code=404, detail="İşlem bulunamadı.")
    return transaction


@router.put("/{transaction_id}", response_model=TransactionOut)
def update_transaction(
    transaction_id: int,
    transaction_in: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction = (
        db.query(Transaction)
        .filter(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
        .first()
    )
    if not transaction:
        raise HTTPException(status_code=404, detail="İşlem bulunamadı.")

    update_data = transaction_in.model_dump(exclude_unset=True)

    if "is_favorite" in update_data:
        update_data["is_favorite"] = 1 if update_data["is_favorite"] else 0

    for field, value in update_data.items():
        setattr(transaction, field, value)

    if "quantity" in update_data or "price_per_unit" in update_data:
        transaction.total_amount = transaction.quantity * transaction.price_per_unit

    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction = (
        db.query(Transaction)
        .filter(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
        .first()
    )
    if not transaction:
        raise HTTPException(status_code=404, detail="İşlem bulunamadı.")

    db.delete(transaction)
    db.commit()
    return None

@router.get("/summary/portfolio")
def get_portfolio_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .all()
    )

    assets: dict[str, dict] = {}

    for t in transactions:
        if t.asset_name not in assets:
            assets[t.asset_name] = {
                "asset_name": t.asset_name,
                "total_bought_quantity": 0.0,
                "total_bought_amount": 0.0,
                "total_sold_quantity": 0.0,
                "total_sold_amount": 0.0,
            }

        if t.transaction_type == TransactionType.buy:
            assets[t.asset_name]["total_bought_quantity"] += t.quantity
            assets[t.asset_name]["total_bought_amount"] += t.total_amount
        else:
            assets[t.asset_name]["total_sold_quantity"] += t.quantity
            assets[t.asset_name]["total_sold_amount"] += t.total_amount

    result = []
    total_portfolio_value = 0.0
    total_profit_loss = 0.0

    for asset_name, data in assets.items():
        remaining_quantity = data["total_bought_quantity"] - data["total_sold_quantity"]
        profit_loss = data["total_sold_amount"] - (
            data["total_bought_amount"]
            * (data["total_sold_quantity"] / data["total_bought_quantity"])
            if data["total_bought_quantity"] > 0 else 0
        )

        avg_buy_price = (
            data["total_bought_amount"] / data["total_bought_quantity"]
            if data["total_bought_quantity"] > 0 else 0
        )
        current_holding_value = remaining_quantity * avg_buy_price

        result.append({
            "asset_name": asset_name,
            "remaining_quantity": remaining_quantity,
            "avg_buy_price": round(avg_buy_price, 2),
            "current_holding_value": round(current_holding_value, 2),
            "realized_profit_loss": round(profit_loss, 2),
        })

        total_portfolio_value += current_holding_value
        total_profit_loss += profit_loss

    return {
        "assets": result,
        "total_portfolio_value": round(total_portfolio_value, 2),
        "total_realized_profit_loss": round(total_profit_loss, 2),
    }