import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { ApiService, Order } from '../../core/api.service';

interface KanbanColumn {
  title: string;
  statuses: string[];
  colorVar: string;
  icon: string;
}

@Component({
  selector: 'app-orders',
  standalone: true,
  imports: [
    CommonModule,
    MatIconModule,
    MatCardModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatTooltipModule
  ],
  template: `
    <div class="orders-board-container">
      <div class="header">
        <div class="title-section">
          <h1 class="glow-text">Kitchen Kanban Board</h1>
          <p class="subtitle">Monitor and update active kitchen orders in real-time.</p>
        </div>
        <div class="ws-badge connected">
          <mat-icon>sync</mat-icon>
          <span>Auto-refresh Active</span>
        </div>
      </div>

      @if (isLoading) {
        <div class="loading-container">
          <mat-spinner diameter="60" color="primary"></mat-spinner>
          <p>Loading active orders...</p>
        </div>
      } @else {
        <!-- Kanban Columns Board -->
        <div class="kanban-board">
          @for (column of columns; track column.title) {
            <div class="kanban-column">
              <div class="column-header" [style.border-color]="'var(' + column.colorVar + ')'">
                <div class="header-left">
                  <mat-icon [style.color]="'var(' + column.colorVar + ')'">{{ column.icon }}</mat-icon>
                  <h3>{{ column.title }}</h3>
                </div>
                <span class="count-badge" [style.background-color]="'var(' + column.colorVar + ')'">
                  {{ getOrdersForColumn(column).length }}
                </span>
              </div>

              <div class="cards-container">
                @if (getOrdersForColumn(column).length === 0) {
                  <div class="empty-column-placeholder">
                    <mat-icon>inbox</mat-icon>
                    <p>No orders in this stage</p>
                  </div>
                }

                @for (order of getOrdersForColumn(column); track order.id) {
                  <div class="order-card glass-card" [class.new-pulse]="isNewOrder(order.id)">
                    <div class="card-top">
                      <span class="order-id">#{{ order.id }}</span>
                      <span class="table-badge">Table {{ order.tableNumber }}</span>
                    </div>

                    <div class="time-elapsed">
                      <mat-icon>schedule</mat-icon>
                      <span>{{ formatTime(order.createdAt) }}</span>
                    </div>

                    <div class="items-list">
                      @for (item of order.items; track item.id) {
                        <div class="item-row">
                          <span class="item-qty">{{ item.quantity }}x</span>
                          <span class="item-name">{{ item.menuItemName }}</span>
                        </div>
                      }
                    </div>

                    @if (order.specialInstructions) {
                      <div class="instructions-box">
                        <strong>Notes:</strong> {{ order.specialInstructions }}
                      </div>
                    }

                    <div class="card-footer">
                      <span class="total-price">Rs. {{ order.totalAmount | number:'1.2-2' }}</span>
                      <span class="payment-badge" [class.paid]="order.paymentStatus === 'PAID'">
                        {{ order.paymentStatus === 'PAID' ? 'Paid' : 'Unpaid' }}
                      </span>
                    </div>

                    <!-- Action buttons -->
                    <div class="action-buttons">
                      @if (order.status === 'WAITING') {
                        <button mat-flat-button class="btn-action accept" (click)="updateStatus(order.id, 'ACCEPTED')">
                          <mat-icon>check</mat-icon> Accept
                        </button>
                        <button mat-stroked-button class="btn-action cancel" (click)="updateStatus(order.id, 'CANCELLED')">
                          <mat-icon>close</mat-icon> Reject
                        </button>
                      }

                      @if (order.status === 'ACCEPTED') {
                        <button mat-flat-button class="btn-action prepare" (click)="updateStatus(order.id, 'PREPARING')">
                          <mat-icon>cooking</mat-icon> Cook
                        </button>
                      }

                      @if (order.status === 'PREPARING') {
                        <button mat-flat-button class="btn-action ready" (click)="updateStatus(order.id, 'READY')">
                          <mat-icon>restaurant</mat-icon> Ready
                        </button>
                      }

                      @if (order.status === 'READY') {
                        <button mat-flat-button class="btn-action serve" (click)="updateStatus(order.id, 'SERVED')">
                          <mat-icon>room_service</mat-icon> Serve
                        </button>
                      }
                    </div>
                  </div>
                }
              </div>
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .orders-board-container {
      display: flex;
      flex-direction: column;
      gap: 24px;
      height: 100%;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
    }
    .header h1 {
      font-size: 28px;
      margin-bottom: 4px;
    }
    .subtitle {
      color: var(--color-text-secondary);
    }
    .ws-badge {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      border-radius: 20px;
      background: rgba(239, 71, 111, 0.15);
      border: 1px solid rgba(239, 71, 111, 0.3);
      color: var(--color-danger);
      font-size: 14px;
      font-weight: 500;
      transition: all 0.3s ease;
    }
    .ws-badge.connected {
      background: rgba(6, 214, 160, 0.15);
      border: 1px solid rgba(6, 214, 160, 0.3);
      color: var(--color-success);
    }
    .ws-badge mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
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
    .kanban-board {
      display: flex;
      gap: 20px;
      overflow-x: auto;
      padding-bottom: 16px;
      height: calc(100vh - 200px);
      align-items: flex-start;
    }
    .kanban-column {
      flex: 0 0 320px;
      background: var(--bg-surface);
      border-radius: 16px;
      border: 1px solid var(--glass-border);
      display: flex;
      flex-direction: column;
      max-height: 100%;
      box-shadow: var(--glass-shadow);
    }
    .column-header {
      padding: 16px;
      border-bottom: 3px solid;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: rgba(0, 0, 0, 0.1);
      border-top-left-radius: 16px;
      border-top-right-radius: 16px;
    }
    .header-left {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .column-header h3 {
      font-size: 16px;
      margin: 0;
      color: var(--color-text-primary);
    }
    .count-badge {
      padding: 2px 10px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 700;
      color: white;
    }
    .cards-container {
      padding: 12px;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      gap: 12px;
      flex-grow: 1;
    }
    .empty-column-placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 40px 0;
      color: var(--color-text-muted);
    }
    .empty-column-placeholder mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }
    .order-card {
      background: rgba(255, 255, 255, 0.02) !important;
      border-radius: 12px;
      padding: 16px !important;
      border: 1px solid var(--glass-border);
      display: flex;
      flex-direction: column;
      gap: 12px;
      transition: all 0.3s ease;
    }
    .order-card:hover {
      background: rgba(255, 255, 255, 0.05) !important;
      transform: translateY(-2px);
    }
    .new-pulse {
      animation: pulseGlow 1.5s infinite alternate;
      border-color: var(--primary) !important;
    }
    @keyframes pulseGlow {
      0% {
        box-shadow: 0 0 5px var(--primary-glow);
      }
      100% {
        box-shadow: 0 0 15px var(--primary);
      }
    }
    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .order-id {
      font-size: 14px;
      font-weight: 700;
      color: var(--primary);
    }
    .table-badge {
      background: rgba(255, 255, 255, 0.08);
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
      color: var(--color-text-primary);
    }
    .time-elapsed {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      color: var(--color-text-muted);
    }
    .time-elapsed mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }
    .items-list {
      display: flex;
      flex-direction: column;
      gap: 4px;
      padding: 8px 0;
      border-top: 1px dashed var(--glass-border);
      border-bottom: 1px dashed var(--glass-border);
    }
    .item-row {
      display: flex;
      gap: 8px;
      font-size: 13px;
    }
    .item-qty {
      font-weight: 700;
      color: var(--accent);
    }
    .item-name {
      color: var(--color-text-secondary);
    }
    .instructions-box {
      font-size: 12px;
      background: rgba(255, 209, 102, 0.08);
      border-left: 3px solid var(--color-warning);
      padding: 6px 10px;
      border-radius: 4px;
      color: var(--color-warning);
    }
    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .total-price {
      font-size: 15px;
      font-weight: 700;
      color: var(--color-text-primary);
    }
    .payment-badge {
      font-size: 11px;
      padding: 2px 6px;
      border-radius: 4px;
      background: rgba(255, 255, 255, 0.05);
      color: var(--color-text-muted);
      border: 1px solid var(--glass-border);
    }
    .payment-badge.paid {
      background: rgba(6, 214, 160, 0.1);
      color: var(--color-success);
      border-color: rgba(6, 214, 160, 0.2);
    }
    .action-buttons {
      display: flex;
      gap: 8px;
      margin-top: 4px;
    }
    .btn-action {
      flex: 1;
      height: 36px !important;
      line-height: 36px !important;
      font-size: 13px !important;
      border-radius: 6px !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      gap: 4px !important;
    }
    .btn-action.accept {
      background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
      color: white;
    }
    .btn-action.prepare {
      background: linear-gradient(135deg, var(--secondary) 0%, var(--accent) 100%);
      color: white;
    }
    .btn-action.ready {
      background: linear-gradient(135deg, var(--color-success) 0%, #05a87e 100%);
      color: white;
    }
    .btn-action.serve {
      background: linear-gradient(135deg, var(--color-info) 0%, #0d6e8e 100%);
      color: white;
    }
    .btn-action.cancel {
      border-color: var(--color-danger) !important;
      color: var(--color-danger) !important;
    }
  `]
})
export class OrdersComponent implements OnInit, OnDestroy {
  private apiService = inject(ApiService);

  orders: Order[] = [];
  isLoading = true;
  private pollInterval: any;

  // New order highlighted IDs
  newOrderIds: Set<number> = new Set();

  columns: KanbanColumn[] = [
    { title: 'New Orders', statuses: ['WAITING'], colorVar: '--primary', icon: 'mark_as_unread' },
    { title: 'In Kitchen', statuses: ['ACCEPTED', 'PREPARING'], colorVar: '--secondary', icon: 'soup_kitchen' },
    { title: 'Ready to Serve', statuses: ['READY'], colorVar: '--color-success', icon: 'restaurant' },
    { title: 'Completed', statuses: ['SERVED'], colorVar: '--color-text-secondary', icon: 'check_circle' },
    { title: 'Cancelled', statuses: ['CANCELLED'], colorVar: '--color-danger', icon: 'cancel' }
  ];

  ngOnInit() {
    this.loadOrders(true);
    
    // Auto-poll active orders every 5 seconds
    this.pollInterval = setInterval(() => {
      this.loadOrders(false);
    }, 5000);
  }

  ngOnDestroy() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }
  }

  loadOrders(isInitial = false) {
    if (isInitial) {
      this.isLoading = true;
    }
    this.apiService.getOrders().subscribe({
      next: (data) => {
        this.detectNewOrders(data);
        this.orders = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Failed to load orders', err);
        this.isLoading = false;
      }
    });
  }

  detectNewOrders(newOrders: Order[]) {
    if (this.orders.length === 0) return;
    for (const order of newOrders) {
      const exists = this.orders.some(o => o.id === order.id);
      if (!exists && order.status === 'WAITING') {
        this.triggerGlow(order.id);
      }
    }
  }

  triggerGlow(orderId: number) {
    this.newOrderIds.add(orderId);
    setTimeout(() => {
      this.newOrderIds.delete(orderId);
    }, 10000); // Highlight for 10 seconds
  }

  isNewOrder(orderId: number): boolean {
    return this.newOrderIds.has(orderId);
  }

  getOrdersForColumn(column: KanbanColumn): Order[] {
    return this.orders.filter(order => column.statuses.includes(order.status));
  }

  updateStatus(orderId: number, nextStatus: string) {
    this.apiService.updateOrderStatus(orderId, nextStatus).subscribe({
      next: (updatedOrder) => {
        // Find and replace locally (though WebSocket will also broadcast, local update is faster/safety net)
        const idx = this.orders.findIndex(o => o.id === orderId);
        if (idx > -1) {
          this.orders[idx] = updatedOrder;
        }
      },
      error: (err) => {
        console.error('Failed to update status', err);
      }
    });
  }

  formatTime(createdAtString: string): string {
    if (!createdAtString) return 'Just now';
    try {
      const created = new Date(createdAtString);
      const diffMs = new Date().getTime() - created.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      
      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m ago`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h ago`;
      return created.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return 'Just now';
    }
  }
}
