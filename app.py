from fastapi import FastAPI, UploadFile, File, HTTPException
import pandas as pd
import io

app = FastAPI(title="Credit Card Application Prediction API")

@app.post("/train")
async def train_model(file: UploadFile = File(...)):
    try:
        contents = await file.read()

        if file.filename.endswith(".csv"):
            df = pd.read_csv(io.BytesIO(contents))
        elif file.filename.endswith((".xlsx", ".xls")):
            df = pd.read_excel(io.BytesIO(contents))
        else:
            raise HTTPException(
                status_code=400,
                detail="Please upload a CSV or Excel file."
            )

        if "label" not in df.columns:
            raise HTTPException(
                status_code=400,
                detail="The uploaded file must contain a label column."
            )

        return {
            "message": "File uploaded successfully.",
            "rows": len(df),
            "columns": len(df.columns),
            "label_counts": df["label"].value_counts().to_dict()
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Step 2: Import tools required for model training
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.metrics import accuracy_score
import joblib
import os

# Step 3: Prepare the dataset for model training
MODEL_FILE = "credit_card_model.joblib"

@app.post("/train-model")
async def train_model_endpoint(file: UploadFile = File(...)):
    contents = await file.read()

    try:
        if file.filename.endswith(".csv"):
            df = pd.read_csv(io.BytesIO(contents))
        elif file.filename.endswith((".xlsx", ".xls")):
            df = pd.read_excel(io.BytesIO(contents))
        else:
            raise HTTPException(status_code=400, detail="Upload a CSV or Excel file.")

        # Make column names consistent
        df.columns = df.columns.str.strip().str.lower()

        if "label" not in df.columns:
            raise HTTPException(status_code=400, detail="Dataset must contain a label column.")

        # Separate input features from the target label
        X = df.drop(columns=["label", "ind_id", "id"], errors="ignore")
        y = df["label"]

        if y.nunique() < 2:
            raise HTTPException(status_code=400, detail="Training data must contain both label classes.")

        # Identify numerical and categorical columns
        numerical_columns = X.select_dtypes(include=["number"]).columns.tolist()
        categorical_columns = X.select_dtypes(exclude=["number"]).columns.tolist()

        # Fill missing values and convert categories into numbers
        preprocessing = ColumnTransformer([
            ("numbers", SimpleImputer(strategy="median"), numerical_columns),
            ("categories", Pipeline([
                ("fill_missing", SimpleImputer(strategy="most_frequent")),
                ("encode", OneHotEncoder(handle_unknown="ignore"))
            ]), categorical_columns)
        ])

        # Create the model pipeline
        model = Pipeline([
            ("preprocessing", preprocessing),
            ("classifier", RandomForestClassifier(
                n_estimators=100, random_state=42, class_weight="balanced"
            ))
        ])

        # Split data for training and evaluation
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        model.fit(X_train, y_train)
        predictions = model.predict(X_test)
        accuracy = accuracy_score(y_test, predictions)

        # Save the trained model for the inference endpoint
        joblib.dump(model, MODEL_FILE)

        return {
            "message": "Model trained successfully.",
            "training_rows": len(X_train),
            "testing_rows": len(X_test),
            "accuracy": round(float(accuracy), 4),
            "model_file": MODEL_FILE
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
# Step 4: Inference endpoint - predict using the trained model

@app.post("/predict")
async def predict_model(file: UploadFile = File(...)):
    try:
        # Check whether a trained model exists
        if not os.path.exists(MODEL_FILE):
            raise HTTPException(
                status_code=400,
                detail="Train the model first using /train-model."
            )

        # Read the uploaded CSV or Excel file
        contents = await file.read()

        if file.filename.endswith(".csv"):
            df = pd.read_csv(io.BytesIO(contents))
        elif file.filename.endswith((".xlsx", ".xls")):
            df = pd.read_excel(io.BytesIO(contents))
        else:
            raise HTTPException(
                status_code=400,
                detail="Upload a CSV or Excel file."
            )

        # Make column names consistent
        df.columns = df.columns.str.strip().str.lower()

        # Remove the target label if it is present
        X = df.drop(columns=["label", "ind_id", "id"], errors="ignore")

        # Load the saved model and predict
        model = joblib.load(MODEL_FILE)
        predictions = model.predict(X)

        return {
            "message": "Predictions generated successfully.",
            "predictions": predictions.tolist()
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))    