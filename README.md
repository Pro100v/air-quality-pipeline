# Air Quality Monitoring System

This project collects and analyzes air quality data from cities around the world using IQAir API. It implements a full Data Engineering pipeline with extraction, loading, transformation, and visualization capabilities.

## Architecture

![Infrastructure Diagram](./docs/infrastructure_diagram.png)

The project uses the following technologies:
- **Google Cloud Platform** (GCS, BigQuery, Compute Engine)
- **dlt** (Data Load Tool) for extracting data from IQAir API
- **dbt** (Data Build Tool) for transforming data in BigQuery
- **Kestra** for workflow orchestration
- **Terraform** for infrastructure provisioning
- **Docker** for containerization

## Project Structure

```
├── dbt_models               # dbt models for data transformation
├── dlt_pipeline             # dlt scripts for data extraction
├── docker                   # Dockerfiles for different components
├── docs                     # Documentation
├── kestra                   # Kestra workflow definitions
│   └── flows
├── scripts                  # Utility scripts
├── secrets                  # Sensitive data (not committed to repo)
└── terraform                # Terraform configuration
└── modules
```
## Setup and Installation

### Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform installed
- Docker and Docker Compose installed
- IQAir API key

### Local Development

1. Clone the repository:

```
git clone https://github.com/yourusername/air-quality-monitoring.git
cd air-quality-monitoring
```

2. Create `.env` file with required environment variables:

```
GCP Settings
GCP_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./secrets/credentials.json
BigQuery Settings
BIGQUERY_DATASET=air_quality_dataset
BIGQUERY_LOCATION=EU
GCS Settings
GCS_BUCKET_NAME=air-quality-data-lake
GCS_BUCKET_PATH=gs://air-quality-data-lake/air-quality
IQAir API
IQAIR_API_KEY=your-api-key
Kestra Settings
KESTRA_WEBHOOK_URL=your-slack-webhook-url
```

3. Start the local development environment:

```
docker-compose up -d
```
4. Access the services:
- Kestra UI: http://localhost:8080
- dbt docs: http://localhost:8580

### Cloud Deployment

1. Create a service account in Google Cloud with the necessary permissions:

```
./scripts/create-sa-gcloud.sh
```

2. Download the service account key and place it in `./secrets/credentials.json`

3. Deploy the infrastructure with Terraform:

```
cd terraform
terraform init
terraform apply
```
4. Deploy the Kestra flows to the VM:

```
scp -r ./kestra/flows user@kestra-vm-ip:/path/to/kestra/flows

```
5. Set up the environment variables on the VM:

```
ssh user@kestra-vm-ip 'bash -s' < ./scripts/setup-env.sh
```

Deployment schema:

```mermaid
graph TD
    %% Core Resources
    VPC[google_compute_network: kestra-vpc-network]
    SUBNET[google_compute_subnetwork: kestra-subnet]
    SA[google_service_account: air-quality-sa]
    
    %% Storage Resources
    GCS_DL[google_storage_bucket: data-lake-bucket]
    GCS_KESTRA[google_storage_bucket: kestra-storage-bucket]
    FOLDER_RAW[google_storage_bucket_object: raw]
    FOLDER_PROC[google_storage_bucket_object: processed]
    
    %% Database Resources
    PRIV_IP[google_compute_global_address: private-ip]
    VPC_CONN[google_service_networking_connection: vpc-connection]
    POSTGRES[google_sql_database_instance: postgres]
    DB_KESTRA[google_sql_database: kestra-db]
    DB_USER[google_sql_user: kestra-user]
    
    %% Compute Resources
    VM[google_compute_instance: kestra-orchestrator]
    
    %% BigQuery Resources
    BQ_DS[google_bigquery_dataset: air_quality_dataset]
    BQ_TABLE[google_bigquery_table: air_quality_raw]
    
    %% Firewall Rules
    FW_KESTRA[google_compute_firewall: allow-kestra-ui]
    FW_SSH[google_compute_firewall: allow-ssh-iap]
    
    %% IAM Permissions
    IAM_STORAGE[google_project_iam_member: storage-admin]
    IAM_BQ[google_project_iam_member: bigquery-admin]
    IAM_SQL[google_project_iam_member: cloudsql-admin]
    
    %% Relationships - Network
    VPC --> SUBNET
    VPC --> PRIV_IP
    PRIV_IP --> VPC_CONN
    VPC --> VPC_CONN
    VPC --> FW_KESTRA
    VPC --> FW_SSH
    
    %% Relationships - Compute
    VPC --> VM
    SUBNET --> VM
    SA --> VM
    POSTGRES --> VM
    DB_KESTRA --> VM
    DB_USER --> VM
    GCS_KESTRA --> VM
    
    %% Relationships - Storage
    GCS_DL --> FOLDER_RAW
    GCS_DL --> FOLDER_PROC
    
    %% Relationships - Database
    VPC_CONN --> POSTGRES
    POSTGRES --> DB_KESTRA
    POSTGRES --> DB_USER
    
    %% Relationships - BigQuery
    BQ_DS --> BQ_TABLE
    
    %% Relationships - IAM
    SA --> IAM_STORAGE
    SA --> IAM_BQ
    SA --> IAM_SQL
    
    %% Subgraphs for Visual Organization
    subgraph Network
        VPC
        SUBNET
        PRIV_IP
        VPC_CONN
        FW_KESTRA
        FW_SSH
    end
    
    subgraph Storage
        GCS_DL
        GCS_KESTRA
        FOLDER_RAW
        FOLDER_PROC
    end
    
    subgraph "BigQuery Resources"
        BQ_DS
        BQ_TABLE
    end
    
    subgraph "Database"
        POSTGRES
        DB_KESTRA
        DB_USER
    end
    
    subgraph "Compute"
        VM
    end
    
    subgraph "Identity & Access"
        SA
        IAM_STORAGE
        IAM_BQ
        IAM_SQL
    end
```

## Pipeline Components

### Data Extraction (dlt)

The data extraction pipeline collects air quality data from IQAir API and stores it in Google Cloud Storage. The data is collected daily and partitioned by date.

To run the extraction pipeline manually:

```
docker-compose exec dlt-dev python -m dlt_pipeline.air_quality.pipeline
```

### Data Transformation (dbt)

The transformation layer consists of dbt models that clean and transform the raw data into a dimensional model for analysis. The models include:

- Staging models: Clean and prepare the raw data
- Dimensional models: Create geographical and time dimensions
- Fact models: Create fact tables with air quality measurements
- Data marts: Create denormalized views for reporting

To run the dbt models manually:

```
docker-compose exec dbt-dev bash -c "cd /app/dbt_models && dbt run --profiles-dir=."
```

### Workflow Orchestration (Kestra)

Kestra orchestrates the entire pipeline with the following workflows:

- `air_quality_extract_load`: Extracts data from IQAir API and loads it to GCS/BigQuery
- `air_quality_transform`: Transforms data using dbt models
- `air_quality_main_flow`: Main orchestration flow that runs daily

## Dashboard and Visualization

The transformed data can be visualized using Looker Studio or any other BI tool. Connect to the `air_quality_mart` table in BigQuery for the most comprehensive view of the data.k

![Diagram-1](artifacts/diagram-1.png)
![Diagram-2](artifacts/diagram-2.png)

## Maintenance and Monitoring

- Logs are available in Kestra UI
- Notifications are sent to Slack on workflow completion
- dbt documentation provides information about the data models

## License

This project is licensed under the MIT License - see the LICENSE file for details.
