import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Category {
  id?: number;
  name: string;
  description?: string;
  createdAt?: string;
}

export interface MenuItem {
  id?: number;
  name: string;
  description?: string;
  price: number;
  categoryId: number;
  categoryName?: string;
  isAvailable: boolean;
  imageUrl?: string;
  estimatedPrepTime: number;
}

export interface Table {
  id?: number;
  tableNumber: string;
  capacity: number;
  qrCodeToken?: string;
  status: 'AVAILABLE' | 'RESERVED' | 'OCCUPIED' | 'BOOKED';
  qrCodeBase64?: string;
}

export interface OrderItem {
  id: number;
  menuItemId: number;
  menuItemName: string;
  price: number;
  quantity: number;
}

export interface Order {
  id: number;
  bookingId: number;
  tableNumber: string;
  status: 'WAITING' | 'ACCEPTED' | 'PREPARING' | 'READY' | 'SERVED' | 'CANCELLED';
  totalAmount: number;
  createdAt: string;
  items: OrderItem[];
  specialInstructions?: string;
  paymentStatus: string;
  paymentMethod?: string;
}

export interface PopularItem {
  name: string;
  orderCount: number;
}

export interface DailySales {
  date: string;
  revenue: number;
}

export interface DashboardStats {
  totalRevenue: number;
  activeTablesCount: number;
  totalOrdersCount: number;
  popularItems: PopularItem[];
  weeklySales: DailySales[];
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private baseUrl = 'http://localhost:8080/api';

  constructor(private http: HttpClient) { }

  // Categories API
  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.baseUrl}/category`);
  }

  createCategory(category: Category): Observable<Category> {
    return this.http.post<Category>(`${this.baseUrl}/category`, category);
  }

  updateCategory(id: number, category: Category): Observable<Category> {
    return this.http.put<Category>(`${this.baseUrl}/category/${id}`, category);
  }

  deleteCategory(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/category/${id}`);
  }

  // Menu Items API
  getMenuItems(): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/menu/all`);
  }

  getAvailableMenuItems(): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/menu`);
  }

  createMenuItem(item: MenuItem): Observable<MenuItem> {
    return this.http.post<MenuItem>(`${this.baseUrl}/menu`, item);
  }

  updateMenuItem(id: number, item: MenuItem): Observable<MenuItem> {
    return this.http.put<MenuItem>(`${this.baseUrl}/menu/${id}`, item);
  }

  deleteMenuItem(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/menu/${id}`);
  }

  // Tables API
  getTables(): Observable<Table[]> {
    return this.http.get<Table[]>(`${this.baseUrl}/table`);
  }

  createTable(table: { tableNumber: string; capacity: number }): Observable<Table> {
    return this.http.post<Table>(`${this.baseUrl}/table`, table);
  }

  updateTable(id: number, table: { tableNumber: string; capacity: number }): Observable<Table> {
    return this.http.put<Table>(`${this.baseUrl}/table/${id}`, table);
  }

  deleteTable(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/table/${id}`);
  }

  releaseTable(id: number): Observable<Table> {
    return this.http.put<Table>(`${this.baseUrl}/table/${id}/release`, {});
  }

  // Orders API
  getOrders(): Observable<Order[]> {
    // Get all orders from orders queue or dashboard endpoint.
    // For standard kitchen orders, we can fetch all orders by polling or we'll get updates via web socket.
    // Let's create an endpoint to fetch active orders if needed.
    // Note: since order controller doesn't have a get-all endpoint, we can query orders or write a custom endpoint.
    // Wait, let's look at OrderController: it has placeOrder, getOrder, and getOrdersByBooking.
    // To see ALL kitchen orders in the admin panel, did we add a get-all orders endpoint?
    // Wait, let's check OrderController again. No, it only has getOrdersByBooking.
    // Let's see: does the kitchen admin panel need to retrieve all active/pending orders? Yes, it does!
    // Let's add a `GET /api/order` endpoint to OrderController, which returns all orders. This is a very common requirement.
    // Let's implement that in OrderController and OrderService first to support fetching orders for the Kanban board!
    return this.http.get<Order[]>(`${this.baseUrl}/order`);
  }

  updateOrderStatus(orderId: number, status: string): Observable<Order> {
    return this.http.put<Order>(`${this.baseUrl}/order/${orderId}/status`, { status });
  }

  // Dashboard API
  getDashboardStats(): Observable<DashboardStats> {
    return this.http.get<DashboardStats>(`${this.baseUrl}/admin/dashboard`);
  }
}
