-- 1. Adicionar 'closed' ao enum kanban
ALTER TYPE public.checklist_task_kanban_status ADD VALUE IF NOT EXISTS 'closed';