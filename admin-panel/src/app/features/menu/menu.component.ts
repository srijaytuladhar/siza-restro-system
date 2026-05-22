import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatTooltipModule } from '@angular/material/tooltip';
import { ApiService, Category, MenuItem } from '../../core/api.service';

@Component({
  selector: 'app-menu',
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
    <div class="menu-creator-container">
      <div class="header">
        <div class="title-section">
          <h1 class="glow-text">Menu & Category Creator</h1>
          <p class="subtitle">Customize categories, dishes, prices, and prep times.</p>
        </div>
        <div class="header-actions">
          @if (activeTab === 'items') {
            <button mat-flat-button class="btn-premium" (click)="openItemModal()">
              <mat-icon>add</mat-icon> Add Menu Item
            </button>
          } @else {
            <button mat-flat-button class="btn-premium" (click)="openCategoryModal()">
              <mat-icon>add</mat-icon> Add Category
            </button>
          }
        </div>
      </div>

      <!-- Tab Switcher -->
      <div class="tab-switcher">
        <button class="tab-btn" [class.active]="activeTab === 'items'" (click)="activeTab = 'items'">
          <mat-icon>restaurant_menu</mat-icon> Menu Items ({{ menuItems.length }})
        </button>
        <button class="tab-btn" [class.active]="activeTab === 'categories'" (click)="activeTab = 'categories'">
          <mat-icon>category</mat-icon> Categories ({{ categories.length }})
        </button>
      </div>

      <!-- Tab Contents -->
      @if (isLoading) {
        <div class="loading-container">
          <p>Loading menu data...</p>
        </div>
      } @else {
        <!-- MENU ITEMS TAB -->
        @if (activeTab === 'items') {
          <div class="menu-items-grid">
            @for (item of menuItems; track item.id) {
              <div class="menu-item-card glass-card" [class.unavailable]="!item.isAvailable">
                <div class="item-image-area">
                  @if (item.imageUrl) {
                    <img [src]="item.imageUrl" alt="{{ item.name }}">
                  } @else {
                    <div class="image-fallback">
                      <mat-icon>restaurant</mat-icon>
                    </div>
                  }
                  <span class="category-badge">{{ item.categoryName || 'Unassigned' }}</span>
                </div>
                
                <div class="item-body">
                  <div class="item-title-row">
                    <h3>{{ item.name }}</h3>
                    <span class="price-tag">Rs. {{ item.price | number:'1.2-2' }}</span>
                  </div>
                  <p class="item-desc">{{ item.description || 'No description provided.' }}</p>
                  
                  <div class="item-stats">
                    <span class="stat-badge">
                      <mat-icon>schedule</mat-icon> {{ item.estimatedPrepTime }} mins
                    </span>
                    <span class="stat-badge availability" [class.active]="item.isAvailable" (click)="toggleAvailability(item)">
                      <mat-icon>{{ item.isAvailable ? 'check_circle' : 'remove_circle' }}</mat-icon>
                      {{ item.isAvailable ? 'Available' : 'Sold Out' }}
                    </span>
                  </div>
                </div>

                <div class="item-actions">
                  <button mat-stroked-button class="btn-icon" (click)="openItemModal(item)">
                    <mat-icon>edit</mat-icon> Edit
                  </button>
                  <button mat-stroked-button class="btn-icon delete" (click)="deleteMenuItem(item.id!)">
                    <mat-icon>delete</mat-icon> Delete
                  </button>
                </div>
              </div>
            }
          </div>
        }

        <!-- CATEGORIES TAB -->
        @if (activeTab === 'categories') {
          <div class="categories-list glass-card">
            <table class="premium-table">
              <thead>
                <tr>
                  <th>Category Name</th>
                  <th>Description</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                @if (categories.length === 0) {
                  <tr>
                    <td colspan="3" class="empty-table-row">No categories found. Click Add Category to create one.</td>
                  </tr>
                }
                @for (cat of categories; track cat.id) {
                  <tr>
                    <td class="cat-name-cell">
                      <strong>{{ cat.name }}</strong>
                    </td>
                    <td class="cat-desc-cell">{{ cat.description || '-' }}</td>
                    <td class="cat-actions-cell">
                      <button mat-icon-button color="accent" (click)="openCategoryModal(cat)" matTooltip="Edit Category">
                        <mat-icon>edit</mat-icon>
                      </button>
                      <button mat-icon-button color="warn" (click)="deleteCategory(cat.id!)" matTooltip="Delete Category">
                        <mat-icon>delete</mat-icon>
                      </button>
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      }

      <!-- Category Modal -->
      @if (showCategoryModal) {
        <div class="modal-overlay" (click)="closeCategoryModal()">
          <div class="modal-content glass-card" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <h2>{{ isEditCategory ? 'Edit Category' : 'Add Category' }}</h2>
              <button mat-icon-button (click)="closeCategoryModal()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
            <form (ngSubmit)="saveCategory()" class="modal-form">
              <div class="form-group">
                <label for="catName">Category Name</label>
                <input type="text" id="catName" name="catName" [(ngModel)]="catFormName" required placeholder="e.g. Burgers, Beverages">
              </div>
              <div class="form-group">
                <label for="catDesc">Description</label>
                <input type="text" id="catDesc" name="catDesc" [(ngModel)]="catFormDesc" placeholder="e.g. Grilled premium patties and soft buns">
              </div>
              <div class="form-actions">
                <button type="button" mat-stroked-button (click)="closeCategoryModal()">Cancel</button>
                <button type="submit" mat-flat-button class="btn-premium">
                  {{ isEditCategory ? 'Save Changes' : 'Add Category' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      }

      <!-- Menu Item Modal -->
      @if (showItemModal) {
        <div class="modal-overlay" (click)="closeItemModal()">
          <div class="modal-content glass-card item-modal" (click)="$event.stopPropagation()">
            <div class="modal-header">
              <h2>{{ isEditItem ? 'Edit Menu Item' : 'Add Menu Item' }}</h2>
              <button mat-icon-button (click)="closeItemModal()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
            <form (ngSubmit)="saveMenuItem()" class="modal-form">
              <div class="form-row-two">
                <div class="form-group">
                  <label for="itemName">Item Name</label>
                  <input type="text" id="itemName" name="itemName" [(ngModel)]="itemFormName" required placeholder="e.g. Chicken Crunch Burger">
                </div>
                <div class="form-group">
                  <label for="itemCategory">Category</label>
                  <select id="itemCategory" name="itemCategory" [(ngModel)]="itemFormCategoryId" required class="premium-select">
                    <option [value]="0" disabled selected>Select Category</option>
                    @for (cat of categories; track cat.id) {
                      <option [value]="cat.id">{{ cat.name }}</option>
                    }
                  </select>
                </div>
              </div>

              <div class="form-row-two">
                <div class="form-group">
                  <label for="itemPrice">Price (Rs.)</label>
                  <input type="number" id="itemPrice" name="itemPrice" [(ngModel)]="itemFormPrice" required min="0">
                </div>
                <div class="form-group">
                  <label for="itemPrep">Estimated Prep Time (mins)</label>
                  <input type="number" id="itemPrep" name="itemPrep" [(ngModel)]="itemFormPrep" required min="1">
                </div>
              </div>

              <div class="form-group">
                <label for="itemDesc">Description</label>
                <input type="text" id="itemDesc" name="itemDesc" [(ngModel)]="itemFormDesc" placeholder="Brief description of flavors/allergens">
              </div>

              <div class="form-group image-upload-group">
                <label>Item Image</label>
                <div class="upload-controls">
                  <input type="file" id="fileUpload" (change)="onFileSelected($event)" accept="image/*" class="hidden-file-input">
                  <label for="fileUpload" class="file-label-btn">
                    <mat-icon>cloud_upload</mat-icon> Upload Image File
                  </label>
                  <span class="upload-tip">Or enter image URL below:</span>
                  <input type="text" name="itemImageUrl" [(ngModel)]="itemFormImageUrl" placeholder="https://example.com/image.jpg" class="url-input">
                </div>
                
                @if (itemFormImageUrl) {
                  <div class="image-preview">
                    <img [src]="itemFormImageUrl" alt="Item Preview">
                    <button type="button" class="btn-remove-preview" (click)="itemFormImageUrl = ''">
                      <mat-icon>close</mat-icon>
                    </button>
                  </div>
                }
              </div>

              <div class="form-group checkbox-group">
                <label class="toggle-switch">
                  <input type="checkbox" name="itemAvailable" [(ngModel)]="itemFormAvailable">
                  <span class="slider"></span>
                </label>
                <span class="checkbox-label">Available for ordering</span>
              </div>

              <div class="form-actions">
                <button type="button" mat-stroked-button (click)="closeItemModal()">Cancel</button>
                <button type="submit" mat-flat-button class="btn-premium">
                  {{ isEditItem ? 'Save Changes' : 'Create Item' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .menu-creator-container {
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
    .tab-switcher {
      display: flex;
      gap: 12px;
      border-bottom: 1px solid var(--glass-border);
      padding-bottom: 8px;
    }
    .tab-btn {
      background: transparent;
      border: none;
      color: var(--color-text-secondary);
      font-family: var(--font-family);
      font-size: 15px;
      font-weight: 600;
      padding: 10px 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      border-radius: 8px;
      transition: all 0.3s ease;
    }
    .tab-btn:hover {
      color: var(--color-text-primary);
      background: rgba(255, 255, 255, 0.03);
    }
    .tab-btn.active {
      color: var(--primary);
      background: rgba(157, 78, 221, 0.1);
      box-shadow: inset 0 -2px 0 var(--primary);
    }
    .loading-container {
      padding: 60px 0;
      text-align: center;
      color: var(--color-text-secondary);
    }

    /* Menu Items Grid */
    .menu-items-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 20px;
    }
    .menu-item-card {
      background: rgba(255, 255, 255, 0.02) !important;
      border-radius: 16px;
      border: 1px solid var(--glass-border);
      overflow: hidden;
      display: flex;
      flex-direction: column;
      transition: all 0.3s ease;
    }
    .menu-item-card:hover {
      background: rgba(255, 255, 255, 0.05) !important;
      transform: translateY(-4px);
    }
    .menu-item-card.unavailable {
      opacity: 0.6;
    }
    .item-image-area {
      height: 180px;
      position: relative;
      background: #100a26;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .item-image-area img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .image-fallback {
      display: flex;
      flex-direction: column;
      align-items: center;
      color: var(--color-text-muted);
    }
    .image-fallback mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }
    .category-badge {
      position: absolute;
      top: 12px;
      left: 12px;
      background: rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(4px);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      color: var(--accent);
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .item-body {
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      flex-grow: 1;
    }
    .item-title-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 8px;
    }
    .item-title-row h3 {
      font-size: 16px;
      font-weight: 700;
      color: var(--color-text-primary);
    }
    .price-tag {
      font-size: 15px;
      font-weight: 700;
      color: var(--color-success);
    }
    .item-desc {
      font-size: 12px;
      color: var(--color-text-secondary);
      line-height: 1.5;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
      height: 36px;
    }
    .item-stats {
      display: flex;
      gap: 12px;
      margin-top: 8px;
    }
    .stat-badge {
      font-size: 11px;
      display: flex;
      align-items: center;
      gap: 4px;
      color: var(--color-text-muted);
      background: rgba(255, 255, 255, 0.04);
      padding: 4px 8px;
      border-radius: 6px;
    }
    .stat-badge mat-icon {
      font-size: 13px;
      width: 13px;
      height: 13px;
    }
    .stat-badge.availability {
      cursor: pointer;
      font-weight: 600;
      background: rgba(239, 71, 111, 0.1);
      color: var(--color-danger);
      transition: all 0.3s ease;
    }
    .stat-badge.availability.active {
      background: rgba(6, 214, 160, 0.1);
      color: var(--color-success);
    }
    .item-actions {
      display: flex;
      border-top: 1px solid var(--glass-border);
      padding: 12px;
      gap: 8px;
    }
    .btn-icon {
      flex: 1;
      height: 34px !important;
      line-height: 34px !important;
      border-radius: 6px !important;
      font-size: 12px !important;
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

    /* Categories Table Styles */
    .categories-list {
      padding: 0 !important;
      overflow: hidden;
      border-radius: 16px;
    }
    .premium-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    .premium-table th {
      background: rgba(0, 0, 0, 0.2);
      padding: 16px 24px;
      color: var(--color-text-secondary);
      font-weight: 600;
      font-size: 14px;
      border-bottom: 1px solid var(--glass-border);
    }
    .premium-table td {
      padding: 16px 24px;
      border-bottom: 1px solid var(--glass-border);
      color: var(--color-text-primary);
      font-size: 14px;
    }
    .cat-name-cell {
      color: var(--primary) !important;
    }
    .cat-desc-cell {
      color: var(--color-text-secondary);
    }
    .cat-actions-cell {
      display: flex;
      gap: 8px;
    }
    .empty-table-row {
      text-align: center;
      color: var(--color-text-muted);
      padding: 40px !important;
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
    .modal-content.item-modal {
      max-width: 600px;
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
    .form-row-two {
      display: grid;
      grid-template-columns: 1fr 1fr;
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
    .form-group input, .premium-select {
      background: rgba(0, 0, 0, 0.2);
      border: 1px solid var(--glass-border);
      border-radius: 8px;
      padding: 12px;
      color: var(--color-text-primary);
      font-family: var(--font-family);
      font-size: 14px;
      outline: none;
      transition: border-color 0.3s ease;
    }
    .premium-select option {
      background-color: var(--bg-secondary);
      color: var(--color-text-primary);
    }
    .form-group input:focus, .premium-select:focus {
      border-color: var(--primary);
    }

    /* Image Upload Fields */
    .image-upload-group {
      border: 1px dashed var(--glass-border);
      border-radius: 8px;
      padding: 16px;
      background: rgba(0, 0, 0, 0.15);
    }
    .upload-controls {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .hidden-file-input {
      display: none;
    }
    .file-label-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--glass-border);
      border-radius: 8px;
      padding: 10px 16px;
      color: var(--color-text-primary);
      cursor: pointer;
      font-weight: 500;
      transition: background-color 0.3s ease;
    }
    .file-label-btn:hover {
      background: rgba(255, 255, 255, 0.1);
    }
    .upload-tip {
      font-size: 12px;
      color: var(--color-text-muted);
    }
    .url-input {
      padding: 10px !important;
    }
    .image-preview {
      margin-top: 12px;
      height: 120px;
      width: 120px;
      border-radius: 8px;
      overflow: hidden;
      position: relative;
      border: 1px solid var(--glass-border);
    }
    .image-preview img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .btn-remove-preview {
      position: absolute;
      top: 4px;
      right: 4px;
      background: rgba(0, 0, 0, 0.7);
      border: none;
      color: white;
      border-radius: 50%;
      width: 24px;
      height: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
    }

    /* Toggle Switch Styles */
    .checkbox-group {
      display: flex;
      flex-direction: row;
      align-items: center;
      gap: 12px;
    }
    .checkbox-label {
      font-size: 14px;
      color: var(--color-text-secondary);
      font-weight: 500;
    }
    .toggle-switch {
      position: relative;
      display: inline-block;
      width: 48px;
      height: 24px;
    }
    .toggle-switch input {
      opacity: 0;
      width: 0;
      height: 0;
    }
    .slider {
      position: absolute;
      cursor: pointer;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(255, 255, 255, 0.15);
      transition: .4s;
      border-radius: 24px;
      border: 1px solid var(--glass-border);
    }
    .slider:before {
      position: absolute;
      content: "";
      height: 18px;
      width: 18px;
      left: 2px;
      bottom: 2px;
      background-color: white;
      transition: .4s;
      border-radius: 50%;
    }
    input:checked + .slider {
      background-color: var(--primary);
    }
    input:focus + .slider {
      box-shadow: 0 0 1px var(--primary);
    }
    input:checked + .slider:before {
      transform: translateX(24px);
    }

    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      margin-top: 10px;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    @keyframes slideUp {
      from { transform: translateY(20px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }
  `]
})
export class MenuComponent implements OnInit {
  private apiService = inject(ApiService);

  categories: Category[] = [];
  menuItems: MenuItem[] = [];
  isLoading = true;
  activeTab: 'items' | 'categories' = 'items';

  // Category Form handling
  showCategoryModal = false;
  isEditCategory = false;
  editingCategoryId: number | null = null;
  catFormName = '';
  catFormDesc = '';

  // Menu Item Form handling
  showItemModal = false;
  isEditItem = false;
  editingItemId: number | null = null;
  itemFormName = '';
  itemFormCategoryId = 0;
  itemFormPrice = 0;
  itemFormPrep = 15;
  itemFormDesc = '';
  itemFormImageUrl = '';
  itemFormAvailable = true;

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.isLoading = true;
    this.apiService.getCategories().subscribe({
      next: (cats) => {
        this.categories = cats;
        this.apiService.getMenuItems().subscribe({
          next: (items) => {
            this.menuItems = items;
            this.isLoading = false;
          },
          error: (err) => {
            console.error('Failed to load menu items', err);
            this.isLoading = false;
          }
        });
      },
      error: (err) => {
        console.error('Failed to load categories', err);
        this.isLoading = false;
      }
    });
  }

  // --- Category Actions ---
  openCategoryModal(cat?: Category) {
    if (cat) {
      this.isEditCategory = true;
      this.editingCategoryId = cat.id!;
      this.catFormName = cat.name;
      this.catFormDesc = cat.description || '';
    } else {
      this.isEditCategory = false;
      this.editingCategoryId = null;
      this.catFormName = '';
      this.catFormDesc = '';
    }
    this.showCategoryModal = true;
  }

  closeCategoryModal() {
    this.showCategoryModal = false;
  }

  saveCategory() {
    if (!this.catFormName.trim()) return;
    
    const payload = {
      name: this.catFormName.trim(),
      description: this.catFormDesc.trim()
    };

    if (this.isEditCategory && this.editingCategoryId !== null) {
      this.apiService.updateCategory(this.editingCategoryId, payload).subscribe({
        next: () => {
          this.loadData();
          this.closeCategoryModal();
        },
        error: (err) => console.error('Failed to update category', err)
      });
    } else {
      this.apiService.createCategory(payload).subscribe({
        next: () => {
          this.loadData();
          this.closeCategoryModal();
        },
        error: (err) => console.error('Failed to create category', err)
      });
    }
  }

  deleteCategory(id: number) {
    if (confirm('Are you sure you want to delete this category? All associated items may lose their category link.')) {
      this.apiService.deleteCategory(id).subscribe({
        next: () => this.loadData(),
        error: (err) => console.error('Failed to delete category', err)
      });
    }
  }

  // --- Menu Item Actions ---
  openItemModal(item?: MenuItem) {
    if (item) {
      this.isEditItem = true;
      this.editingItemId = item.id!;
      this.itemFormName = item.name;
      this.itemFormCategoryId = item.categoryId;
      this.itemFormPrice = item.price;
      this.itemFormPrep = item.estimatedPrepTime;
      this.itemFormDesc = item.description || '';
      this.itemFormImageUrl = item.imageUrl || '';
      this.itemFormAvailable = item.isAvailable;
    } else {
      this.isEditItem = false;
      this.editingItemId = null;
      this.itemFormName = '';
      this.itemFormCategoryId = this.categories.length > 0 ? this.categories[0].id! : 0;
      this.itemFormPrice = 0;
      this.itemFormPrep = 15;
      this.itemFormDesc = '';
      this.itemFormImageUrl = '';
      this.itemFormAvailable = true;
    }
    this.showItemModal = true;
  }

  closeItemModal() {
    this.showItemModal = false;
  }

  saveMenuItem() {
    if (!this.itemFormName.trim() || this.itemFormCategoryId === 0 || this.itemFormPrice < 0) return;

    const payload = {
      name: this.itemFormName.trim(),
      description: this.itemFormDesc.trim(),
      price: this.itemFormPrice,
      categoryId: this.itemFormCategoryId,
      estimatedPrepTime: this.itemFormPrep,
      imageUrl: this.itemFormImageUrl.trim(),
      isAvailable: this.itemFormAvailable
    };

    if (this.isEditItem && this.editingItemId !== null) {
      this.apiService.updateMenuItem(this.editingItemId, payload).subscribe({
        next: () => {
          this.loadData();
          this.closeItemModal();
        },
        error: (err) => console.error('Failed to update menu item', err)
      });
    } else {
      this.apiService.createMenuItem(payload).subscribe({
        next: () => {
          this.loadData();
          this.closeItemModal();
        },
        error: (err) => console.error('Failed to create menu item', err)
      });
    }
  }

  deleteMenuItem(id: number) {
    if (confirm('Are you sure you want to delete this menu item?')) {
      this.apiService.deleteMenuItem(id).subscribe({
        next: () => this.loadData(),
        error: (err) => console.error('Failed to delete menu item', err)
      });
    }
  }

  toggleAvailability(item: MenuItem) {
    const updated = {
      ...item,
      isAvailable: !item.isAvailable
    };
    this.apiService.updateMenuItem(item.id!, updated).subscribe({
      next: () => this.loadData(),
      error: (err) => console.error('Failed to toggle availability', err)
    });
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.itemFormImageUrl = e.target.result; // Base64 data URL
      };
      reader.readAsDataURL(file);
    }
  }
}
