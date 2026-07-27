---
name: ml-classification-pipeline
description: Build end-to-end binary classification pipeline with staged execution, proper validation, and common pitfall avoidance for sklearn/XGBoost/LightGBM.
category: data-science
---

# ML Classification Pipeline - Robust Implementation

## Purpose
Build end-to-end binary classification pipeline with staged execution, proper validation, and common pitfall avoidance.

## Architecture: Staged Pipeline

Each stage produces:
1. `plan_stage_X.md` - what to do
2. `etapX_*.py` - executable script
3. `results_stage_X.json` - machine-readable results
4. `insights_stage_X.md` - human-readable analysis, recommendations

**Stage 1:** Data loading, EDA, filtering, train/val/test split
**Stage 2:** Feature engineering, encoding, imputation
**Stage 3:** Model training, hyperparameter tuning, validation, best model selection
**Stage 4:** Advanced tuning (Optuna), ensemble methods, calibration
**Stage 5:** Feature selection, final model, 5-fold CV, final report

## Critical Pitfalls and Fixes

### sklearn / joblib Issues
- **NEVER use `n_jobs=-1` in GridSearchCV/RandomizedSearchCV** - causes IPC deadlocks; use `n_jobs=4`
- **NEVER use `SuppressStderr`** context manager - breaks joblib worker communication
- **NEVER use `multi_class="multinomial"`** in LogisticRegression - removed in sklearn 1.8+
- Use `RandomizedSearchCV` over `GridSearchCV` - faster, fewer deadlock issues

### LabelEncoder Unseen Labels
When applying LabelEncoder trained on training set to val/test sets, unseen labels cause `KeyError`. Fix:

```python
# During training - include 'UNKNOWN' as a class
le = LabelEncoder()
all_vals = df[col].astype(str).unique().tolist() + ['UNKNOWN']
le.fit(all_vals)
df[col] = le.transform(df[col].astype(str))

# During inference - map unseen to 'UNKNOWN'
known = set(le.classes_)
df[col] = df[col].astype(str).apply(lambda x: 'UNKNOWN' if x not in known else x)
df[col] = le.transform(df[col].astype(str))
```

### VIF Calculation
VIF fails on label-encoded categorical columns (raises exception for every column). Either:
- Only compute VIF on truly numeric features
- Catch exceptions and mark as -1 (not computable)
- Skip VIF entirely for tree-based models (they handle multicollinearity)

### Data Format
- Use CSV instead of parquet unless pyarrow/fastparquet installed
- Always specify `encoding='utf-8'` for CSV with non-ASCII characters

### Class Imbalance
- Use `class_weight='balanced'` for RF/LGBM
- Use `scale_pos_weight` for XGBoost: `(neg_count) / max(pos_count, 1)`
- Prefer `f1_macro` as primary metric over accuracy

### Data Leakage Prevention
- Do NOT compute temporal features relative to "today" if data is historical
- LabelEncoder must be fit ONLY on training data
- Imputation statistics must be computed ONLY on training data
- Feature selection must happen inside CV folds

### Optuna Hyperparameter Tuning
- **NEVER use `log=True` with `low=0`** in `trial.suggest_float()` - raises ValueError; use `low=1e-5` instead
- Use `TPESampler(seed=42)` for reproducibility
- 30-50 trials per model is sufficient; diminishing returns after ~50
- Use 5-fold stratified CV inside the objective function for robust scoring
- Pin `n_jobs=4` in model params during Optuna to avoid IPC issues

### Feature Selection Pitfalls
- Iterative feature removal (bottom-up) may NOT improve results - removing even "least important" features can hurt model performance if tree models use them as weak splits
- Test with small removals (3-5 at a time) and stop immediately when metrics degrade
- Protect domain-critical features (e.g., network membership one-hot) from removal
- If removal doesn't help, keep the full feature set

### Ensemble Pitfalls
- Voting/Stacking may NOT improve over single best model - always compare against baseline first
- If ensemble underperforms, the individual models are likely already well-tuned
- Stacking is especially prone to overfitting on small datasets

### Calibration
- CalibratedClassifierCV improves Brier score but often does NOT improve F1/accuracy
- Use calibration when reliable probabilities matter more than classification accuracy

## Model Recommendations

For datasets with 30-50 features, ~8000 rows:

1. **Baseline:** LogisticRegression (scaled), RandomForest, XGBoost, LightGBM
2. **Tuned:** Same models with RandomizedSearchCV (n_iter=30, 5-fold stratified CV)
3. **GradientBoosting (sklearn)** often best general-purpose performer
4. **LightGBM** often highest AUC but prone to overfitting - check train-test gap

Expected realistic accuracy: 85-92%. If any model achieves >98%, investigate data leakage.

## Feature Engineering Patterns

For list columns (comma-separated strings):
- Count of items: `len(items)`
- Unique types: `len(set(items))`
- Binary presence flag
- Most common type

For categorical columns with high cardinality:
- Standardize/normalize values (e.g., network names)
- Group into meaningful categories
- Use LabelEncoder with 'UNKNOWN' class for unseen values

For date columns stored as strings:
- Parse with `pd.to_datetime(errors='coerce')`
- Extract: year, month, dayofweek
- Compute time deltas (careful about reference date)

## Verification Steps

After each stage:
1. Check for remaining NaN (should be 0)
2. Verify feature count matches expectations
3. Check class distribution preserved across splits
4. Verify no data leakage between train/val/test