(in testing and development)
# Modern React Authentication System Documentation

## Table of Contents
- [Folder Structure](#folder-structure)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [API Reference](#api-reference)
- [Advanced Usage](#advanced-usage)
- [Security Considerations](#security-considerations)
- [TypeScript Support](#typescript-support)

## Folder Structure

```
src/
├── auth/
│   ├── contexts/
│   │   └── AuthContext.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useProtectedRoute.ts
│   │   └── useAuthRedirect.ts
│   ├── types/
│   │   └── auth.types.ts
│   ├── utils/
│   │   ├── tokenStorage.ts
│   │   ├── authValidation.ts
│   │   └── authHelpers.ts
│   ├── services/
│   │   └── authService.ts
│   └── constants/
│       └── authConstants.ts
├── components/
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── RegisterForm.tsx
│   │   ├── PasswordResetForm.tsx
│   │   └── ProfileUpdateForm.tsx
│   └── common/
│       ├── ProtectedRoute.tsx
│       └── LoadingSpinner.tsx
└── pages/
    ├── auth/
    │   ├── LoginPage.tsx
    │   ├── RegisterPage.tsx
    │   ├── ForgotPasswordPage.tsx
    │   └── ProfilePage.tsx
    └── common/
        ├── HomePage.tsx
        └── DashboardPage.tsx
```

## Installation

```bash
# Using npm
npm install react-router-dom @types/react-router-dom

# Using yarn
yarn add react-router-dom @types/react-router-dom
```

## Quick Start

1. **Wrap your application with AuthProvider**

```tsx
// src/App.tsx
import { AuthProvider } from './auth/contexts/AuthContext';
import { BrowserRouter as Router } from 'react-router-dom';

function App() {
  return (
    <Router>
      <AuthProvider>
        {/* Your app components */}
      </AuthProvider>
    </Router>
  );
}
```

2. **Use authentication in components**

```tsx
// src/components/auth/LoginForm.tsx
import { useAuth } from '../../auth/hooks/useAuth';

function LoginForm() {
  const { login, isLoading, error } = useAuth();
  // ... implementation
}
```

## Detailed Usage

### Authentication Context

The authentication system is built around a central `AuthContext` that manages the authentication state and provides methods for authentication operations.

#### Available States
- `isAuthenticated`: Boolean indicating authentication status
- `user`: Current user object or null
- `accessToken`: JWT token or null
- `isLoading`: Loading state indicator
- `error`: Error state message

#### Available Methods
- `login(email: string, password: string)`
- `logout()`
- `register(email: string, password: string, name?: string)`
- `resetPassword(email: string)`
- `updateProfile(userData: Partial<User>)`
- `refreshToken()`

### Protected Routes

```tsx
// src/components/common/ProtectedRoute.tsx
import { useProtectedRoute } from '../../auth/hooks/useProtectedRoute';

function ProtectedRoute({ children }) {
  const { isLoading } = useProtectedRoute('/login');
  
  if (isLoading) {
    return <LoadingSpinner />;
  }
  
  return children;
}
```

### Custom Hooks

1. **useAuth**
```tsx
const { user, login, logout } = useAuth();
```

2. **useProtectedRoute**
```tsx
const { isLoading } = useProtectedRoute('/login');
```

3. **useAuthRedirect**
```tsx
const { redirectIfAuthenticated } = useAuthRedirect();
```

## API Reference

### AuthContext

```tsx
interface AuthContextType {
  isAuthenticated: boolean;
  user: User | null;
  accessToken: string | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  register: (email: string, password: string, name?: string) => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updateProfile: (userData: Partial<User>) => Promise<void>;
  refreshToken: () => Promise<void>;
}
```

### User Type

```tsx
interface User {
  id: string;
  email: string;
  name?: string;
  avatar?: string;
  roles?: string[];
}
```

## Advanced Usage

### Token Management

```tsx
// src/auth/utils/tokenStorage.ts
export const TokenStorage = {
  getToken: () => localStorage.getItem('accessToken'),
  setToken: (token: string) => localStorage.setItem('accessToken', token),
  removeToken: () => localStorage.removeItem('accessToken'),
};
```

### Automatic Token Refresh

```tsx
// src/auth/utils/authHelpers.ts
export const setupTokenRefresh = (refreshToken: () => Promise<void>) => {
  let refreshTimeout: NodeJS.Timeout;

  const scheduleRefresh = (expiresIn: number) => {
    refreshTimeout = setTimeout(refreshToken, (expiresIn - 60) * 1000);
  };

  return {
    startTokenRefresh: (expiresIn: number) => scheduleRefresh(expiresIn),
    stopTokenRefresh: () => clearTimeout(refreshTimeout),
  };
};
```

## Security Considerations

1. **Token Storage**
   - Access tokens are stored in localStorage
   - Refresh tokens should be stored in HTTP-only cookies
   - Sensitive data should never be stored in localStorage

2. **CSRF Protection**
   - Implement CSRF tokens for POST requests
   - Use SameSite cookie attributes

3. **XSS Protection**
   - Sanitize user inputs
   - Use Content Security Policy (CSP)
   - Avoid storing sensitive data in localStorage

## TypeScript Support

The authentication system is fully typed with TypeScript. Key types are located in `src/auth/types/auth.types.ts`.

### Example Type Usage

```tsx
import { User, AuthState } from '../auth/types/auth.types';

// Using with hooks
const { user } = useAuth();
const userEmail: string = user?.email ?? '';

// Type checking for auth state
const checkAuthState = (state: AuthState) => {
  if (state.isAuthenticated && state.user) {
    return state.user.email;
  }
  return null;
};
```

## Implementation Examples

### Login Implementation

```tsx
// src/components/auth/LoginForm.tsx
import React, { useState } from 'react';
import { useAuth } from '../../auth/hooks/useAuth';
import { useNavigate } from 'react-router-dom';

export const LoginForm: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, error, isLoading } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (error) {
      // Error handling is managed by AuthContext
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form implementation */}
    </form>
  );
};
```

### Protected Route Implementation

```tsx
// src/components/common/ProtectedRoute.tsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../auth/hooks/useAuth';

export const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ 
  children 
}) => {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
};
```

## Environment Setup

Create a `.env` file in your project root:

```env
REACT_APP_API_URL=https://api.example.com
REACT_APP_AUTH_TOKEN_EXPIRY=3600
REACT_APP_REFRESH_TOKEN_EXPIRY=604800
```

## Contributing

Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please open an issue in the GitHub repository or contact the maintenance team.

---

Last Updated: 2025-08-31 14:45:59 UTC
Maintainer: @HarshYadav 
