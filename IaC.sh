export PROJECT_ID="regal-muse-335423"
export PROJECT_NUMBER="720003034727"
export DEV_BUCKET="DEV_BUCKET"
export PROD_BUCKET="PROD_BUCKET"

gcloud storage buckets create gs://$DEV_BUCKET --project=$PROJECT_ID --default-storage-class=STANDARD --location=EUROPE-WEST1 --uniform-bucket-level-access

gcloud storage buckets create gs://$PROD_BUCKET --project=$PROJECT_ID --default-storage-class=STANDARD --location=EUROPE-WEST1 --uniform-bucket-level-access

gcloud iam workload-identity-pools create github \
    --project=$PROJECT_ID \
    --location="global" \
    --description="GitHub pool" \
    --display-name="GitHub pool"

gcloud iam workload-identity-pools providers create-oidc "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="GitHub provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.workflow_ref=assertion.job_workflow_ref,attribute.event_name=assertion.event_name" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam service-accounts create bucket-dev \
    --project=$PROJECT_ID \
    --description="SA with access to the DEV Bucket" \
    --display-name="Bucket Reader DEV"

gcloud iam service-accounts create bucket-prod \
    --project=$PROJECT_ID \
    --description="SA with access to the PROD Bucket" \
    --display-name="Bucket Reader PROD"

gcloud storage buckets add-iam-policy-binding gs://${DEV_BUCKET} \
  --member=serviceAccount:bucket-dev@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer

gcloud storage buckets add-iam-policy-binding gs://${PROD_BUCKET} \
  --member=serviceAccount:bucket-prod@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer

gcloud iam service-accounts add-iam-policy-binding "bucket-dev@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.event_name/pull_request"


gcloud iam service-accounts add-iam-policy-binding "bucket-prod@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/attribute.workflow_ref/outofdevops/workload-identity-federation/.github/workflows/multi-id.yaml@refs/heads/main"
