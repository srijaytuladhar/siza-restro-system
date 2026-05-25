import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { tap } from 'rxjs/operators';
import { Observable } from 'rxjs';

export interface AuthResponse {
  token: string;
  username: string;
  role: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'https://dec-decided-phil-whom.trycloudflare.com/api/auth';

  currentUser = signal<{ username: string; role: string } | null>(null);
  isLoggedIn = computed(() => this.currentUser() !== null);

  constructor(private http: HttpClient) {
    this.loadSession();
  }

  private loadSession() {
    const token = localStorage.getItem('token');
    const username = localStorage.getItem('username');
    const role = localStorage.getItem('role');

    if (token && username && role) {
      this.currentUser.set({ username, role });
    }
  }

  login(username: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/login`, { username, password }).pipe(
      tap(res => {
        localStorage.setItem('token', res.token);
        localStorage.setItem('username', res.username);
        localStorage.setItem('role', res.role);
        this.currentUser.set({ username: res.username, role: res.role });
      })
    );
  }

  logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('username');
    localStorage.removeItem('role');
    this.currentUser.set(null);
  }

  isAuthenticated(): boolean {
    return localStorage.getItem('token') !== null;
  }

  hasRole(role: string): boolean {
    const user = this.currentUser();
    return user ? user.role === role || user.role === 'ROLE_' + role : false;
  }
}
