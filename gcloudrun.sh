#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- User Configuration ---
# IMPORTANT: Replace these placeholder values with your actual details.

# Your Google Cloud Project ID
export GCP_PROJECT_ID="startup-projects-447512"

# The Google Cloud region for your Cloud Run service, Artifact Registry, and Cloud Storage bucket
# Example: us-central1, europe-west1, asia-southeast1
export GCP_REGION="us-central1"

# Name for your Artifact Registry Docker repository
export AR_REPO_NAME="startup-connect-py-repo"

# Name for the Google Service Account that GitHub Actions will use for deployment
export SA_NAME="startup-connect-py-deployer"

# Your GitHub Organization or Username (e.g., 'my-github-org' or 'my-github-username')
# IMPORTANT: This should ONLY be your organization or username, NOT the full repository path.
# Example: If your repo is 'my-org/my-repo', this should be 'my-org'.
export GITHUB_ORG_OR_USERNAME="Fordjour12"

# Your specific GitHub Repository Name (e.g., 'my-app-repo')
# This is used for the IAM condition to restrict access.
export GITHUB_REPO_NAME="startup-connect"

# The branch that will trigger deployments (e.g., 'main', 'master', 'develop')
export GITHUB_DEPLOY_BRANCH="master"

# Name for your Workload Identity Pool
export WIF_POOL_ID="startup-connect-pool"

# Name for your Workload Identity Provider
export WIF_PROVIDER_ID="startup-connect-provider"

# Name for your Cloud Storage bucket (optional, set to "" if not needed)
# Bucket names must be globally unique.
export GCS_BUCKET_NAME="${GCP_PROJECT_ID}-9ad91b68d08-app-data" # Example: my-project-id-app-data

# --- End User Configuration ---

# --- Derived Variables ---
export SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
export PROJECT_NUMBER=$(gcloud projects describe "${GCP_PROJECT_ID}" --format="value(projectNumber)")

# Check if project number was retrieved successfully
if [ -z "${PROJECT_NUMBER}" ]; then
   echo "ERROR: Could not retrieve project number for ${GCP_PROJECT_ID}. Please check your project ID and permissions."
   exit 1
fi

export WIF_POOL_FULL_PATH="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}"
export WIF_PROVIDER_FULL_PATH="${WIF_POOL_FULL_PATH}/providers/${WIF_PROVIDER_ID}"

echo "--- Starting Google Cloud Run Deployment Pipeline Setup ---"
echo "Project ID: ${GCP_PROJECT_ID}"
echo "Region: ${GCP_REGION}"
echo "Service Account: ${SA_EMAIL}"
echo "GitHub Org/User: ${GITHUB_ORG_OR_USERNAME}"
echo "GitHub Repo: ${GITHUB_REPO_NAME}"
echo "Deployment Branch: ${GITHUB_DEPLOY_BRANCH}"
echo ""

# --- Pre-check: Update gcloud components ---
echo "It's highly recommended to update your gcloud components before running this script:"
echo "  gcloud components update"
echo "Please run the above command in your terminal and then re-run this script."
echo "Press Enter to continue (or Ctrl+C to exit and update gcloud)..."
read -r

# --- 0. Optional Cleanup Prompt ---
echo "Do you want to delete existing Workload Identity Pool and Provider (if they exist)? This is destructive and should only be done if you want a clean setup."
echo "Enter 'yes' to delete, or press Enter to skip:"
read -r CLEANUP_RESPONSE
if [ "$CLEANUP_RESPONSE" = "yes" ]; then
   echo "  - Attempting to clean up existing Workload Identity Provider and Pool..."
   gcloud iam workload-identity-pools providers delete "${WIF_PROVIDER_ID}" \
      --workload-identity-pool="${WIF_POOL_ID}" \
      --location="global" \
      --project="${GCP_PROJECT_ID}" --quiet || echo "    Provider '${WIF_PROVIDER_ID}' not found or could not be deleted. Continuing."
   gcloud iam workload-identity-pools delete "${WIF_POOL_ID}" \
      --location="global" \
      --project="${GCP_PROJECT_ID}" --quiet || echo "    Pool '${WIF_POOL_ID}' not found or could not be deleted. Continuing."
   echo "  Waiting 10 seconds for deletion to propagate..."
   sleep 10
else
   echo "  Skipping cleanup of existing Workload Identity Pool and Provider."
fi
echo ""

# --- 1. Enable Required Google Cloud APIs ---
echo "1. Enabling required Google Cloud APIs..."
gcloud services enable \
   artifactregistry.googleapis.com \
   run.googleapis.com \
   iam.googleapis.com \
   cloudresourcemanager.googleapis.com \
   storage.googleapis.com \
   --project="${GCP_PROJECT_ID}" || {
   echo "ERROR: Failed to enable APIs."
   exit 1
}
echo "APIs enabled."
echo ""

# --- 2. Configure Artifact Registry ---
echo "2. Configuring Artifact Registry Docker repository: ${AR_REPO_NAME} in ${GCP_REGION}..."
if ! gcloud artifacts repositories describe "${AR_REPO_NAME}" --location="${GCP_REGION}" --project="${GCP_PROJECT_ID}" &>/dev/null; then
   gcloud artifacts repositories create "${AR_REPO_NAME}" \
      --repository-format=docker \
      --location="${GCP_REGION}" \
      --description="Docker repository for Cloud Run images" \
      --project="${GCP_PROJECT_ID}" || {
      echo "ERROR: Failed to create Artifact Registry repository."
      exit 1
   }
   echo "Artifact Registry repository created."
else
   echo "Artifact Registry repository '${AR_REPO_NAME}' already exists. Skipping creation."
fi
echo ""

# --- 3. Create Google Service Account ---
echo "3. Creating Google Service Account: ${SA_NAME}..."
if ! gcloud iam service-accounts describe "${SA_EMAIL}" --project="${GCP_PROJECT_ID}" &>/dev/null; then
   gcloud iam service-accounts create "${SA_NAME}" \
      --display-name="Service Account for GitHub Actions Cloud Run Deployment" \
      --description="Used by GitHub Actions Workload Identity Federation to deploy to Cloud Run." \
      --project="${GCP_PROJECT_ID}" || {
      echo "ERROR: Failed to create service account."
      exit 1
   }
   echo "Service Account created."
else
   echo "Service Account '${SA_NAME}' already exists. Skipping creation."
fi
echo ""

# --- 4. Grant IAM Roles to Service Account ---
echo "4. Granting IAM roles to service account: ${SA_EMAIL}..."

echo "  - Granting roles/run.admin..."
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
   --member="serviceAccount:${SA_EMAIL}" \
   --role="roles/run.admin" \
   --condition=None \
   --project="${GCP_PROJECT_ID}" || {
   echo "ERROR: Failed to grant roles/run.admin."
   exit 1
}

echo "  - Granting roles/artifactregistry.writer..."
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
   --member="serviceAccount:${SA_EMAIL}" \
   --role="roles/artifactregistry.writer" \
   --condition=None \
   --project="${GCP_PROJECT_ID}" || {
   echo "ERROR: Failed to grant roles/artifactregistry.writer."
   exit 1
}

echo "  - Granting roles/iam.serviceAccountUser..."
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
   --member="serviceAccount:${SA_EMAIL}" \
   --role="roles/iam.serviceAccountUser" \
   --condition=None \
   --project="${GCP_PROJECT_ID}" || {
   echo "ERROR: Failed to grant roles/iam.serviceAccountUser."
   exit 1
}

echo "IAM roles granted to service account."
echo ""

echo "  - Granting roles/iam.workloadIdentityPoolAdmin ..."
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
   --member="serviceAccount:${SA_EMAIL}" \
   --role="roles/iam.workloadIdentityPoolAdmin" \
   --condition=None \
   --project="${GCP_PROJECT_ID}" || {
   echo "ERROR: Failed to grant roles/iam.workloadIdentityPoolAdmin."
   exit 1
}
echo "IAM roles granted to service account."
echo ""

# --- 5. Configure Workload Identity Federation (WIF) ---
echo "5. Configuring Workload Identity Federation..."

# Create Workload Identity Pool
echo "  - Creating Workload Identity Pool: ${WIF_POOL_ID}..."
if ! gcloud iam workload-identity-pools describe "${WIF_POOL_ID}" --location="global" --project="${GCP_PROJECT_ID}" &>/dev/null; then
   gcloud iam workload-identity-pools create "${WIF_POOL_ID}" \
      --project="${GCP_PROJECT_ID}" \
      --location="global" \
      --display-name="GitHub Actions Pool" \
      --description="Pool for GitHub Actions workflows to authenticate." || {
      echo "ERROR: Failed to create Workload Identity Pool."
      exit 1
   }
   echo "  Workload Identity Pool created."
else
   echo "  Workload Identity Pool '${WIF_POOL_ID}' already exists. Skipping creation."
fi

# Create OIDC Provider with full attribute mappings and condition
echo "  - Creating OIDC Provider: ${WIF_PROVIDER_ID}..."
if ! gcloud iam workload-identity-pools providers describe "${WIF_PROVIDER_ID}" --workload-identity-pool="${WIF_POOL_ID}" --location="global" --project="${GCP_PROJECT_ID}" &>/dev/null; then
   gcloud iam workload-identity-pools providers create-oidc "${WIF_PROVIDER_ID}" \
      --project="${GCP_PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="${WIF_POOL_ID}" \
      --display-name="GitHub Actions OIDC Provider" \
      --description="OIDC provider for GitHub Actions." \
      --issuer-uri="https://token.actions.githubusercontent.com" \
      --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
      --attribute-condition="assertion.repository == '${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME}' && assertion.ref == 'refs/heads/${GITHUB_DEPLOY_BRANCH}'" || {
      echo "ERROR: Failed to create OIDC Provider."
      exit 1
   }
   echo "  OIDC Provider created."
else
   echo "  OIDC Provider '${WIF_PROVIDER_ID}' already exists. Skipping creation."
fi

# Validate IAM Condition
echo "  - Validating IAM condition..."
CONDITION_EXPRESSION="attribute.repository == '${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME}' && attribute.ref == 'refs/heads/${GITHUB_DEPLOY_BRANCH}'"
CONDITION_TITLE="GitHub Actions Deployment Access for ${GITHUB_REPO_NAME} ${GITHUB_DEPLOY_BRANCH}"
CONDITION_DESCRIPTION="Allows GitHub Actions from ${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME} on branch ${GITHUB_DEPLOY_BRANCH} to impersonate this service account."

echo "    Condition: ${CONDITION_EXPRESSION}"
gcloud alpha iam policies lint-condition \
   --condition-expression="${CONDITION_EXPRESSION}" || {
   echo "ERROR: IAM condition validation failed. Please check the condition syntax."
   exit 1
}
echo "  IAM condition validated."

# Bind Service Account to WIF Provider with a Condition
echo "  - Binding service account to WIF provider with a secure condition..."
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
   --project="${GCP_PROJECT_ID}" \
   --role="roles/iam.workloadIdentityUser" \
   --member="principalSet://iam.googleapis.com/${WIF_POOL_FULL_PATH}/attribute.repository/${GITHUB_ORG_OR_USERNAME}/${GITHUB_REPO_NAME}" \
   --condition="expression=${CONDITION_EXPRESSION},title=${CONDITION_TITLE},description=${CONDITION_DESCRIPTION}" || {
   echo "ERROR: Failed to bind service account to WIF provider."
   exit 1
}
echo "  Workload Identity Federation configured."
echo ""

# --- 6. Configure Cloud Storage (Optional) ---
if [ -n "${GCS_BUCKET_NAME}" ]; then
   echo "6. Configuring Cloud Storage bucket: gs://${GCS_BUCKET_NAME}..."
   if ! gcloud storage buckets describe "gs://${GCS_BUCKET_NAME}" --project="${GCP_PROJECT_ID}" &>/dev/null; then
      gcloud storage buckets create "gs://${GCS_BUCKET_NAME}" \
         --project="${GCP_PROJECT_ID}" \
         --location="${GCP_REGION}" \
         --uniform-bucket-level-access || {
         echo "ERROR: Failed to create Cloud Storage bucket."
         exit 1
      }
      echo "Cloud Storage bucket created."
   else
      echo "Cloud Storage bucket '${GCS_BUCKET_NAME}' already exists. Skipping creation."
   fi

   echo "  - Granting roles/storage.admin to bucket '${GCS_BUCKET_NAME}'..."
   gcloud storage buckets add-iam-policy-binding "gs://${GCS_BUCKET_NAME}" \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="roles/storage.admin" \
      --project="${GCP_PROJECT_ID}" \
      --condition=None || {
      echo "ERROR: Failed to grant storage.admin role to bucket."
      exit 1
   }
   echo "Cloud Storage bucket configured and access granted."
   echo ""
else
   echo "6. Skipping Cloud Storage bucket creation (GCS_BUCKET_NAME was not set)."
   echo ""
fi

echo "--- Setup Complete! ---"
echo "You can now use the following details in your GitHub Actions workflow:"
echo "------------------------------------------------------------------------------------------------------"
echo "Google Cloud Project ID: ${GCP_PROJECT_ID}"
echo "Google Cloud Region: ${GCP_REGION}"
echo "Artifact Registry Docker Repo: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${AR_REPO_NAME}"
echo "Service Account Email: ${SA_EMAIL}"
echo "Workload Identity Provider Resource Name: ${WIF_PROVIDER_FULL_PATH}"
echo "Cloud Storage Bucket (if created): gs://${GCS_BUCKET_NAME}"
echo "------------------------------------------------------------------------------------------------------"
echo ""
echo "Next steps: Create your GitHub Actions workflow file using the example provided."
