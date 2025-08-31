# Authentication Simplification Implementation Plan

## Overview

This document outlines the comprehensive plan to simplify Vigor's authentication system to use Microsoft Entra ID default tenant with email-based user identification.

## Phase 1: Documentation Updates ✅ COMPLETED

- [x] Updated PRD-Vigor.md authentication requirements
- [x] Updated Tech_Spec_Vigor.md security section
- [x] Updated User_Experience.md authentication flows
- [x] Created this implementation plan

## Phase 2: Authentication Service Updates

### 2.1 Update shared/auth.py

- [ ] Remove Vedprakash domain-specific configurations
- [ ] Update JWT validation to use default tenant
- [ ] Implement email-based user identification
- [ ] Add automatic user creation logic

### 2.2 Update shared/models.py

- [ ] Simplify User model to use email as primary key
- [ ] Remove domain-specific fields
- [ ] Add auto-generated user ID fields

### 2.3 Update shared/config.py

- [ ] Remove Vedprakash domain environment variables
- [ ] Simplify Azure AD configuration
- [ ] Update tenant settings to 'common'

## Phase 3: Function App Authentication Updates

### 3.1 Update all authentication endpoints

- [ ] auth/login endpoint - simplify to default tenant
- [ ] auth/me endpoint - use email-based lookup
- [ ] auth/profile endpoints - update user model references

### 3.2 Update middleware

- [ ] Simplify authentication decorators
- [ ] Update user context extraction
- [ ] Remove domain-specific validations

## Phase 4: Database Schema Updates

### 4.1 Update Cosmos DB user container

- [ ] Migrate user records to email-based primary keys
- [ ] Update partition key strategy if needed
- [ ] Add data migration script for existing users

### 4.2 Update user-related containers

- [ ] Update foreign key references in workouts container
- [ ] Update foreign key references in workout_logs container
- [ ] Update foreign key references in ai_coach_messages container

## Phase 5: Frontend Integration Updates

### 5.1 Update MSAL configuration

- [ ] Configure for default tenant authentication
- [ ] Remove domain-specific authority settings
- [ ] Update redirect URIs for simplified flow

### 5.2 Update authentication flows

- [ ] Simplify login/logout components
- [ ] Update user profile management
- [ ] Remove domain-specific UI elements

## Phase 6: Infrastructure Updates

### 6.1 Update Azure Function App settings

- [ ] Update authentication provider configuration
- [ ] Remove Vedprakash domain-specific settings
- [ ] Configure for default tenant access

### 6.2 Update Key Vault secrets

- [ ] Review and update authentication-related secrets
- [ ] Remove unused domain-specific configurations

## Phase 7: Testing and Validation

### 7.1 Backend testing

- [ ] Test authentication endpoints with default tenant
- [ ] Validate automatic user creation
- [ ] Test email-based user lookup

### 7.2 Integration testing

- [ ] Test end-to-end authentication flow
- [ ] Validate user profile management
- [ ] Test cross-session persistence

### 7.3 Security validation

- [ ] Verify JWT token validation
- [ ] Test rate limiting functionality
- [ ] Validate user data isolation

## Phase 8: Deployment and Cleanup

### 8.1 Deploy updates

- [ ] Deploy updated Function App code
- [ ] Update Azure AD app registration if needed
- [ ] Deploy frontend updates

### 8.2 Archive legacy code

- [ ] Move old authentication code to .archive folder
- [ ] Clean up unused environment variables
- [ ] Update documentation references

## Success Criteria

- [x] All documentation updated to reflect simplified authentication
- [ ] Users can authenticate using any Microsoft account (default tenant)
- [ ] Email address serves as primary user identifier
- [ ] Automatic user record creation on first login
- [ ] Simplified architecture with single resource group
- [ ] All existing functionality preserved with new authentication

## Risk Mitigation

- **Data Loss**: Create backup of existing user data before migration
- **Authentication Failure**: Test thoroughly in development environment
- **User Experience**: Maintain familiar login flow for end users
- **Security**: Ensure proper JWT validation and user isolation

## Timeline

- Phase 1: ✅ Completed (Documentation Updates)
- Phase 2-3: Backend authentication updates (2-3 hours)
- Phase 4: Database schema migration (1-2 hours)
- Phase 5-6: Frontend and infrastructure updates (2-3 hours)
- Phase 7-8: Testing, deployment, and cleanup (2-3 hours)

**Total Estimated Time**: 7-11 hours

## Next Steps

Begin Phase 2 by updating the authentication service files in the functions-modernized/ directory.
