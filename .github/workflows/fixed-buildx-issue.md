# CI/CD Pipeline Docker Buildx Issue - Fixed

This document describes the changes made to fix the Docker Buildx issue in the CI/CD pipeline.

## The Issue

The CI/CD pipeline was failing with the following error:

```
Error: ERROR: no builder "builder-283cbf5b-2ec4-4322-9af0-df281a9cb1d6" found
```

This occurred because the workflow was trying to reference a specific Docker Buildx builder that no longer exists.

## The Fix

The following changes were made to the `.github/workflows/ci_cd_pipeline.yml` file:

1. Updated the Docker Buildx setup step to create a new builder instance without relying on a specific builder ID:

```yaml
- name: Set up Docker Buildx
  id: builder
  uses: docker/setup-buildx-action@v3
  with:
    driver: docker-container
    buildkitd-flags: --allow-insecure-entitlement security.insecure
    install: true
    use: true
```

2. Removed explicit builder references from the build steps to rely on the default builder:

```yaml
- name: Build Docker image (local)
  id: build-local
  uses: docker/build-push-action@v5
  with:
    context: ./backend
    file: ./backend/Dockerfile
    push: false
    tags: vigor-backend:latest
    platforms: linux/amd64
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

3. Similarly removed the explicit builder reference from the build and push step:

```yaml
- name: Build and push Docker image
  id: build
  continue-on-error: true
  uses: docker/build-push-action@v5
  with:
    context: ./backend
    file: ./backend/Dockerfile
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    labels: ${{ steps.meta.outputs.labels }}
    platforms: linux/amd64
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Why This Works

The updated configuration addresses several issues:

1. **Dynamic Builder Creation**: Instead of relying on a specific builder ID, we've configured the action to create a new builder instance for each run.

2. **Default Builder Usage**: By removing the explicit builder reference in the build steps, the workflow now automatically uses the default builder that was just created.

3. **Improved Stability**: The new configuration adds `install: true` and `use: true` options to ensure that Docker Buildx is properly set up and available for use in the workflow.

4. **Security Permissions**: The `buildkitd-flags: --allow-insecure-entitlement security.insecure` flag has been added to provide necessary permissions for the build process.

These changes make the CI/CD pipeline more robust and less likely to fail due to missing builders or configuration issues.
