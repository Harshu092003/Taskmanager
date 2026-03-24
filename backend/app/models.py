from sqlalchemy import Column, String, Date, Enum, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
import uuid
import enum

Base = declarative_base()

DATABASE_URL = "sqlite+aiosqlite:///./tasks.db"

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class TaskStatus(str, enum.Enum):
    todo = "To-Do"
    in_progress = "In Progress"
    done = "Done"


class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    description = Column(String, default="")
    due_date = Column(String, nullable=False)  # ISO date string
    status = Column(String, default=TaskStatus.todo)
    blocked_by_id = Column(String, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)

    blocked_by = relationship("Task", remote_side="Task.id", foreign_keys=[blocked_by_id])


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session