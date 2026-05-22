import { Component, OnInit, AfterViewInit, ViewChild, ElementRef, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ApiService, DashboardStats } from '../../core/api.service';
import Chart from 'chart.js/auto';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatIconModule,
    MatCardModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="dashboard-container">
      <div class="header">
        <h1 class="glow-text">Analytics Dashboard</h1>
        <p class="subtitle">Overview of restaurant performance, sales and table statuses.</p>
      </div>

      @if (isLoading) {
        <div class="loading-container">
          <mat-spinner diameter="60" color="primary"></mat-spinner>
          <p>Loading analytics...</p>
        </div>
      } @else if (stats) {
        <!-- Stats Cards Grid -->
        <div class="stats-grid">
          <div class="stat-card glass-card">
            <div class="card-icon revenue-icon">
              <mat-icon>monetization_on</mat-icon>
            </div>
            <div class="card-info">
              <span class="label">Total Revenue</span>
              <h2 class="value">Rs. {{ stats.totalRevenue | number:'1.2-2' }}</h2>
              <span class="trend up"><mat-icon>trending_up</mat-icon> +12% this week</span>
            </div>
          </div>

          <div class="stat-card glass-card">
            <div class="card-icon tables-icon">
              <mat-icon>table_restaurant</mat-icon>
            </div>
            <div class="card-info">
              <span class="label">Active Tables</span>
              <h2 class="value">{{ stats.activeTablesCount }}</h2>
              <span class="trend info"><mat-icon>info</mat-icon> Dynamic check-ins</span>
            </div>
          </div>

          <div class="stat-card glass-card">
            <div class="card-icon orders-icon">
              <mat-icon>receipt_long</mat-icon>
            </div>
            <div class="card-info">
              <span class="label">Total Orders</span>
              <h2 class="value">{{ stats.totalOrdersCount }}</h2>
              <span class="trend up"><mat-icon>trending_up</mat-icon> +8% from yesterday</span>
            </div>
          </div>
        </div>

        <!-- Charts Section -->
        <div class="charts-grid">
          <div class="chart-card glass-card">
            <h3>Weekly Sales Revenue (Rs.)</h3>
            <div class="chart-wrapper">
              <canvas #salesChart></canvas>
            </div>
          </div>

          <div class="chart-card glass-card">
            <h3>Popular Menu Items</h3>
            <div class="chart-wrapper">
              <canvas #popularChart></canvas>
            </div>
          </div>
        </div>
      } @else {
        <div class="error-container glass-card">
          <mat-icon color="warn">error_outline</mat-icon>
          <h3>Failed to load statistics.</h3>
          <p>Please check your backend connection and database configurations.</p>
        </div>
      }
    </div>
  `,
  styles: [`
    .dashboard-container {
      display: flex;
      flex-direction: column;
      gap: 24px;
    }
    .header h1 {
      font-size: 28px;
      margin-bottom: 4px;
    }
    .subtitle {
      color: var(--color-text-secondary);
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 20px;
    }
    .stat-card {
      display: flex;
      align-items: center;
      gap: 20px;
      padding: 24px !important;
    }
    .card-icon {
      width: 56px;
      height: 56px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card-icon mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
      color: white;
    }
    .revenue-icon {
      background: linear-gradient(135deg, #06d6a0 0%, #118ab2 100%);
      box-shadow: 0 4px 15px rgba(6, 214, 160, 0.4);
    }
    .tables-icon {
      background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
      box-shadow: 0 4px 15px var(--primary-glow);
    }
    .orders-icon {
      background: linear-gradient(135deg, #ffd166 0%, #f77f00 100%);
      box-shadow: 0 4px 15px rgba(255, 209, 102, 0.4);
    }
    .card-info {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .label {
      font-size: 14px;
      color: var(--color-text-secondary);
      font-weight: 500;
    }
    .value {
      font-size: 24px;
      font-weight: 700;
      color: var(--color-text-primary);
    }
    .trend {
      font-size: 12px;
      display: flex;
      align-items: center;
      gap: 4px;
      font-weight: 500;
    }
    .trend mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }
    .trend.up {
      color: var(--color-success);
    }
    .trend.info {
      color: var(--accent);
    }
    .charts-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 20px;
    }
    @media (max-width: 1024px) {
      .charts-grid {
        grid-template-columns: 1fr;
      }
    }
    .chart-card {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .chart-card h3 {
      font-size: 18px;
      color: var(--color-text-primary);
    }
    .chart-wrapper {
      position: relative;
      width: 100%;
      height: 320px;
    }
    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      padding: 100px 0;
      color: var(--color-text-secondary);
    }
    .error-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 12px;
      padding: 40px;
      text-align: center;
    }
  `]
})
export class DashboardComponent implements OnInit, AfterViewInit {
  private apiService = inject(ApiService);

  @ViewChild('salesChart') salesChartRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('popularChart') popularChartRef!: ElementRef<HTMLCanvasElement>;

  stats: DashboardStats | null = null;
  isLoading = true;

  salesChartInstance: Chart | null = null;
  popularChartInstance: Chart | null = null;

  ngOnInit() {
    this.loadStats();
  }

  ngAfterViewInit() {
    // Charts will render inside loadStats once request completes
  }

  loadStats() {
    this.isLoading = true;
    this.apiService.getDashboardStats().subscribe({
      next: (data) => {
        this.stats = data;
        this.isLoading = false;
        // Let change detection run, then render charts
        setTimeout(() => this.renderCharts(), 50);
      },
      error: (err) => {
        console.error('Failed to load stats', err);
        this.isLoading = false;
      }
    });
  }

  renderCharts() {
    if (!this.stats) return;

    // 1. Sales Chart (Line Chart)
    if (this.salesChartRef) {
      if (this.salesChartInstance) {
        this.salesChartInstance.destroy();
      }

      const labels = this.stats.weeklySales.map(ws => ws.date);
      const dataValues = this.stats.weeklySales.map(ws => ws.revenue);

      this.salesChartInstance = new Chart(this.salesChartRef.nativeElement, {
        type: 'line',
        data: {
          labels: labels,
          datasets: [{
            label: 'Sales (Rs.)',
            data: dataValues,
            borderColor: '#9d4edd',
            backgroundColor: 'rgba(157, 78, 221, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false }
          },
          scales: {
            x: {
              grid: { color: 'rgba(255, 255, 255, 0.05)' },
              ticks: { color: '#a99ec6' }
            },
            y: {
              grid: { color: 'rgba(255, 255, 255, 0.05)' },
              ticks: { color: '#a99ec6' }
            }
          }
        }
      });
    }

    // 2. Popular Food Items (Doughnut Chart)
    if (this.popularChartRef) {
      if (this.popularChartInstance) {
        this.popularChartInstance.destroy();
      }

      const labels = this.stats.popularItems.map(pi => pi.name);
      const dataValues = this.stats.popularItems.map(pi => pi.orderCount);

      // Handle fallback if popularItems is empty
      const chartLabels = labels.length ? labels : ['No orders yet'];
      const chartData = dataValues.length ? dataValues : [1];

      this.popularChartInstance = new Chart(this.popularChartRef.nativeElement, {
        type: 'doughnut',
        data: {
          labels: chartLabels,
          datasets: [{
            data: chartData,
            backgroundColor: [
              '#9d4edd',
              '#3f37c9',
              '#4cc9f0',
              '#06d6a0',
              '#ffd166'
            ],
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom',
              labels: { color: '#a99ec6', font: { family: 'Outfit' } }
            }
          }
        }
      });
    }
  }
}
