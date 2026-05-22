import { Injectable } from '@angular/core';
import { Subject, Observable } from 'rxjs';
import SockJS from 'sockjs-client';
import * as Stomp from 'stompjs/lib/stomp';

@Injectable({
  providedIn: 'root'
})
export class WebsocketService {
  private stompClient: Stomp.Client | null = null;
  private messageSubject = new Subject<any>();

  constructor() {
    this.connect();
  }

  private connect() {
    const socket = new SockJS('http://localhost:8080/ws');
    this.stompClient = Stomp.over(socket);
    
    // Silence debug logs in production/runtime console
    this.stompClient.debug = () => {};

    this.stompClient.connect({}, 
      (frame) => {
        console.log('STOMP Connection Established: ', frame);
        
        // Subscribe to orders topic
        this.stompClient?.subscribe('/topic/orders', (message) => {
          if (message.body) {
            try {
              const data = JSON.parse(message.body);
              this.messageSubject.next(data);
            } catch (e) {
              console.error('Error parsing WebSocket message body', e);
            }
          }
        });
      }, 
      (error) => {
        console.error('STOMP Connection Error, retrying in 5 seconds...', error);
        setTimeout(() => this.connect(), 5000);
      }
    );
  }

  onOrderUpdate(): Observable<any> {
    return this.messageSubject.asObservable();
  }
}
