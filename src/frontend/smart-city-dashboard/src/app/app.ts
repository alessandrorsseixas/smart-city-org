import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet,
    MatToolbarModule,
    MatIconModule,
    MatButtonModule,
    MatCardModule,
    MatSlideToggleModule
  ],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  title = 'Smart City Dashboard';

  houseLights = {
    livingRoom: true
  };

  houseDevices = {
    ac: false,
    security: true
  };

  energyData = {
    solar: 45.2,
    wind: 23.8,
    battery: 87
  };

  carStatus = {
    location: 'Main Street & 5th Ave',
    battery: 76,
    status: 'Autonomous Mode'
  };

  systemStatus = {
    auth: true,
    house: true,
    energy: true,
    car: false
  };

  toggleDevice(device: string, location: string, isOn: boolean) {
    console.log(`Toggling ${device} in ${location} to ${isOn ? 'ON' : 'OFF'}`);
    // Here you would call the actual API to control the device
  }

  controlCar() {
    console.log('Sending car to charging station...');
    // Here you would call the car control API
  }
}
