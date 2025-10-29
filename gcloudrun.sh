#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# =====================================================================
# Google Cloud Run Deployment Setup Script (Updated)
# Includes Artifact Registry Repo Admin + Workload Identity User fixes
# =====================================================================

# --- Configurable Parameters ---
# Modify these values to customize the setup behavior

# API Services to enable
export API_SERVICES="artifactregistry.googleapis.com run.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com storage.googleapis.com"

# IAM Roles to grant
export ROLE_RUN_ADMIN="roles/run.admin"
export ROLE_ARTIFACT_REGISTRY_WRITER="roles/artifactregistry.writer"
export ROLE_ARTIFACT_REGISTRY_REPO_ADMIN="roles/artifactregistry.repoAdmin"
export ROLE_SERVICE_ACCOUNT_USER="roles/iam.serviceAccountUser"
export ROLE_WORKLOAD_IDENTITY_USER="roles/iam.workloadIdentityUser"
export ROLE_STORAGE_OBJECT_ADMIN="roles/storage.objectAdmin"

# Artifact Registry settings
export AR_REPO_FORMAT="docker"
export AR_REPO_DESCRIPTION="Docker repository for Cloud Run images"

# Workload Identity Federation settings
export WIF_POOL_DISPLAY_NAME="GitHub Actions Pool"
export WIF_POOL_DESCRIPTION="Pool for GitHub Actions workflows to authenticate."
export WIF_PROVIDER_DISPLAY_NAME="GitHub Actions OIDC Provider"
export WIF_PROVIDER_DESCRIPTION="OIDC provider for GitHub Actions."
export WIF_ISSUER_URI="https://token.actions.githubusercontent.com"
export WIF_ATTRIBUTE_MAPPING="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref"

# Service Account settings
export SA_DISPLAY_NAME="Service Account for GitHub Actions Cloud Run Deployment"
export SA_DESCRIPTION="Used by GitHub Actions Workload Identity Federation to deploy to Cloud Run."

# Timing and retry settings
export CLEANUP_SLEEP_DURATION=10

# Cloud Storage settings
export GCS_UNIFORM_BUCKET_LEVEL_ACCESS="--uniform-bucket-level-access"

# --- Input Validation ---

if [ -z "${GCP_PROJECT_ID:-}" ] || [ -z "${GCP_REGION:-}" ] || [ -z "${SA_NAME:-}" ] ||
   [ -z "${GITHUB_ORG_OR_USERNAME:-}" ] || [ -z "${GITHUB_REPO_NAME:-}" ] ||
   [ -z "${GITHUB_DEPLOY_BRANCH:-}" ] || [ -z "${WIF_POOL_ID:-}" ] ||
   [ -z "${WIF_PROVIDER_ID:-}" ] || [ -z "${AR_REPO_NAME:-}" ]; then
   echo "ERROR: One or more required environment variables are not set."
   echo "Please set: GCP_PROJECT_ID, GCP_REGION, SA_NAME, GITHUB_ORG_OR_USERNAME, GITHUB_REPO_NAME,"
   echo "            GITHUB_DEPLOY_BRANCH, WIF_POOL_ID, WIF_PROVIDER_ID, AR_REPO_NAME."
   exit 1
fi

export SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
export PROJECT_NUMBER=$(gcloud projects describe "${GCP_PROJECT_ID}" --format="value(projectNumber)")

if [ -z "${PROJECT_NUMBER}" ]; then
   echo "ERROR: Could not retrieve project number for ${GCP_PROJECT_ID}."
   exit 1
fi

export WIF_POOL_FULL_PATH="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}"
export WIF_PROVIDER_FULL_PATH="${WIF_POOL_FULL_PATH}/providers/${WIF_PROVIDER_ID}"

echo "=== Starting Cloud Run Deployment Setup ==="
echo "Project: ${GCP_PROJECT_ID} (${PROJECT_NUMBER})"
echo "Region: ${GCP_REGION}"
echo "Service Account: ${SA_EMAIL}"
echo "Artifact Registry: ${AR_REPO_NAME}"
echo "GitHub: ${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME} (${GITHUB_DEPLOY_BRANCH})"
echo ""

# --- 1. Enable Required APIs ---
echo "[1] Enabling APIs..."
gcloud services enable ${API_SERVICES} --project="${GCP_PROJECT_ID}"

# --- 2. Create Service Account ---
echo "[2] Creating Service Account..."
if ! gcloud iam service-accounts describe "${SA_EMAIL}" --project="${GCP_PROJECT_ID}" &>/dev/null; then
  gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="${SA_DISPLAY_NAME}" \
    --description="${SA_DESCRIPTION}" \
    --project="${GCP_PROJECT_ID}"
  echo "Service account created."
else
  echo "Service account already exists. Skipping creation."
fi

# --- 3. Assign IAM Roles ---
echo "[3] Assigning roles to service account..."
for ROLE in \
  "${ROLE_RUN_ADMIN}" \
  "${ROLE_SERVICE_ACCOUNT_USER}" \
  "${ROLE_ARTIFACT_REGISTRY_WRITER}" \
  "${ROLE_ARTIFACT_REGISTRY_REPO_ADMIN}"; do
  echo "  - Granting ${ROLE}"
  gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --project="${GCP_PROJECT_ID}" --quiet
done

# --- 4. Artifact Registry ---
echo "[4] Creating Artifact Registry repository..."
if ! gcloud artifacts repositories describe "${AR_REPO_NAME}" \
  --location="${GCP_REGION}" --project="${GCP_PROJECT_ID}" &>/dev/null; then
  gcloud artifacts repositories create "${AR_REPO_NAME}" \
    --repository-format="${AR_REPO_FORMAT}" \
    --location="${GCP_REGION}" \
    --description="${AR_REPO_DESCRIPTION}" \
    --project="${GCP_PROJECT_ID}"
  echo "Repository created."
else
  echo "Repository already exists. Skipping creation."
fi

# Add repo-level IAM binding (least privilege)
echo "  - Granting ${ROLE_ARTIFACT_REGISTRY_WRITER} on repo..."
gcloud artifacts repositories add-iam-policy-binding "${AR_REPO_NAME}" \
  --location="${GCP_REGION}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="${ROLE_ARTIFACT_REGISTRY_WRITER}" \
  --project="${GCP_PROJECT_ID}" --quiet

echo "  - Granting ${ROLE_ARTIFACT_REGISTRY_REPO_ADMIN} on repo..."
gcloud artifacts repositories add-iam-policy-binding "${AR_REPO_NAME}" \
  --location="${GCP_REGION}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="${ROLE_ARTIFACT_REGISTRY_REPO_ADMIN}" \
  --project="${GCP_PROJECT_ID}" --quiet

# --- 5. Workload Identity Federation ---
echo "[5] Setting up Workload Identity Federation..."

if ! gcloud iam workload-identity-pools describe "${WIF_POOL_ID}" \
  --location="global" --project="${GCP_PROJECT_ID}" &>/dev/null; then
  gcloud iam workload-identity-pools create "${WIF_POOL_ID}" \
    --project="${GCP_PROJECT_ID}" \
    --location="global" \
    --display-name="${WIF_POOL_DISPLAY_NAME}" \
    --description="${WIF_POOL_DESCRIPTION}"
  echo "WIF Pool created."
else
  echo "WIF Pool already exists."
fi

if ! gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" \
  --workload-identity-pool="${WIF_POOL_ID}" \
  --location="global" \
  --project="${GCP_PROJECT_ID}" &>/dev/null; then
  gcloud iam workload-identity-pools providers create-oidc "${WIF_PROVIDER_ID}" \
    --project="${GCP_PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${WIF_POOL_ID}" \
    --display-name="${WIF_PROVIDER_DISPLAY_NAME}" \
    --description="${WIF_PROVIDER_DESCRIPTION}" \
    --issuer-uri="${WIF_ISSUER_URI}" \
    --attribute-mapping="${WIF_ATTRIBUTE_MAPPING}" \
    --attribute-condition="assertion.repository=='${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME}' && assertion.ref=='refs/heads/${GITHUB_DEPLOY_BRANCH}'"
  echo "OIDC Provider created."
else
  echo "OIDC Provider already exists."
fi

# Bind service account to WIF provider (Workload Identity User)
echo "  - Binding Workload Identity User role..."
WIF_MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}/attribute.repository/${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME}/attribute.ref/refs/heads/${GITHUB_DEPLOY_BRANCH}"
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${GCP_PROJECT_ID}" \
  --role="${ROLE_WORKLOAD_IDENTITY_USER}" \
  --member="${WIF_MEMBER}" --quiet

# --- 6. Optional: Cloud Storage setup ---
if [ -n "${GCS_BUCKET_NAME:-}" ]; then
  echo "[6] Configuring Cloud Storage bucket..."
  if ! gcloud storage buckets describe "gs://${GCS_BUCKET_NAME}" &>/dev/null; then
    gcloud storage buckets create "gs://${GCS_BUCKET_NAME}" \
      --project="${GCP_PROJECT_ID}" \
      --location="${GCP_REGION}" \
      ${GCS_UNIFORM_BUCKET_LEVEL_ACCESS}
  fi
  gcloud storage buckets add-iam-policy-binding "gs://${GCS_BUCKET_NAME}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE_STORAGE_OBJECT_ADMIN}" \
    --project="${GCP_PROJECT_ID}"
  echo "Storage bucket configured."
fi

# --- Done ---
echo ""
echo "✅ Setup Complete!"
echo "----------------------------------------"
echo "Service Account: ${SA_EMAIL}"
echo "Project ID: ${GCP_PROJECT_ID}"
echo "Region: ${GCP_REGION}"
echo "Artifact Repo: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${AR_REPO_NAME}"
echo "WIF Provider: ${WIF_PROVIDER_FULL_PATH}"
echo "----------------------------------------"
echo ""
echo "You can now configure your GitHub Actions with:"
echo ""
echo "  - uses: google-github-actions/auth@v2"
echo "    with:"
echo "      workload_identity_provider: '${WIF_PROVIDER_FULL_PATH}'"
echo "      service_account: '${SA_EMAIL}'"
echo ""
echo "Then run:"
echo "  gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet"
echo "and push your image!"

