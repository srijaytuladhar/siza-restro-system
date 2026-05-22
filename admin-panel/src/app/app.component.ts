import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive, Router } from '@angular/router';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatTooltipModule } from '@angular/material/tooltip';
import { AuthService } from './core/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    MatSidenavModule,
    MatToolbarModule,
    MatListModule,
    MatIconModule,
    MatButtonModule,
    MatTooltipModule
  ],
  template: `
    <div [class.light-theme]="isLightTheme" class="app-wrapper">
      @if (authService.isLoggedIn()) {
        <mat-sidenav-container class="sidenav-container">
          <!-- Sidebar Sidenav -->
          <mat-sidenav #drawer class="sidenav" 
                       [mode]="'side'" 
                       [opened]="true">
            <div class="logo-area">
              <mat-icon class="logo-icon glow-text">restaurant</mat-icon>
              <span class="logo-text">Siza<span class="logo-highlight">Restro</span></span>
            </div>
            
            <mat-nav-list class="nav-list">
              <a mat-list-item routerLink="/dashboard" routerLinkActive="active-link" class="nav-item">
                <mat-icon matListItemIcon>dashboard</mat-icon>
                <span matListItemTitle>Dashboard</span>
              </a>
              <a mat-list-item routerLink="/orders" routerLinkActive="active-link" class="nav-item">
                <mat-icon matListItemIcon>soup_kitchen</mat-icon>
                <span matListItemTitle>Kitchen Board</span>
              </a>
              <a mat-list-item routerLink="/tables" routerLinkActive="active-link" class="nav-item">
                <mat-icon matListItemIcon>table_restaurant</mat-icon>
                <span matListItemTitle>Tables Management</span>
              </a>
              <a mat-list-item routerLink="/menu" routerLinkActive="active-link" class="nav-item">
                <mat-icon matListItemIcon>menu_book</mat-icon>
                <span matListItemTitle>Menu Creator</span>
              </a>
            </mat-nav-list>

            <div class="user-profile-footer">
              <div class="avatar">{{ userInitials() }}</div>
              <div class="user-details">
                <div class="username">{{ authService.currentUser()?.username }}</div>
                <div class="user-role">{{ formatRole(authService.currentUser()?.role) }}</div>
              </div>
            </div>
          </mat-sidenav>

          <mat-sidenav-content class="content-wrapper">
            <!-- App Header Toolbar -->
            <mat-toolbar class="toolbar glass-card">
              <span class="spacer"></span>
              
              <!-- Dark / Light Theme Toggle -->
              <button mat-icon-button (click)="toggleTheme()" [matTooltip]="isLightTheme ? 'Switch to Dark Mode' : 'Switch to Light Mode'">
                <mat-icon>{{ isLightTheme ? 'dark_mode' : 'light_mode' }}</mat-icon>
              </button>

              <span class="divider"></span>

              <!-- Logout Button -->
              <button mat-icon-button color="warn" (click)="onLogout()" matTooltip="Logout">
                <mat-icon>logout</mat-icon>
              </button>
            </mat-toolbar>

            <!-- Main Render Area -->
            <main class="main-content">
              <router-outlet></router-outlet>
            </main>
          </mat-sidenav-content>
        </mat-sidenav-container>
      } @else {
        <!-- Direct render without Sidenav Layout for Login screen -->
        <div class="login-layout">
          <router-outlet></router-outlet>
        </div>
      }
    </div>
  `,
  styles: [`
    .app-wrapper {
      min-height: 100vh;
      background-color: var(--bg-primary);
      transition: background-color 0.4s ease;
    }
    .sidenav-container {
      height: 100vh;
    }
    .sidenav {
      width: var(--sidebar-width);
      background-color: var(--bg-secondary) !important;
      border-right: 1px solid var(--glass-border) !important;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }
    .logo-area {
      padding: 24px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-bottom: 1px solid var(--glass-border);
    }
    .logo-icon {
      color: var(--primary);
      font-size: 28px;
      width: 28px;
      height: 28px;
    }
    .logo-text {
      font-size: 20px;
      font-weight: 700;
      letter-spacing: 0.5px;
      color: var(--color-text-primary);
    }
    .logo-highlight {
      color: var(--primary);
    }
    .nav-list {
      padding-top: 16px;
      flex-grow: 1;
    }
    .nav-item {
      margin: 4px 12px;
      border-radius: 8px !important;
      color: var(--color-text-secondary) !important;
      transition: all 0.3s ease !important;
    }
    .nav-item:hover {
      background-color: rgba(255, 255, 255, 0.05) !important;
      color: var(--color-text-primary) !important;
    }
    .active-link {
      background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%) !important;
      color: white !important;
      box-shadow: 0 4px 12px var(--primary-glow);
    }
    .active-link mat-icon {
      color: white !important;
    }
    .content-wrapper {
      background-color: var(--bg-primary) !important;
      transition: background-color 0.4s ease;
    }
    .toolbar {
      background: var(--bg-glass) !important;
      border-radius: 0 !important;
      border-left: none !important;
      border-right: none !important;
      border-top: none !important;
      height: 64px;
      display: flex;
      align-items: center;
      padding: 0 24px !important;
    }
    .spacer {
      flex: 1 1 auto;
    }
    .divider {
      width: 1px;
      height: 24px;
      background-color: var(--glass-border);
      margin: 0 16px;
    }
    .user-profile-footer {
      padding: 16px 24px;
      display: flex;
      align-items: center;
      gap: 12px;
      border-top: 1px solid var(--glass-border);
      position: absolute;
      bottom: 0;
      width: 100%;
      background-color: var(--bg-secondary);
    }
    .avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 16px;
    }
    .user-details {
      display: flex;
      flex-direction: column;
    }
    .username {
      font-size: 14px;
      font-weight: 600;
      color: var(--color-text-primary);
    }
    .user-role {
      font-size: 12px;
      color: var(--color-text-muted);
    }
    .login-layout {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background-color: var(--bg-primary);
    }
  `]
})
export class AppComponent {
  authService = inject(AuthService);
  router = inject(Router);
  
  isLightTheme = false;

  toggleTheme() {
    this.isLightTheme = !this.isLightTheme;
  }

  userInitials(): string {
    const username = this.authService.currentUser()?.username || 'A';
    return username.substring(0, 2).toUpperCase();
  }

  formatRole(role: string | undefined): string {
    if (!role) return '';
    return role.replace('ROLE_', '');
  }

  onLogout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
