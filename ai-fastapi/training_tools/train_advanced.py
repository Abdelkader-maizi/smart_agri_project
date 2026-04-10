import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg') # for headless environments
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import joblib

print("Loading dataset...")
try:
    df = pd.read_csv('data.csv')
except FileNotFoundError:
    print("Error: data.csv not found.")
    sys.exit(1)

X = df[['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']]
y = df['label']

print(f"Dataset shape: {df.shape}")

# Stratify ensure balanced classes in split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

print("Starting Hyperparameter Tuning (GridSearchCV)...")
param_grid = {
    'n_estimators': [50, 100],
    'max_depth': [None, 10, 20],
    'min_samples_split': [2, 5]
}

rf = RandomForestClassifier(random_state=42)
grid_search = GridSearchCV(estimator=rf, param_grid=param_grid, cv=3, n_jobs=-1, verbose=1)

grid_search.fit(X_train, y_train)

best_model = grid_search.best_estimator_
print(f"\nBest parameters found: {grid_search.best_params_}")

print("\nEvaluating the best model...")
y_pred = best_model.predict(X_test)
acc = accuracy_score(y_test, y_pred)
print(f"Accuracy: {acc * 100:.2f}%\n")
print("Classification Report:")
print(classification_report(y_test, y_pred))

joblib.dump(best_model, 'model/model.pkl')
print(f"Model successfully saved to model/model.pkl")

print("Generating Feature Importance graph...")
importances = best_model.feature_importances_
feature_names = X.columns
feat_df = pd.DataFrame({'Feature': feature_names, 'Importance': importances})
feat_df = feat_df.sort_values(by='Importance', ascending=False)

plt.figure(figsize=(10, 6))
sns.barplot(x='Importance', y='Feature', data=feat_df, hue='Feature', legend=False, palette='viridis')
plt.title('Crop Yield Factors - Feature Importance')
plt.xlabel('Importance (Impact on AI decision)')
plt.ylabel('Factors')

plt.tight_layout()
plt.savefig('feature_importance.png', dpi=300)
print("Graph saved as feature_importance.png")

print("Calibration complete.")
