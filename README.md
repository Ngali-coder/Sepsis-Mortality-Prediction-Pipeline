# Sepsis Mortality Prediction

### An end-to-end clinical machine learning pipeline for early mortality-risk prediction from intensive-care data

Sepsis Mortality Prediction is a clinical machine learning project designed to estimate mortality risk among patients with sepsis using routinely collected demographic, physiological, laboratory, and severity-related variables.

The project demonstrates the complete machine learning lifecycle—from exploratory clinical data analysis and leakage-safe preprocessing to feature selection, model optimization, independent test evaluation, and interpretable clinical reporting.

## Overview

Sepsis is a life-threatening condition caused by a dysregulated response to infection and remains a major source of mortality in intensive-care units.

Early risk stratification may help clinical teams identify high-risk patients, prioritize monitoring, and support timely intervention. However, ICU data present substantial analytical challenges, including:

- Missing laboratory measurements
- Physiologically impossible values
- Clinically meaningful extreme observations
- Highly skewed biomarkers
- Correlated and redundant features
- Class imbalance
- Risk of preprocessing leakage
- The need for clinically interpretable predictions

This project addresses these challenges through a structured, clinically informed machine learning pipeline.

## Problem Statement

The objective is to develop and evaluate machine learning models capable of predicting mortality among patients with sepsis from ICU clinical data.

The project focuses on two complementary goals:

1. Achieving reliable predictive discrimination on unseen patients.
2. Preserving clinical interpretability so that model behaviour can be examined and communicated responsibly.

## Key Features

- Comprehensive exploratory data analysis
- Target-distribution and class-imbalance assessment
- Clinical validation of impossible physiological values
- Missing-value analysis and imputation
- Skewness analysis and feature transformation
- IQR-based outlier clipping
- Correlation and redundancy analysis
- Leakage-safe train, validation and test splitting
- SMOTE applied only to the training partition
- Feature selection for reduced multicollinearity
- Logistic Regression, SVM and neural-network comparison
- Hyperparameter optimization
- Independent test-set evaluation
- ROC and Precision–Recall analysis
- Confusion-matrix evaluation
- Model calibration and interpretability analysis

## Clinical Questions Investigated

The exploratory analysis was designed to examine:

- Which biomarkers are most strongly associated with mortality?
- How do survivors and non-survivors differ physiologically?
- Which clinical variables contain substantial missingness?
- Which measurements are highly skewed or noisy?
- Which extreme values represent data errors versus severe pathology?
- Which features are redundant?
- Which variables provide useful predictive information?

The analysis identified clinically important patterns involving variables such as lactate, SOFA score, renal-function markers, blood pressure, oxygen saturation, pH, and other physiological measurements.

## Machine Learning Workflow

```text
Clinical ICU Dataset
        │
        ▼
Data Quality Assessment
        │
        ▼
Exploratory Clinical Analysis
        │
        ▼
Train / Validation / Test Split
        │
        ▼
Leakage-Safe Preprocessing
        │
        ├── Impossible-value treatment
        ├── Missing-value imputation
        ├── Feature transformation
        ├── Outlier clipping
        └── Feature scaling
        │
        ▼
Training-Only Class Balancing with SMOTE
        │
        ▼
Correlation-Based Feature Selection
        │
        ▼
Model Development
        ├── Logistic Regression
        ├── Support Vector Machine
        └── PyTorch Neural Network
        │
        ▼
Hyperparameter Optimization
        │
        ▼
Validation-Based Model Selection
        │
        ▼
Independent Test Evaluation
```

## Data Preprocessing

### Physiological Plausibility Validation

Clinically impossible values were distinguished from extreme but physiologically plausible measurements.

Examples of invalid measurements included:

- Negative blood-pressure values
- Oxygen saturation outside plausible physiological limits
- Implausible respiratory-rate measurements

Invalid values were converted to missing values before imputation.

Severe but clinically possible observations—such as elevated lactate or creatinine—were retained because they may contain important information about critical illness.

### Missing-Value Handling

Missingness was evaluated for each feature before model development. Imputation parameters were learned exclusively from the training data to prevent information leakage.

### Feature Transformation

Skewed clinical biomarkers were transformed where appropriate to reduce the influence of extreme values and improve model stability.

### Outlier Treatment

Outlier clipping was performed using thresholds estimated from the training partition. This reduced instability while preserving clinically meaningful severe cases.

### Feature Scaling

Continuous variables were scaled using parameters fitted only on training data.

### Class-Imbalance Handling

SMOTE was applied exclusively to the training set. Validation and test data retained their original distributions to ensure unbiased evaluation.

### Leakage Prevention

The dataset was divided into stratified training, validation, and independent test sets before preprocessing.

All preprocessing parameters—including imputation values, scaling statistics, clipping thresholds, transformations and resampling—were derived only from training data.

## Feature Selection

Correlation analysis was used to identify highly redundant variables, particularly minimum, maximum and mean versions of closely related biomarkers.

Feature selection aimed to:

- Reduce multicollinearity
- Improve model stability
- Simplify interpretation
- Preserve clinically meaningful information
- Reduce unnecessary model complexity

## Models Evaluated

### Logistic Regression

A clinically interpretable baseline and final candidate model capable of estimating mortality probabilities and exposing feature-level relationships.

### Support Vector Machine

A nonlinear classification model evaluated for its ability to capture more complex decision boundaries.

### Neural Network

A feed-forward neural network implemented in PyTorch and optimized through architecture and hyperparameter experiments.

## Model Evaluation

Models were evaluated using multiple complementary metrics:

- ROC-AUC
- Precision–Recall AUC
- Accuracy
- Balanced accuracy
- Precision
- Recall and sensitivity
- Specificity
- F1-score
- Confusion matrix
- Calibration analysis

ROC-AUC was used to evaluate discrimination across thresholds, while Precision–Recall analysis was emphasized because mortality prediction involves an imbalanced clinical outcome.

## Model Selection

The tuned Logistic Regression model achieved the best overall balance between:

- Discrimination
- Sensitivity
- Specificity
- Precision
- Interpretability
- Generalization stability

The neural network achieved stronger mortality sensitivity in some experiments but produced more false-positive predictions, reducing specificity.

The tuned Logistic Regression model was therefore selected for final independent test evaluation.

This result also demonstrates an important machine learning principle: greater model complexity does not automatically produce better real-world performance.

## Technology Stack

### Programming and Data Analysis

- Python
- Pandas
- NumPy
- SciPy

### Machine Learning

- Scikit-learn
- Imbalanced-learn
- PyTorch

### Visualization

- Matplotlib
- Seaborn

### Methods

- Logistic Regression
- Support Vector Machines
- Artificial Neural Networks
- SMOTE
- Cross-validation
- Hyperparameter optimization
- Calibration analysis
- Feature selection

## Project Structure

```text
Sepsis-Mortality-Prediction/
├── README.md
├── LICENSE
├── requirements.txt
├── .gitignore
│
├── notebooks/
│   └── sepsis_mortality_prediction.ipynb
│
├── src/
├── data/
│   └── README.md
├── models/
├── results/
└── images/
```

## Installation

Clone the repository:

```bash
git clone https://github.com/Ngali-coder/Sepsis-Mortality-Prediction.git
cd Sepsis-Mortality-Prediction-Pipeline
```

Create a virtual environment:

```bash
python -m venv .venv
```

Activate it on Windows:

```bash
.venv\Scripts\activate
```

Activate it on macOS or Linux:

```bash
source .venv/bin/activate
```

Install the dependencies:

```bash
pip install -r requirements.txt
```

Launch Jupyter:

```bash
jupyter notebook
```

Then open:

```text
notebooks/sepsis_mortality_prediction.ipynb
```

## Dataset Access and Privacy

This project uses an ICU clinical dataset derived from sepsis-related patient records.

The underlying patient-level data are **not included in this repository** because clinical datasets may be governed by privacy, licensing, credentialing, or data-use restrictions.

Users must obtain authorized access to the relevant dataset and place their local copy in the appropriate data directory.


## Results and Visualizations

The notebook generates:

- Mortality class-distribution plots
- Missing-value visualizations
- Biomarker KDE plots
- Boxplots and histograms
- Outlier summaries
- Correlation matrices
- Feature-strength analyses
- Confusion matrices
- ROC curves
- Precision–Recall curves
- Calibration plots
- Baseline-versus-tuned model comparisons
- Independent test-set evaluation


## Limitations

- Retrospective clinical data may contain documentation bias.
- Results may not generalize across hospitals or patient populations without external validation.
- Missingness may reflect clinical decision-making rather than random absence.
- SMOTE-generated observations do not represent real patients.
- The model is intended for research and educational use, not direct clinical deployment.
- Prospective validation is required before any clinical application.

## Responsible Use

This repository is a research and educational demonstration.

It must not be used as a standalone diagnostic system or as a substitute for professional clinical judgment. Any future clinical application would require:

- External validation
- Prospective evaluation
- Bias and fairness assessment
- Clinical-governance approval
- Privacy and security review
- Regulatory compliance
- Continuous performance monitoring

## Future Improvements

- External validation on data from additional hospitals
- Temporal validation across different admission periods
- Survival-analysis modelling
- Explainability with SHAP
- Fairness assessment across demographic groups
- Probability-threshold optimization based on clinical costs
- Model uncertainty estimation
- Reproducible preprocessing modules under `src/`
- Experiment tracking with MLflow
- Dockerized inference service
- FastAPI model-serving endpoint
- Cloud deployment and model monitoring

## License

This project is released under the MIT License.

The license applies to the source code and documentation only. It does not grant permission to redistribute any third-party clinical dataset.

## Author

**Ngali Abiru**

AI/ML Engineer · Machine Learning Engineer · Data Engineer  
M.Sc. Artificial Intelligence in Digital Health  
Vrije Universiteit Brussel

If this project is useful to you, consider starring the repository.
