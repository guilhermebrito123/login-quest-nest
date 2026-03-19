
ALTER TABLE public.diarias_temporarias DISABLE TRIGGER USER;

UPDATE public.diarias_temporarias
SET
  status = 'Aprovada',
  lancada_por = NULL,
  lancada_em = NULL,
  updated_at = now() AT TIME ZONE 'America/Sao_Paulo'
WHERE id IN (911, 903, 901)
  AND status = 'Lançada para pagamento';

ALTER TABLE public.diarias_temporarias ENABLE TRIGGER USER;
