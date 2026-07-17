from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func
import enum

from app.database import Base


class TransactionType(str, enum.Enum):
    buy = "buy"
    sell = "sell"


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    asset_name = Column(String, nullable=False)       # örn: "Bitcoin", "Altın"
    transaction_type = Column(Enum(TransactionType), nullable=False)  # buy / sell
    quantity = Column(Float, nullable=False)           # miktar
    price_per_unit = Column(Float, nullable=False)     # birim fiyat
    total_amount = Column(Float, nullable=False)       # quantity * price_per_unit

    transaction_date = Column(DateTime(timezone=True), server_default=func.now())
    is_favorite = Column(Integer, default=0)           # 0 = hayır, 1 = evet

    created_at = Column(DateTime(timezone=True), server_default=func.now())