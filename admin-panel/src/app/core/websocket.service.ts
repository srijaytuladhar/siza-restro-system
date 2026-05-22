import { Injectable } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import SockJS from 'sockjs-client';
import * as StompModule from 'stompjs/lib/stomp';

const Stomp = (StompModule as any).Stomp || StompModule;

@Injectable({
  providedIn: 'root'
})
export class WebsocketService {
  private stompClient: any = null;
  private messageSubject = new Subject<any>();
  private tablesSubject = new Subject<any>();

  constructor() {
    this.connect();
  }

  private connect() {
    const socket = new SockJS('http://localhost:8080/ws');
    this.stompClient = Stomp.over(socket);
    
    // Silence debug logs in production/runtime console
    this.stompClient.debug = () => {};

    this.stompClient.connect({}, 
      (frame: any) => {
        console.log('STOMP Connection Established: ', frame);
        
        // Subscribe to orders topic
        this.stompClient?.subscribe('/topic/orders', (message: any) => {
          if (message.body) {
            try {
              const data = JSON.parse(message.body);
              this.messageSubject.next(data);
            } catch (e) {
              console.error('Error parsing WebSocket message body', e);
            }
          }
        });

        // Subscribe to tables topic
        this.stompClient?.subscribe('/topic/tables', (message: any) => {
          if (message.body) {
            try {
              const data = JSON.parse(message.body);
              this.tablesSubject.next(data);
            } catch (e) {
              console.error('Error parsing WebSocket message body', e);
            }
          }
        });
      }, 
      (error: any) => {
        console.error('STOMP Connection Error, retrying in 5 seconds...', error);
        setTimeout(() => this.connect(), 5000);
      }
    );
  }

  onOrderUpdate(): Observable<any> {
    return this.messageSubject.asObservable();
  }

  onTableUpdate(): Observable<any> {
    return this.tablesSubject.asObservable();
  }
}
