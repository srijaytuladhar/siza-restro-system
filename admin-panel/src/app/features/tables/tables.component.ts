import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatTooltipModule } from '@angular/material/tooltip';
import { ApiService, Table } from '../../core/api.service';
import { WebsocketService } from '../../core/websocket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-tables',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatIconModule,
    MatCardModule,
    MatButtonModule,
    MatTooltipModule
  ],
  template: `
    <div class="tables-container">
      <div class="header">
        <div class="title-section">
          <h1 class="glow-text">Table Management</h1>
          <p class="subtitle">Add, edit, and print secure QR codes for dining tables.</p>
        </div>
        <button mat-flat-button class="btn-premium add-btn" (click)="openAddModal()">
          <mat-icon>add</mat-icon> Add New Table
        </button>
      </div>

      <!-- Quick Filter Bar -->
      <div class="filter-bar">
        <button class="filter-chip" [class.active]="selectedFilter === 'ALL'" (click)="selectedFilter = 'ALL'">
          All Tables
        </button>
        <button class="filter-chip" [class.active]="selectedFilter === 'AVAILABLE'" (click)="selectedFilter = 'AVAILABLE'">
          Available
        </button>
        <button class="filter-chip" [class.active]="selectedFilter === 'RESERVED'" (click)="selectedFilter = 'RESERVED'">
          Reserved
        </button>
        <button class="filter-chip" [class.active]="selectedFilter === 'OCCUPIED'" (click)="selectedFilter = 'OCCUPIED'">
          Occupied
        </button>
      </div>

      @if (isLoading) {
        <div class="loading-container">
          <p>Loading table configurations...</p>
        </div>
      } @else {
        <!-- Tables Grid -->
        <div class="tables-grid">
          @for (table of filteredTables; track table.id) {
            <div class="table-card glass-card" [class]="table.status.toLowerCase()">
              <div class="card-header">
                <span class="table-number">Table {{ table.tableNumber }}</span>
                <span class="status-badge" [class]="table.status.toLowerCase()">
                  {{ formatStatus(table.status) }}
                </span>
              </div>

              <div class="card-details">
                <div class="detail-row">
                  <mat-icon>groups</mat-icon>
                  <span>Capacity: <strong>{{ table.capacity }} guests</strong></span>
                </div>
                <div class="detail-row">
                  <mat-icon>vpn_key</mat-icon>
                  <span class="token-text" [matTooltip]="table.qrCodeToken || ''">
                    Token: {{ truncateToken(table.qrCodeToken) }}
                  </span>
                </div>
              </div>

              <div class="card-actions">
                @if (table.status === 'OCCUPIED') {
                  <button mat-stroked-button class="btn-icon release" (click)="releaseTable(table.id!)" matTooltip="Release Table">
                    <mat-icon>lock_open</mat-icon> Release
                  </button>
                }
                <button mat-stroked-button class="btn-icon" (click)="viewQrCode(table)" matTooltip="View QR Code">
                  <mat-icon>qr_code_2</mat-icon> QR Code
                </button>
                <button mat-stroked-button class="btn-icon" (click)="openEditModal(table)" matTooltip="Edit Table">
                  <mat-icon>edit</mat-icon>
                </button>
                <button mat-stroked-button class="btn-icon delete" (click)="deleteTable(table.id!)" matTooltip="Delete Table">
                  <mat-icon>delete</mat-icon>
                </button>
              </div>
            </div>
          }
        </div>
      }

      <!-- Add/Edit Table Modal -->
      @if (showFormModal) {
        <div class="modal-overlay" (click)="closeFormModal()">
          <div class="modal-content glass-card" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <h2>{{ isEditMode ? 'Edit Table ' + formTableNumber : 'Create New Table' }}</h2>
              <button mat-icon-button (click)="closeFormModal()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
            <form (ngSubmit)="saveTable()" class="modal-form">
              <div class="form-group">
                <label for="tableNumber">Table Number / Label</label>
                <input type="text" id="tableNumber" name="tableNumber" [(ngModel)]="formTableNumber" required placeholder="e.g. 5, VIP-1">
              </div>
              <div class="form-group">
                <label for="capacity">Seating Capacity</label>
                <input type="number" id="capacity" name="capacity" [(ngModel)]="formCapacity" required min="1">
              </div>
              <div class="form-actions">
                <button type="button" mat-stroked-button (click)="closeFormModal()">Cancel</button>
                <button type="submit" mat-flat-button class="btn-premium">
                  {{ isEditMode ? 'Save Changes' : 'Create Table' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      }

      <!-- QR Viewer Modal -->
      @if (showQrModal && selectedTableForQr) {
        <div class="modal-overlay" (click)="closeQrModal()">
          <div class="modal-content glass-card qr-modal" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <h2>Table {{ selectedTableForQr.tableNumber }} QR Code</h2>
              <button mat-icon-button (click)="closeQrModal()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
            
            <div class="qr-print-area" id="qr-code-print">
              <div class="qr-brand">
                <span class="brand-title">SizaRestro</span>
                <span class="brand-sub">Scan to View Menu & Order</span>
              </div>
              <div class="qr-image-wrapper">
                @if (selectedTableForQr.qrCodeBase64) {
                  <img [src]="'data:image/png;base64,' + selectedTableForQr.qrCodeBase64" alt="Table QR Code">
                } @else {
                  <div class="no-qr">
                    <mat-icon>error_outline</mat-icon>
                    <span>No QR Code Generated</span>
                  </div>
                }
              </div>
              <div class="qr-footer">
                <h3>Table {{ selectedTableForQr.tableNumber }}</h3>
                <p>Capacity: {{ selectedTableForQr.capacity }} guests</p>
              </div>
            </div>

            <div class="modal-actions">
              <button mat-stroked-button (click)="closeQrModal()">Close</button>
              <button mat-flat-button class="btn-premium" (click)="printQrCode()">
                <mat-icon>print</mat-icon> Print QR Code
              </button>
            </div>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .tables-container {
      display: flex;
      flex-direction: column;
      gap: 24px;
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
    .add-btn {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .filter-bar {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }
    .filter-chip {
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid var(--glass-border);
      color: var(--color-text-secondary);
      padding: 8px 16px;
      border-radius: 20px;
      font-family: var(--font-family);
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.3s ease;
    }
    .filter-chip:hover {
      background: rgba(255, 255, 255, 0.08);
      color: var(--color-text-primary);
    }
    .filter-chip.active {
      background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
      color: white;
      border-color: transparent;
      box-shadow: 0 4px 12px var(--primary-glow);
    }
    .loading-container {
      padding: 60px 0;
      text-align: center;
      color: var(--color-text-secondary);
    }
    .tables-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 20px;
    }
    .table-card {
      background: rgba(255, 255, 255, 0.02) !important;
      border-radius: 16px;
      padding: 20px !important;
      display: flex;
      flex-direction: column;
      gap: 16px;
      position: relative;
      border-top: 4px solid var(--glass-border) !important;
    }
    .table-card.available {
      border-top-color: var(--color-success) !important;
    }
    .table-card.reserved {
      border-top-color: var(--color-warning) !important;
    }
    .table-card.occupied {
      border-top-color: var(--color-danger) !important;
    }
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .table-number {
      font-size: 18px;
      font-weight: 700;
      color: var(--color-text-primary);
    }
    .status-badge {
      font-size: 11px;
      font-weight: 700;
      padding: 4px 8px;
      border-radius: 6px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .status-badge.available {
      background: rgba(6, 214, 160, 0.1);
      color: var(--color-success);
    }
    .status-badge.reserved {
      background: rgba(255, 209, 102, 0.1);
      color: var(--color-warning);
    }
    .status-badge.occupied {
      background: rgba(239, 71, 111, 0.1);
      color: var(--color-danger);
    }
    .card-details {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .detail-row {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: var(--color-text-secondary);
    }
    .detail-row mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      color: var(--color-text-muted);
    }
    .token-text {
      font-family: monospace;
      font-size: 12px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .card-actions {
      display: flex;
      gap: 8px;
      margin-top: 8px;
      border-top: 1px solid var(--glass-border);
      padding-top: 12px;
    }
    .btn-icon {
      height: 36px !important;
      line-height: 36px !important;
      padding: 0 10px !important;
      min-width: 36px !important;
      border-radius: 6px !important;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 4px;
      flex: 1;
      font-size: 13px !important;
      color: var(--color-text-secondary) !important;
      border-color: var(--glass-border) !important;
    }
    .btn-icon:hover {
      background: rgba(255, 255, 255, 0.05) !important;
      color: var(--color-text-primary) !important;
    }
    .btn-icon.delete:hover {
      border-color: var(--color-danger) !important;
      color: var(--color-danger) !important;
      background: rgba(239, 71, 111, 0.05) !important;
    }
    .btn-icon.release {
      border-color: var(--color-success) !important;
      color: var(--color-success) !important;
    }
    .btn-icon.release:hover {
      background: rgba(6, 214, 160, 0.08) !important;
      color: var(--color-success) !important;
    }

    /* Modal Overlay Styles */
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background: rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(8px);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      animation: fadeIn 0.25s ease;
    }
    .modal-content {
      width: 100%;
      max-width: 450px;
      background: var(--bg-glass) !important;
      border: 1px solid var(--glass-border);
      border-radius: 20px;
      padding: 24px;
      box-shadow: 0 20px 50px rgba(0,0,0,0.5);
      animation: slideUp 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    .modal-header h2 {
      font-size: 20px;
      color: var(--color-text-primary);
    }
    .modal-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .form-group {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .form-group label {
      font-size: 14px;
      color: var(--color-text-secondary);
      font-weight: 500;
    }
    .form-group input {
      background: rgba(0, 0, 0, 0.2);
      border: 1px solid var(--glass-border);
      border-radius: 8px;
      padding: 12px;
      color: var(--color-text-primary);
      font-family: var(--font-family);
      outline: none;
      transition: border-color 0.3s ease;
    }
    .form-group input:focus {
      border-color: var(--primary);
    }
    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      margin-top: 10px;
    }

    /* QR Modal Specific Styles */
    .qr-modal {
      max-width: 400px;
      text-align: center;
    }
    .qr-print-area {
      background: white;
      color: black;
      border-radius: 12px;
      padding: 24px;
      margin: 16px 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
    }
    .qr-brand {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .brand-title {
      font-size: 22px;
      font-weight: 800;
      color: #7209b7;
      letter-spacing: 0.5px;
    }
    .brand-sub {
      font-size: 11px;
      color: #666;
      font-weight: 500;
    }
    .qr-image-wrapper {
      width: 220px;
      height: 220px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 1px solid #eee;
      border-radius: 8px;
      padding: 8px;
      background: #fafafa;
    }
    .qr-image-wrapper img {
      max-width: 100%;
      max-height: 100%;
    }
    .no-qr {
      display: flex;
      flex-direction: column;
      align-items: center;
      color: #999;
      gap: 8px;
    }
    .qr-footer h3 {
      font-size: 18px;
      font-weight: 700;
      margin-bottom: 2px;
      color: #222;
    }
    .qr-footer p {
      font-size: 12px;
      color: #555;
    }
    .modal-actions {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      margin-top: 16px;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes slideUp {
      from { transform: translateY(20px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }

    /* Print styling to only print the QR card card */
    @media print {
      body * {
        visibility: hidden;
      }
      #qr-code-print, #qr-code-print * {
        visibility: visible;
      }
      #qr-code-print {
        position: absolute;
        left: 50%;
        top: 40%;
        transform: translate(-50%, -50%);
        border: none;
        box-shadow: none;
        padding: 0;
        margin: 0;
        width: 100%;
        max-width: 350px;
      }
    }
  `]
})
export class TablesComponent implements OnInit, OnDestroy {
  private apiService = inject(ApiService);
  private websocketService = inject(WebsocketService);
  private tableSub: Subscription | null = null;

  tables: Table[] = [];
  isLoading = true;
  selectedFilter: 'ALL' | 'AVAILABLE' | 'RESERVED' | 'OCCUPIED' = 'ALL';

  // Form handling
  showFormModal = false;
  isEditMode = false;
  editingTableId: number | null = null;
  formTableNumber = '';
  formCapacity = 4;

  // QR Viewer Modal
  showQrModal = false;
  selectedTableForQr: Table | null = null;

  ngOnInit() {
    this.loadTables(true);
    this.tableSub = this.websocketService.onTableUpdate().subscribe({
      next: () => {
        this.loadTables(false);
      }
    });
  }

  ngOnDestroy() {
    if (this.tableSub) {
      this.tableSub.unsubscribe();
    }
  }

  loadTables(showLoader = true) {
    if (showLoader) {
      this.isLoading = true;
    }
    this.apiService.getTables().subscribe({
      next: (data) => {
        // Map status occupied dynamically if backend returns it
        this.tables = data.map(t => ({
          ...t,
          status: (t.status as any) === 'OCCUPIED' ? 'OCCUPIED' : t.status
        }));
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Failed to load tables', err);
        this.isLoading = false;
      }
    });
  }

  get filteredTables(): Table[] {
    if (this.selectedFilter === 'ALL') {
      return this.tables;
    }
    return this.tables.filter(table => table.status === this.selectedFilter);
  }

  formatStatus(status: string): string {
    return status.toLowerCase();
  }

  truncateToken(token?: string): string {
    if (!token) return 'Generating...';
    return token.substring(0, 8) + '...';
  }

  openAddModal() {
    this.isEditMode = false;
    this.editingTableId = null;
    this.formTableNumber = '';
    this.formCapacity = 4;
    this.showFormModal = true;
  }

  openEditModal(table: Table) {
    this.isEditMode = true;
    this.editingTableId = table.id!;
    this.formTableNumber = table.tableNumber;
    this.formCapacity = table.capacity;
    this.showFormModal = true;
  }

  closeFormModal() {
    this.showFormModal = false;
  }

  saveTable() {
    if (!this.formTableNumber.trim() || this.formCapacity <= 0) return;

    const payload = {
      tableNumber: this.formTableNumber.trim(),
      capacity: this.formCapacity
    };

    if (this.isEditMode && this.editingTableId !== null) {
      this.apiService.updateTable(this.editingTableId, payload).subscribe({
        next: () => {
          this.loadTables();
          this.closeFormModal();
        },
        error: (err) => {
          console.error('Failed to update table', err);
        }
      });
    } else {
      this.apiService.createTable(payload).subscribe({
        next: () => {
          this.loadTables();
          this.closeFormModal();
        },
        error: (err) => {
          console.error('Failed to create table', err);
        }
      });
    }
  }

  deleteTable(id: number) {
    if (confirm('Are you sure you want to delete this table? This will invalidate its QR code.')) {
      this.apiService.deleteTable(id).subscribe({
        next: () => {
          this.loadTables();
        },
        error: (err) => {
          console.error('Failed to delete table', err);
        }
      });
    }
  }

  releaseTable(id: number) {
    if (confirm('Are you sure you want to release this table? This will free the table and close any active booking session.')) {
      this.apiService.releaseTable(id).subscribe({
        next: () => {
          this.loadTables();
        },
        error: (err) => {
          console.error('Failed to release table', err);
        }
      });
    }
  }

  viewQrCode(table: Table) {
    this.selectedTableForQr = table;
    this.showQrModal = true;
  }

  closeQrModal() {
    this.showQrModal = false;
    this.selectedTableForQr = null;
  }

  printQrCode() {
    window.print();
  }
}
