from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from typing import Optional
import asyncio

from app.models import get_db, Task
from app.schemas import TaskCreate, TaskUpdate, TaskResponse

router = APIRouter(prefix="/tasks", tags=["tasks"])


async def _build_response(task: Task, db: AsyncSession) -> TaskResponse:
    blocked_by_title = None
    if task.blocked_by_id:
        result = await db.execute(select(Task).where(Task.id == task.blocked_by_id))
        blocker = result.scalar_one_or_none()
        if blocker:
            blocked_by_title = blocker.title

    return TaskResponse(
        id=task.id,
        title=task.title,
        description=task.description or "",
        due_date=task.due_date,
        status=task.status,
        blocked_by_id=task.blocked_by_id,
        blocked_by_title=blocked_by_title,
    )


@router.get("/", response_model=list[TaskResponse])
async def list_tasks(
    search: Optional[str] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(Task)
    if search:
        query = query.where(Task.title.ilike(f"%{search}%"))
    if status:
        query = query.where(Task.status == status)
    result = await db.execute(query)
    tasks = result.scalars().all()
    return [await _build_response(t, db) for t in tasks]


@router.post("/", response_model=TaskResponse, status_code=201)
async def create_task(payload: TaskCreate, db: AsyncSession = Depends(get_db)):
    # Validate blocked_by_id exists
    if payload.blocked_by_id:
        res = await db.execute(select(Task).where(Task.id == payload.blocked_by_id))
        if not res.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Blocking task not found")

    await asyncio.sleep(2)  # Simulated delay

    task = Task(
        title=payload.title,
        description=payload.description,
        due_date=payload.due_date,
        status=payload.status.value,
        blocked_by_id=payload.blocked_by_id,
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return await _build_response(task, db)


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return await _build_response(task, db)


@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(task_id: str, payload: TaskUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if payload.blocked_by_id and payload.blocked_by_id == task_id:
        raise HTTPException(status_code=400, detail="Task cannot block itself")

    if payload.blocked_by_id:
        res = await db.execute(select(Task).where(Task.id == payload.blocked_by_id))
        if not res.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Blocking task not found")

    await asyncio.sleep(5)  # Simulated delay

    task.title = payload.title
    task.description = payload.description
    task.due_date = payload.due_date
    task.status = payload.status.value
    task.blocked_by_id = payload.blocked_by_id

    await db.commit()
    await db.refresh(task)
    return await _build_response(task, db)


@router.delete("/{task_id}", status_code=204)
async def delete_task(task_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    await db.delete(task)
    await db.commit()