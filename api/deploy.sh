#!/bin/bash

# Exit on error
set -e

# Configuration
PROJECT_ID="reading-memory"
SERVICE_NAME="reading-memory-api"
REGION="asia-northeast1"
IMAGE_NAME="asia-northeast1-docker.pkg.dev/${PROJECT_ID}/reading-memory-api/${SERVICE_NAME}"

echo "🚀 Starting deployment process..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Set the project
echo "📌 Setting project to ${PROJECT_ID}..."
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Build and push the Docker image
echo "🏗️ Building Docker image..."
cd api
gcloud builds submit --tag ${IMAGE_NAME}

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production,GCP_PROJECT_ID=${PROJECT_ID} \
  --set-secrets "GOOGLE_BOOKS_API_KEY=GOOGLE_BOOKS_API_KEY:latest,CLAUDE_API_KEY=CLAUDE_API_KEY:latest,RAKUTEN_APPLICATION_ID=rakuten-application-id:latest,RAKUTEN_AFFILIATE_ID=rakuten-affiliate-id:latest" \
  --memory 1Gi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 100

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --platform managed --region ${REGION} --format 'value(status.url)')

echo "✅ Deployment complete!"
echo "🌐 Service URL: ${SERVICE_URL}"
echo ""
echo "📝 Next steps:"
echo "1. Update iOS app with the new API endpoint: ${SERVICE_URL}"
echo "2. Test the API endpoints"
echo "3. Monitor logs: gcloud run logs read --service ${SERVICE_NAME} --region ${REGION}"