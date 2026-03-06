# Dev Debug Scripts

These scripts are **developer utilities** for local debugging and verification.
They are not used by backend startup, API runtime, CI, or production deployment.

## Scripts

- `check_db_logs.py` — prints recent `SystemLog` rows.
- `inspect_db.py` — inspects `questions_status_check` constraints.
- `diag_paths.py` — verifies ML model/labels candidate path resolution.
- `test_prediction.py` — quick ML prediction smoke test.

## Run examples

From repository root:

```bash
backend/venv/bin/python backend/scripts/dev/check_db_logs.py
backend/venv/bin/python backend/scripts/dev/inspect_db.py
backend/venv/bin/python backend/scripts/dev/diag_paths.py
backend/venv/bin/python backend/scripts/dev/test_prediction.py
```
