"""Score every customer with the churn model and export the dataset used by the Power BI report.

Scores are out-of-fold (5-fold cross-validation), so no customer is scored by a model that saw
them during training. The model matches the notebook: logistic regression on one-hot encoded
features, with MonthlyCharges and TotalCharges left out.

Run from the repository root:
    python powerbi/scripts/score_customers.py
"""
from pathlib import Path

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "data" / "telco_customer_churn.csv"
TARGET = ROOT / "powerbi" / "data" / "customers_scored.csv"

df = pd.read_csv(SOURCE)
y = (df["Churn"] == "Yes").astype(int)

features = df.drop(columns=["customerID", "Churn", "TotalCharges", "MonthlyCharges"])
features["SeniorCitizen"] = features["SeniorCitizen"].map({0: "No", 1: "Yes"})
X = pd.get_dummies(features, drop_first=True, dtype=float)

model = make_pipeline(StandardScaler(), LogisticRegression(max_iter=2000))
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
score = cross_val_predict(model, X, y, cv=cv, method="predict_proba")[:, 1]
print(f"Out-of-fold ROC-AUC: {roc_auc_score(y, score):.3f}")

# Rank 1 = riskiest customer. Decile 1 = riskiest 10%.
rank = pd.Series(score).rank(ascending=False, method="first").astype(int)
df["RiskScore"] = score.round(4)
df["RiskRank"] = rank
df["RiskDecile"] = ((rank - 1) * 10 // len(df) + 1).astype(int)

TARGET.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(TARGET, index=False, lineterminator="\n")
print(f"Wrote {len(df):,} rows to {TARGET.relative_to(ROOT)}")
