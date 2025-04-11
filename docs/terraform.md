

```
Plan: 18 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bigquery_dataset      = "air_quality_dataset"
  + data_lake_bucket      = "air-quality-data-lake-de-zoomcamp-air-quality"
  + environment           = "dev"
  + kestra_storage_bucket = "kestra-storage-de-zoomcamp-air-quality"
  + kestra_ui_login       = (sensitive value)
  + kestra_ui_url         = (known after apply)
  + kestra_vm_ip          = (known after apply)
  + postgres_database     = "kestra"
  + postgres_instance     = "kestradb"
  + postgres_private_ip   = (known after apply)
  + postgres_user         = (sensitive value)
  + project_id            = "de-zoomcamp-air-quality"
  + region                = "europe-west1"
  + service_account_email = "air-quality-sa@de-zoomcamp-air-quality.iam.gserviceaccount.com"
  + subnet                = "kestra-subnet"
  + vpc_network           = "kestra-vpc-network"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

...

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

bigquery_dataset = "air_quality_dataset"
data_lake_bucket = "air-quality-data-lake-de-zoomcamp-air-quality"
environment = "dev"
kestra_storage_bucket = "kestra-storage-de-zoomcamp-air-quality"
kestra_ui_login = <sensitive>
kestra_ui_url = "http://130.211.71.98:8080"
kestra_vm_ip = "130.211.71.98"
postgres_database = "kestra"
postgres_instance = "kestradb"
postgres_private_ip = "10.74.0.3"
postgres_user = <sensitive>
project_id = "de-zoomcamp-air-quality"
region = "europe-west1"
service_account_email = "air-quality-sa@de-zoomcamp-air-quality.iam.gserviceaccount.com"
subnet = "kestra-subnet"
vpc_network = "kestra-vpc-network"

```
