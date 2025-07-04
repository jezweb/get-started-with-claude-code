# Google Cloud Storage Integration with Vertex AI

Comprehensive guide for integrating Google Cloud Storage buckets with Vertex AI for data management, model artifacts, and seamless ML workflows.

## 🎯 Overview

Cloud Storage serves as the backbone for Vertex AI operations:
- **Training Data** - Store datasets for model training
- **Model Artifacts** - Save trained models and checkpoints
- **Pipeline Assets** - Store preprocessing scripts and configurations
- **Batch Predictions** - Input/output data for batch inference
- **Experiment Tracking** - Logs, metrics, and experiment artifacts

## 🚀 Quick Start

### 1. Setup Cloud Storage Bucket

```bash
# Create a new bucket for Vertex AI
export PROJECT_ID="your-project-id"
export BUCKET_NAME="vertex-ai-${PROJECT_ID}"
export LOCATION="us-central1"

# Create bucket with uniform access
gsutil mb -p ${PROJECT_ID} -c standard -l ${LOCATION} -b on gs://${BUCKET_NAME}/

# Create folder structure
gsutil -m mkdir -p gs://${BUCKET_NAME}/{data,models,artifacts,logs,temp}
```

### 2. Configure Permissions

```bash
# Grant Vertex AI service account access
export SERVICE_ACCOUNT="service-${PROJECT_NUMBER}@gcp-sa-aiplatform.iam.gserviceaccount.com"

# Grant necessary permissions
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:roles/storage.objectAdmin gs://${BUCKET_NAME}

# For custom service accounts
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/storage.objectUser"
```

## 📁 Storage Organization

### Recommended Folder Structure

```
gs://vertex-ai-project/
├── data/
│   ├── raw/              # Original datasets
│   ├── processed/        # Preprocessed data
│   ├── train/           # Training datasets
│   ├── validation/      # Validation datasets
│   └── test/            # Test datasets
├── models/
│   ├── experiments/     # Experimental models
│   ├── staging/         # Models ready for testing
│   └── production/      # Production models
├── artifacts/
│   ├── pipelines/       # Kubeflow/Vertex pipelines
│   ├── notebooks/       # Jupyter notebooks
│   └── configs/         # Configuration files
├── logs/
│   ├── training/        # Training logs
│   ├── serving/         # Serving logs
│   └── monitoring/      # Monitoring data
└── temp/                # Temporary files
```

## 💾 Data Management

### Uploading Training Data

```python
from google.cloud import storage
import pandas as pd
from typing import List
import os

class VertexAIStorageManager:
    def __init__(self, project_id: str, bucket_name: str):
        self.client = storage.Client(project=project_id)
        self.bucket = self.client.bucket(bucket_name)
        
    def upload_dataframe(self, df: pd.DataFrame, gcs_path: str, format: str = 'csv'):
        """Upload pandas DataFrame to GCS"""
        blob = self.bucket.blob(gcs_path)
        
        if format == 'csv':
            blob.upload_from_string(df.to_csv(index=False), content_type='text/csv')
        elif format == 'parquet':
            buffer = df.to_parquet()
            blob.upload_from_string(buffer, content_type='application/octet-stream')
        elif format == 'jsonl':
            jsonl_string = df.to_json(orient='records', lines=True)
            blob.upload_from_string(jsonl_string, content_type='application/json')
            
        return f"gs://{self.bucket.name}/{gcs_path}"
    
    def upload_files(self, local_paths: List[str], gcs_prefix: str):
        """Batch upload files to GCS"""
        uploaded_paths = []
        
        for local_path in local_paths:
            filename = os.path.basename(local_path)
            gcs_path = f"{gcs_prefix}/{filename}"
            blob = self.bucket.blob(gcs_path)
            blob.upload_from_filename(local_path)
            uploaded_paths.append(f"gs://{self.bucket.name}/{gcs_path}")
            
        return uploaded_paths

# Usage example
storage_manager = VertexAIStorageManager(PROJECT_ID, BUCKET_NAME)

# Upload training data
train_df = pd.read_csv("local_train_data.csv")
train_uri = storage_manager.upload_dataframe(
    train_df, 
    "data/train/dataset_v1.csv"
)
```

### Optimized Data Loading

```python
import tensorflow as tf
import numpy as np
from concurrent.futures import ThreadPoolExecutor

class GCSDataLoader:
    def __init__(self, bucket_name: str):
        self.bucket_name = bucket_name
        
    def load_tfrecords(self, file_pattern: str, batch_size: int = 32):
        """Load TFRecord files from GCS efficiently"""
        file_pattern = f"gs://{self.bucket_name}/{file_pattern}"
        files = tf.io.gfile.glob(file_pattern)
        
        # Create dataset with parallel reads
        dataset = tf.data.TFRecordDataset(
            files,
            num_parallel_reads=tf.data.AUTOTUNE,
            buffer_size=8 * 1024 * 1024  # 8MB buffer
        )
        
        # Parse and batch
        dataset = dataset.map(
            self._parse_tfrecord,
            num_parallel_calls=tf.data.AUTOTUNE
        )
        dataset = dataset.batch(batch_size)
        dataset = dataset.prefetch(tf.data.AUTOTUNE)
        
        return dataset
    
    def load_images_parallel(self, image_uris: List[str], max_workers: int = 10):
        """Load images in parallel from GCS"""
        def load_single_image(uri):
            image_bytes = tf.io.gfile.GFile(uri, 'rb').read()
            return tf.image.decode_image(image_bytes)
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            images = list(executor.map(load_single_image, image_uris))
            
        return tf.stack(images)
```

## 🔄 Vertex AI Integration

### Training with Cloud Storage

```python
from google.cloud import aiplatform

# Initialize Vertex AI
aiplatform.init(project=PROJECT_ID, location=LOCATION)

# Create custom training job with GCS data
job = aiplatform.CustomTrainingJob(
    display_name="my-training-job",
    script_path="trainer/task.py",
    container_uri="gcr.io/cloud-aiplatform/training/tf-gpu.2-8:latest",
    requirements=["pandas", "scikit-learn"],
    model_serving_container_image_uri="gcr.io/cloud-aiplatform/prediction/tf2-gpu.2-8:latest"
)

# Run training with GCS paths
model = job.run(
    dataset=f"gs://{BUCKET_NAME}/data/train/",
    model_display_name="my-model",
    args=[
        "--train-files", f"gs://{BUCKET_NAME}/data/train/*.csv",
        "--eval-files", f"gs://{BUCKET_NAME}/data/validation/*.csv",
        "--model-dir", f"gs://{BUCKET_NAME}/models/experiments/run-001",
        "--num-epochs", "10",
        "--batch-size", "32"
    ],
    machine_type="n1-standard-8",
    accelerator_type="NVIDIA_TESLA_T4",
    accelerator_count=1
)
```

### Batch Prediction with Storage

```python
# Prepare batch prediction input
batch_input_uri = f"gs://{BUCKET_NAME}/data/batch_predict/input.jsonl"
batch_output_uri = f"gs://{BUCKET_NAME}/data/batch_predict/output/"

# Create batch prediction job
batch_prediction_job = model.batch_predict(
    job_display_name="batch-prediction-job",
    instances_format="jsonl",
    predictions_format="jsonl",
    gcs_source=batch_input_uri,
    gcs_destination_prefix=batch_output_uri,
    machine_type="n1-standard-4",
    starting_replica_count=1,
    max_replica_count=5
)

# Monitor job
batch_prediction_job.wait()
print(f"Predictions saved to: {batch_output_uri}")
```

## 🏔️ Vertex AI Workbench Integration

### Mount Storage in Notebooks

```python
# In Vertex AI Workbench notebook
import os
from google.cloud import storage

# Mount bucket using gcsfuse (pre-installed in Workbench)
mount_point = "/home/jupyter/gcs-mount"
os.makedirs(mount_point, exist_ok=True)

# Mount command
!gcsfuse --implicit-dirs --key-file=$GOOGLE_APPLICATION_CREDENTIALS \
    {BUCKET_NAME} {mount_point}

# Now access files directly
import pandas as pd
df = pd.read_csv(f"{mount_point}/data/train/dataset.csv")

# Unmount when done
!fusermount -u {mount_point}
```

### Direct Storage Access

```python
# Configure Vertex AI Workbench for optimal GCS performance
class WorkbenchStorageConfig:
    def __init__(self, bucket_name: str):
        self.bucket_name = bucket_name
        
    def setup_credentials(self):
        """Setup service account credentials"""
        # Workbench automatically handles auth
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = \
            '/home/jupyter/.config/gcloud/application_default_credentials.json'
    
    def create_data_pipeline(self):
        """Create efficient data pipeline"""
        return tf.data.Dataset.from_tensor_slices(
            tf.io.gfile.glob(f"gs://{self.bucket_name}/data/train/*.tfrecord")
        ).interleave(
            lambda x: tf.data.TFRecordDataset(x),
            cycle_length=16,
            num_parallel_calls=tf.data.AUTOTUNE
        )
```

## 🚀 Performance Optimization

### Large File Handling

```python
class OptimizedGCSHandler:
    def __init__(self, bucket_name: str):
        self.bucket_name = bucket_name
        self.client = storage.Client()
        self.bucket = self.client.bucket(bucket_name)
    
    def parallel_upload_large_file(self, local_path: str, gcs_path: str, 
                                   chunk_size: int = 100 * 1024 * 1024):  # 100MB chunks
        """Upload large files in parallel chunks"""
        blob = self.bucket.blob(gcs_path)
        
        # Use resumable upload for large files
        with open(local_path, 'rb') as f:
            blob.upload_from_file(
                f,
                chunk_size=chunk_size,
                num_retries=3,
                timeout=3600  # 1 hour timeout
            )
    
    def stream_download(self, gcs_path: str, local_path: str):
        """Stream download large files"""
        blob = self.bucket.blob(gcs_path)
        
        with open(local_path, 'wb') as f:
            blob.download_to_file(f, chunk_size=8 * 1024 * 1024)  # 8MB chunks
    
    def composite_upload(self, local_files: List[str], gcs_path: str):
        """Upload multiple files as a composite object"""
        component_blobs = []
        
        # Upload components
        for i, local_file in enumerate(local_files):
            component_name = f"{gcs_path}.part{i}"
            blob = self.bucket.blob(component_name)
            blob.upload_from_filename(local_file)
            component_blobs.append(blob)
        
        # Compose final object
        final_blob = self.bucket.blob(gcs_path)
        final_blob.compose(component_blobs)
        
        # Clean up components
        for blob in component_blobs:
            blob.delete()
```

### Caching Strategy

```python
class GCSCache:
    def __init__(self, bucket_name: str, cache_dir: str = "/tmp/gcs_cache"):
        self.bucket_name = bucket_name
        self.cache_dir = cache_dir
        os.makedirs(cache_dir, exist_ok=True)
    
    def get_or_download(self, gcs_path: str):
        """Download file if not in cache"""
        cache_path = os.path.join(self.cache_dir, gcs_path.replace('/', '_'))
        
        if not os.path.exists(cache_path):
            blob = storage.Client().bucket(self.bucket_name).blob(gcs_path)
            blob.download_to_filename(cache_path)
            
        return cache_path
    
    def cache_dataset(self, file_patterns: List[str]):
        """Pre-cache datasets for training"""
        all_files = []
        for pattern in file_patterns:
            files = tf.io.gfile.glob(f"gs://{self.bucket_name}/{pattern}")
            all_files.extend(files)
        
        # Parallel download
        with ThreadPoolExecutor(max_workers=10) as executor:
            local_files = list(executor.map(self.get_or_download, all_files))
            
        return local_files
```

## 🔒 Security Best Practices

### Encryption

```python
# Customer-managed encryption keys (CMEK)
from google.cloud import kms

def create_cmek_bucket(project_id: str, bucket_name: str, key_name: str):
    """Create bucket with CMEK encryption"""
    storage_client = storage.Client(project=project_id)
    
    bucket = storage_client.bucket(bucket_name)
    bucket.default_kms_key_name = key_name
    bucket.create(location="us-central1")
    
    return bucket

# Use signed URLs for temporary access
def generate_signed_url(bucket_name: str, blob_name: str, expiration_hours: int = 1):
    """Generate signed URL for temporary access"""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    url = blob.generate_signed_url(
        version="v4",
        expiration=datetime.timedelta(hours=expiration_hours),
        method="GET"
    )
    
    return url
```

### Access Control

```python
# Fine-grained access control
def setup_bucket_iam(bucket_name: str, user_email: str, role: str):
    """Setup IAM permissions for bucket"""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    policy = bucket.get_iam_policy(requested_policy_version=3)
    
    # Add member to role
    policy.bindings.append({
        "role": role,
        "members": [f"user:{user_email}"]
    })
    
    bucket.set_iam_policy(policy)
```

## 💰 Cost Optimization

### Storage Classes

```python
# Lifecycle management for cost optimization
lifecycle_rule = {
    "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
    "condition": {"age": 30}  # Move to Nearline after 30 days
}

bucket.lifecycle_rules = [lifecycle_rule]
bucket.patch()

# Archive old models
archive_rule = {
    "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
    "condition": {
        "age": 365,
        "matchesPrefix": ["models/experiments/"]
    }
}
```

### Request Optimization

```python
# Batch operations for efficiency
def batch_delete_old_files(bucket_name: str, prefix: str, days_old: int = 30):
    """Batch delete old files"""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=days_old)
    
    blobs_to_delete = []
    for blob in bucket.list_blobs(prefix=prefix):
        if blob.time_created < cutoff_date:
            blobs_to_delete.append(blob)
    
    # Batch delete
    if blobs_to_delete:
        bucket.delete_blobs(blobs_to_delete)
```

## 📊 Monitoring & Logging

```python
# Monitor storage usage
def get_storage_metrics(bucket_name: str):
    """Get storage metrics for bucket"""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    
    total_size = 0
    file_count = 0
    
    for blob in bucket.list_blobs():
        total_size += blob.size
        file_count += 1
    
    return {
        "total_size_gb": total_size / (1024**3),
        "file_count": file_count,
        "average_file_size_mb": (total_size / file_count) / (1024**2) if file_count > 0 else 0
    }
```

## 🎯 Best Practices

1. **Data Organization**:
   - Use consistent naming conventions
   - Implement versioning for datasets
   - Separate raw and processed data

2. **Performance**:
   - Use appropriate file formats (Parquet for analytics, TFRecord for TF)
   - Implement parallel uploads/downloads
   - Cache frequently accessed data

3. **Cost Management**:
   - Set lifecycle policies
   - Use appropriate storage classes
   - Monitor and optimize access patterns

4. **Security**:
   - Enable bucket versioning
   - Use CMEK for sensitive data
   - Implement least-privilege access

## 📚 Resources

- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Vertex AI Storage Integration](https://cloud.google.com/vertex-ai/docs/training/using-cloud-storage)
- [Storage Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Pricing Calculator](https://cloud.google.com/products/calculator)

---

*Cloud Storage is essential for Vertex AI workflows. Proper organization and optimization ensure efficient, cost-effective ML operations.*