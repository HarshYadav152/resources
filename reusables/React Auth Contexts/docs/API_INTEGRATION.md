# API Integration Guide

## Authentication Endpoints

### Base URL Configuration

```typescript
// src/auth/constants/authConstants.ts
export const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

export const AUTH_ENDPOINTS = {
  LOGIN: `${API_BASE_URL}/auth/login`,
  REGISTER: `${API_BASE_URL}/auth/register`,
  LOGOUT: `${API_BASE_URL}/auth/logout`,
  REFRESH_TOKEN: `${API_BASE_URL}/auth/refresh-token`,
  RESET_PASSWORD: `${API_BASE_URL}/auth/reset-password`,
  UPDATE_PROFILE: `${API_BASE_URL}/auth/profile`,
};
```

### API Service Implementation

```typescript
// src/auth/services/authService.ts
import { AUTH_ENDPOINTS } from '../constants/authConstants';
import { User } from '../types/auth.types';

export class AuthService {
  static async login(email: string, password: string) {
    const response = await fetch(AUTH_ENDPOINTS.LOGIN, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      throw new Error('Login failed');
    }

    return response.json();
  }

  // Additional methods...
}
```
