import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="login-container">
      <!-- Background Decorative Lights -->
      <div class="orb orb-1"></div>
      <div class="orb orb-2"></div>
      
      <div class="login-card glass-card">
        <div class="header">
          <mat-icon class="logo-icon glow-text">restaurant</mat-icon>
          <h2>Welcome to SizaRestro</h2>
          <p class="subtitle">Admin Panel Authorization</p>
        </div>

        <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="form">
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Username</mat-label>
            <input matInput formControlName="username" placeholder="Enter your username" autocomplete="username">
            <mat-icon matSuffix>person</mat-icon>
            @if (loginForm.get('username')?.hasError('required')) {
              <mat-error>Username is required</mat-error>
            }
          </mat-form-field>

          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Password</mat-label>
            <input matInput [type]="hidePassword ? 'password' : 'text'" formControlName="password" placeholder="Enter your password" autocomplete="current-password">
            <button type="button" mat-icon-button matSuffix (click)="hidePassword = !hidePassword">
              <mat-icon>{{ hidePassword ? 'visibility_off' : 'visibility' }}</mat-icon>
            </button>
            @if (loginForm.get('password')?.hasError('required')) {
              <mat-error>Password is required</mat-error>
            }
          </mat-form-field>

          @if (errorMessage) {
            <div class="error-banner">
              <mat-icon>error_outline</mat-icon>
              <span>{{ errorMessage }}</span>
            </div>
          }

          <button mat-flat-button class="submit-button btn-premium" 
                  [disabled]="loginForm.invalid || isLoading" 
                  type="submit">
            @if (isLoading) {
              <mat-spinner diameter="24" color="accent"></mat-spinner>
            } @else {
              <span>SIGN IN</span>
            }
          </button>
        </form>
      </div>
    </div>
  `,
  styles: [`
    .login-container {
      position: relative;
      width: 100vw;
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      background: #060212;
      overflow: hidden;
    }
    .orb {
      position: absolute;
      border-radius: 50%;
      filter: blur(100px);
      z-index: 0;
      opacity: 0.5;
    }
    .orb-1 {
      width: 400px;
      height: 400px;
      background: var(--primary);
      top: -100px;
      left: -100px;
    }
    .orb-2 {
      width: 500px;
      height: 500px;
      background: var(--secondary);
      bottom: -150px;
      right: -150px;
    }
    .login-card {
      position: relative;
      z-index: 1;
      width: 100%;
      max-width: 420px;
      padding: 40px !important;
      text-align: center;
      animation: fadeIn 0.8s ease-out;
    }
    .header {
      margin-bottom: 32px;
    }
    .logo-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: var(--primary);
      margin-bottom: 12px;
    }
    h2 {
      font-size: 24px;
      color: var(--color-text-primary);
      margin-bottom: 6px;
    }
    .subtitle {
      color: var(--color-text-secondary);
      font-size: 14px;
    }
    .form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .full-width {
      width: 100%;
    }
    .submit-button {
      height: 48px;
      border-radius: 12px !important;
      font-weight: 600;
      font-size: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .error-banner {
      background-color: rgba(239, 71, 111, 0.15);
      border: 1px solid var(--color-danger);
      color: var(--color-danger);
      padding: 12px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      margin-bottom: 8px;
      text-align: left;
    }
    @keyframes fadeIn {
      from {
        opacity: 0;
        transform: translateY(20px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    /* Input custom overrides */
    ::ng-deep .mat-mdc-text-field-wrapper {
      background-color: rgba(255, 255, 255, 0.03) !important;
    }
    ::ng-deep .mat-mdc-form-field-focus-active .mdc-outlined-credential-border {
      border-color: var(--primary) !important;
    }
  `]
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  loginForm: FormGroup = this.fb.group({
    username: ['', [Validators.required]],
    password: ['', [Validators.required]]
  });

  hidePassword = true;
  isLoading = false;
  errorMessage = '';

  onSubmit() {
    if (this.loginForm.invalid) return;
    
    this.isLoading = true;
    this.errorMessage = '';
    const { username, password } = this.loginForm.value;

    this.authService.login(username, password).subscribe({
      next: () => {
        this.isLoading = false;
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.isLoading = false;
        this.errorMessage = err?.error?.message || 'Invalid username or password.';
        console.error(err);
      }
    });
  }
}
