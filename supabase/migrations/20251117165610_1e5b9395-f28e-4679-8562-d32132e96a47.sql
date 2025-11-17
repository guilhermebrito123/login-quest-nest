-- Add foreign key constraints to supervisor_id columns referencing profiles table

-- Add foreign key to execucao_checklist.supervisor_id
ALTER TABLE public.execucao_checklist
  DROP CONSTRAINT IF EXISTS execucao_checklist_supervisor_id_fkey,
  ADD CONSTRAINT execucao_checklist_supervisor_id_fkey 
    FOREIGN KEY (supervisor_id) 
    REFERENCES public.profiles(id) 
    ON DELETE SET NULL;

-- Add foreign key to execucao_checklist_item.supervisor_id
ALTER TABLE public.execucao_checklist_item
  DROP CONSTRAINT IF EXISTS execucao_checklist_item_supervisor_id_fkey,
  ADD CONSTRAINT execucao_checklist_item_supervisor_id_fkey 
    FOREIGN KEY (supervisor_id) 
    REFERENCES public.profiles(id) 
    ON DELETE SET NULL;