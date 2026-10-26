from fastapi import FastAPI, HTTPException
import pandas as pd
import joblib
from fastapi import UploadFile, File
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
import io

app = FastAPI()

MODEL_FILE_NAME = "linear_regression_pipeline.pkl"

# Load the trained model pipeline
model = joblib.load(MODEL_FILE_NAME)

# Housing features used by the trained model
FEATURE_COLUMNS = [
    "area",
    "bedrooms",
    "bathrooms",
    "stories",
    "mainroad",
    "guestroom",
    "basement",
    "hotwaterheating",
    "airconditioning",
    "parking",
    "prefarea",
    "furnishingstatus"
]


# Add the prediction endpoint
@app.post("/predict")
def predict_house_price(inference_data: dict):
    # Check whether all required housing features are provided
    missing_columns = [
        column for column in FEATURE_COLUMNS
        if column not in inference_data
    ]

    if missing_columns:
        raise HTTPException(
            status_code=400,
            detail=f"Missing features: {missing_columns}"
        )

    # Convert the input into a DataFrame
    input_data = pd.DataFrame([inference_data])
    input_data = input_data[FEATURE_COLUMNS]

    # Predict the house price
    prediction = model.predict(input_data)

    return {"predicted_price": float(prediction[0])}

# Connect to the Linear Regression assignment database
DATABASE_URL = URL.create(
    drivername="mysql+pymysql",
    username="root",
    password="Shruti@18",
    host="localhost",
    port=3306,
    database="linear_regression_db"
)

engine = create_engine(DATABASE_URL)


# Upload a CSV file, save it to SQL, and read it back
@app.post("/upload-and-preprocess-data")
async def upload_and_preprocess_data(file: UploadFile = File(...)):
    try:
        # Read the uploaded CSV file
        contents = await file.read()
        data = pd.read_csv(io.BytesIO(contents))

        # Save the uploaded data into the SQL database
        data.to_sql(
            name="housing_data",
            con=engine,
            if_exists="replace",
            index=False
        )

        # Query the data back from SQL
        sql_data = pd.read_sql(
            "SELECT * FROM housing_data",
            con=engine
        )

        # Split the data into training and validation sets
        from sklearn.model_selection import train_test_split

        train_data, validation_data = train_test_split(
            sql_data,
            test_size=0.2,
            random_state=42
        )

        return {
            "message": "CSV uploaded and saved to SQL successfully",
            "total_rows": len(sql_data),
            "training_rows": len(train_data),
            "validation_rows": len(validation_data),
            "columns": list(sql_data.columns)
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
