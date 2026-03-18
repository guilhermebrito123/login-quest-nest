-- Disable user triggers on diarias_temporarias
ALTER TABLE diarias_temporarias DISABLE TRIGGER USER;

-- José Antônio: c50e010d → 0a404d5f
UPDATE diarias_temporarias 
SET diarista_id = '0a404d5f-37a1-4eec-94fe-7559046af80d' 
WHERE diarista_id = 'c50e010d-0f72-45e2-b9ae-34ab963e3868';

-- Rosimary: f3ed6359 → 92600f80
UPDATE diarias_temporarias 
SET diarista_id = '92600f80-fc04-44ea-92b6-f47d6d39c981' 
WHERE diarista_id = 'f3ed6359-5866-4dae-a6e1-bfc5cedf17ae';

-- Re-enable user triggers
ALTER TABLE diarias_temporarias ENABLE TRIGGER USER;

-- Delete the 3 duplicate diarista records
DELETE FROM diaristas WHERE id = '7a6d37d1-24e7-4d7e-be2f-c9d53aaf11ed';
DELETE FROM diaristas WHERE id = 'c50e010d-0f72-45e2-b9ae-34ab963e3868';
DELETE FROM diaristas WHERE id = 'f3ed6359-5866-4dae-a6e1-bfc5cedf17ae';