#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="reading-memory"
SERVICE_NAME="reading-memory-api"
SERVICE_ACCOUNT="${SERVICE_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🔧 Setting up GCP resources for Reading Memory API..."

# Set the project
gcloud config set project ${PROJECT_ID}

# Create service account
echo "👤 Creating service account..."
gcloud iam service-accounts create ${SERVICE_NAME} \
  --display-name="Reading Memory API Service Account" \
  --description="Service account for Reading Memory API on Cloud Run" || true

# Grant necessary roles
echo "🔑 Granting roles to service account..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/firebase.sdkAdminServiceAgent"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

# Create secrets if they don't exist
echo "🔐 Setting up Secret Manager..."
echo "Please enter your Google Books API Key:"
read -s GOOGLE_BOOKS_API_KEY
echo ""

echo "Please enter your Claude API Key:"
read -s CLAUDE_API_KEY
echo ""

# Create or update secrets
echo "Creating/updating secrets..."
echo -n "${GOOGLE_BOOKS_API_KEY}" | gcloud secrets create GOOGLE_BOOKS_API_KEY --data-file=- || \
echo -n "${GOOGLE_BOOKS_API_KEY}" | gcloud secrets versions add GOOGLE_BOOKS_API_KEY --data-file=-

echo -n "${CLAUDE_API_KEY}" | gcloud secrets create CLAUDE_API_KEY --data-file=- || \
echo -n "${CLAUDE_API_KEY}" | gcloud secrets versions add CLAUDE_API_KEY --data-file=-

# Grant secret access to service account
gcloud secrets add-iam-policy-binding GOOGLE_BOOKS_API_KEY \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding CLAUDE_API_KEY \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

echo "✅ GCP setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Run npm install in the api directory"
echo "2. Run ./deploy.sh to deploy to Cloud Run"