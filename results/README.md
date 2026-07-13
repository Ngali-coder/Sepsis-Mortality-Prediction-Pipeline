# Results and Findings

## Overview

Three machine learning algorithms were developed and evaluated for early mortality prediction in septic ICU patients:

- Logistic Regression
- Support Vector Machine (SVM)
- Feed-forward Artificial Neural Network (PyTorch)

All models were trained using the same clinically informed preprocessing pipeline, feature engineering strategy, and leakage-safe train/validation/test protocol to ensure a fair comparison.

---

# Exploratory Data Analysis Findings

The exploratory analysis revealed several important characteristics of the clinical dataset before model development.

### Clinical observations

The dataset contained:

- Missing laboratory measurements resulting from selective clinical test ordering.
- Physiologically impossible values that required validation before preprocessing.
- Highly skewed laboratory biomarkers requiring transformation.
- Strong class imbalance between survivors and non-survivors.
- Highly correlated physiological measurements that increased model redundancy.

These findings justified the need for:

- Missing-value imputation
- Outlier treatment
- Feature transformation
- Correlation-based feature selection
- SMOTE applied exclusively to the training partition

Overall, the exploratory analysis confirmed that careful preprocessing was essential before developing reliable mortality prediction models. :contentReference[oaicite:2]{index=2}

---

# Model Performance Comparison

Three algorithms were evaluated after preprocessing and hyperparameter optimization.

| Model | Main Strength | Main Limitation |
|-------|---------------|-----------------|
| Logistic Regression | Best balance between discrimination, specificity, interpretability and generalization | Slightly lower recall than the Neural Network |
| Support Vector Machine | Excellent cross-validation ROC-AUC during tuning | Failed to generalize on validation data due to severe overfitting |
| Neural Network | Highest mortality recall | Lower specificity and increased false-positive predictions |

The comparison demonstrated that model complexity alone did not guarantee superior clinical performance.

Although the Neural Network captured more mortality cases, Logistic Regression produced a considerably better balance between discrimination, calibration, and clinical reliability. 

---

# Support Vector Machine Findings

Hyperparameter optimization substantially improved cross-validation performance, achieving a ROC-AUC of approximately **0.93** during training.

However, independent validation revealed severe overfitting.

The tuned SVM failed to identify mortality cases correctly, producing:

| Metric | Tuned SVM |
|---------|----------:|
| Recall | 0% |
| Specificity | 100% |
| ROC-AUC | 0.563 |
| PR-AUC | 0.325 |

Although highly specific, the model classified nearly every patient as a survivor.

From a clinical perspective, this behaviour is unacceptable because critically ill patients would be missed. The results emphasize the importance of evaluating models on independent validation data rather than relying solely on cross-validation performance. :contentReference[oaicite:4]{index=4}

---

# Neural Network Findings

Hyperparameter optimization explored multiple neural-network architectures using combinations of:

- Hidden-layer configurations
- Dropout rates
- Learning rates
- Batch sizes

The tuned model substantially improved mortality detection.

| Metric | Baseline NN | Tuned NN |
|---------|------------:|----------:|
| Accuracy | 74.2% | 65.8% |
| Precision | 59.1% | 47.0% |
| Recall | 56.7% | **73.9%** |
| Specificity | 82.1% | 62.2% |
| ROC-AUC | 0.749 | 0.751 |
| PR-AUC | 0.603 | 0.601 |

Increasing recall reduced the number of missed mortality cases but also produced substantially more false-positive predictions.

Clinically, the Neural Network behaved like a high-sensitivity early-warning system, prioritizing patient safety over overall classification accuracy. :contentReference[oaicite:5]{index=5}

---

# Logistic Regression Findings

Among all evaluated algorithms, the tuned Logistic Regression model consistently demonstrated the most balanced predictive performance.

Unlike the Neural Network, it maintained good discrimination while avoiding excessive false-positive predictions.

Unlike the SVM, it generalized reliably to unseen patients.

The model also remained highly interpretable, allowing clinicians to understand how important physiological variables influenced mortality risk.

Feature analysis showed that biomarkers including:

- Lactate
- Creatinine
- White blood cell count
- SOFA score
- Vasopressor administration
- Renal-function indicators

were among the strongest contributors to mortality prediction, aligning well with established clinical knowledge. :contentReference[oaicite:6]{index=6}

---

# Final Independent Test Performance

After model selection, the tuned Logistic Regression model was retrained using the combined training and validation datasets before evaluation on the untouched independent test set.

| Metric | Final Logistic Regression |
|---------|--------------------------:|
| Accuracy | **74.3%** |
| Precision | **58.6%** |
| Recall (Sensitivity) | **60.4%** |
| Specificity | **80.6%** |
| F1-score | **59.5%** |
| ROC-AUC | **0.788** |
| PR-AUC | **0.661** |

The confusion matrix showed that the model successfully identified high-risk mortality cases while maintaining a relatively low false-alarm rate.

These results demonstrate reliable discrimination between survivors and non-survivors while preserving clinically meaningful interpretability. :contentReference[oaicite:7]{index=7}

---

# Key Findings

The experiments produced several important observations:

- Careful preprocessing had a significant impact on model stability and generalization.
- Physiological validation before preprocessing prevented clinically meaningful extreme observations from being incorrectly removed.
- Leakage-safe preprocessing produced trustworthy evaluation results.
- Logistic Regression outperformed more complex models in terms of overall clinical usefulness.
- Hyperparameter optimization alone could not prevent SVM overfitting.
- Higher recall does not necessarily imply better clinical performance when accompanied by excessive false positives.
- Clinically informed feature engineering substantially improved prediction quality.

---

# Final Model Selection

The tuned Logistic Regression model was selected as the final model because it achieved the best overall balance between:

- Predictive discrimination
- Sensitivity
- Specificity
- Precision
- Generalization
- Clinical interpretability

Although the Neural Network detected a greater proportion of mortality cases, it generated substantially more false-positive predictions.

Conversely, the tuned SVM exhibited severe overfitting and failed to generalize to unseen patients.

For a clinical decision-support application, balanced performance and interpretability were considered more valuable than maximizing a single evaluation metric.

Therefore, the tuned Logistic Regression model was selected as the most appropriate model for mortality prediction in septic ICU patients. 
