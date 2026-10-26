import pandas as pd

#Load the original housing dataset
data = pd.read_csv("Housing.csv")

# Display the dataset size and column names
print("Dataset shape:", data.shape)
print("Columns:", data.columns.tolist())

# Load the training dataset
train_data = pd.read_csv("data_train_processed.csv")

# Check the training data structure
print("Training data shape:", train_data.shape)
print("Training columns:", train_data.columns.tolist())
print("\nMissing values:")
print(train_data.isnull().sum())

# Check the data type of each training column
print("\nTraining data types:")
print(train_data.dtypes)

# Check the data type of each training column
print("\nTraining data Types:")
print(train_data.dtypes)

# Load the validation input features
validation_features = pd.read_csv("data_validation_features.csv")

# Load the actual house prices for validation
validation_target = pd.read_csv("data_validation_target.csv")

# Check the validation data sizes
print("\nValidation feature shape:", validation_features.shape)
print("Validation target shape:", validation_target.shape)

# Display the validation input columns
print("Validation feature columns:", validation_features.columns.tolist())
print("Validation target columns:", validation_target.columns.tolist())

# Train and evaluate the Linear Regression model
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import joblib

# Seperate the input features from the target price
X_train = train_data.drop(columns=["price"])
y_train = train_data["price"]

# Identify numerical and categorical columns
numerical_columns = X_train.select_dtypes(include=["number"]).columns
categorical_columns = X_train.select_dtypes(exclude=["number"]).columns

# Convert categorial text values into numerical values
preprocessor = ColumnTransformer(
    transformers=[
        ("categorical", OneHotEncoder(handle_unknown="ignore"), categorical_columns),
        ("numerical", "passthrough", numerical_columns)
    ],
    sparse_threshold=0
)

# Create a pipeline that preprocesses data and Linear Regression
model_pipeline = Pipeline(steps=[
    ("preprocessor", preprocessor),
    ("model", LinearRegression())
])

# Train the model using the training data
model_pipeline.fit(X_train, y_train)

# Predict house prices using the validation features
X_validation = validation_features
y_validation = validation_target["price"]
predictions = model_pipeline.predict(X_validation)

# Evaluate model performance
print("\nMean Absolute Error:", mean_absolute_error(y_validation, predictions))
print("Root Mean Squared Error:", mean_squared_error(y_validation, predictions) ** 0.5 )
print("R-squared Score:", r2_score(y_validation, predictions))

# Save the trained pipeline for use by the API
joblib.dump(model_pipeline, "linear_regression_pipeline.pkl")
print("\nModel pipeline saved successfully.")

# Compare training and validation price ranges
print("\nTraining price summary:")
print(train_data["price"].describe())

print("\nValidation price summary:")
print(validation_target["price"].describe())

print("\nFirst 5 actual validation prices:")
print(y_validation.head().tolist())

print("\nFirst 5 predicted prices:")
print(predictions[:5].tolist())

# Check whether the original dataset is sorted by price
print("\nFirst 10 original prices:")
print(data["price"].head(10).tolist())

print("\nLast 10 original prices:")
print(data["price"].tail(10).tolist())

print("\nOriginal price summary:")
print(data["price"].describe())

# Check whether training and validation rows appear in the original dataset
print("\nTraining data price range:")
print(train_data["price"].min(), "to", validation_target["price"].max())

print("\nTraining prices sorted ascending:", train_data["price"].is_monotonic_increasing)
print("Training prices sorted descending:", train_data["price"].is_monotonic_decreasing)

print("\nValidation prices sorted ascending:", validation_target["price"].is_monotonic_increasing)
print("\nValidation prices sorted descending:", validation_target["price"].is_monotonic_decreasing)

print("\nTraining first 10 prices:", train_data["price"].head(10).tolist())
print("Training last 10 prices:", train_data["price"].tail(10).tolist())
print("Unique training prices:", train_data["price"].nunique())

print("Columns:", data.columns.tolist())