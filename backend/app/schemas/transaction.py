from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.models.transaction import TransactionType


class TransactionCreate(BaseModel):
    asset_name: str
    transaction_type: TransactionType
    quantity: float
    price_per_unit: float


class TransactionOut(BaseModel):
    id: int
    user_id: int
    asset_name: str
    transaction_type: TransactionType
    quantity: float
    price_per_unit: float
    total_amount: float
    transaction_date: datetime
    is_favorite: int

    model_config = ConfigDict(from_attributes=True)


class TransactionUpdate(BaseModel):
    asset_name: str | None = None
    quantity: float | None = None
    price_per_unit: float | None = None
    is_favorite: bool | None = None