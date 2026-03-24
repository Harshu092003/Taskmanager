from pydantic import BaseModel
from typing import Optional
from enum import Enum


class TaskStatus(str, Enum):
    todo = "To-Do"
    in_progress = "In Progress"
    done = "Done"


class TaskBase(BaseModel):
    title: str
    description: Optional[str] = ""
    due_date: str  # ISO date string e.g. "2025-12-31"
    status: TaskStatus = TaskStatus.todo
    blocked_by_id: Optional[str] = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(TaskBase):
    pass


class TaskResponse(TaskBase):
    id: str
    blocked_by_title: Optional[str] = None

    model_config = {"from_attributes": True}