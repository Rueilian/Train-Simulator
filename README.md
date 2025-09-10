Digital Circuits Lab Final Project: Train Simulator
Real-Time Video Streaming with Joystick Control

## Project Overview

This project implements a comprehensive FPGA-based video streaming system using the Altera DE2-115 development board. The system features real-time video transmission over Ethernet, joystick-based speed control, distance measurement, and VGA display with overlay information.

## Key Features

- **Real-time Video Streaming**: UDP-based video transmission from Python client to FPGA
- **Joystick Control**: ADS1115 ADC-based analog joystick input for speed and direction control
- **Distance Measurement**: Real-time distance calculation and display
- **VGA Display**: 640x480 resolution with speed, distance, and timer overlays
- **Ethernet Communication**: Bidirectional UDP communication for video and control data
- **SDRAM Frame Buffer**: Efficient video frame storage and retrieval

## Hardware Requirements

- Altera DE2-115 Development Board
- ADS1115 ADC Module (for joystick input)
- Ethernet connection
- VGA monitor
- Joystick/analog controller

## Project Structure

```
src/
├── ADS/                    # ADC controller for joystick input
│   └── ads1115_controller.sv
├── DE2-115/               # Main FPGA top-level module
│   ├── DE2_115.sv         # Main system integration
│   ├── Debounce.sv        # Input debouncing
│   └── hex_display.v      # 7-segment display driver
├── Ethernet/              # Ethernet communication modules
│   ├── UDP_parser.sv      # UDP packet parsing
│   ├── Ethernet.v         # Main Ethernet controller
│   └── [various ethernet modules]
├── Sdram/                 # SDRAM controller and frame buffer
│   ├── Sdram_Control.v    # Main SDRAM controller
│   └── [SDRAM support files]
├── SpeedCtrl/             # Speed control logic
│   └── SpeedCtrl.sv       # Joystick to speed conversion
├── VGA/                   # VGA display and overlay modules
│   ├── VGA_Controller.v   # Main VGA controller
│   ├── Speed_display.v    # Speed overlay display
│   ├── Distance_display.v # Distance overlay display
│   └── [other display modules]
└── python/                # Python client application
    └── send_video.py      # Video streaming client
```

## System Architecture

### FPGA Side (DE2-115)
1. **Main Controller** (`DE2_115.sv`): Integrates all subsystems
2. **ADC Interface**: Reads joystick position via I2C from ADS1115
3. **Speed Control**: Converts joystick input to speed/direction commands
4. **Ethernet Module**: Handles UDP communication for video and control data
5. **SDRAM Frame Buffer**: Stores incoming video frames
6. **VGA Controller**: Displays video with real-time overlays

### Python Client Side
- **Video Streaming**: Sends video frames via UDP to FPGA
- **Control Feedback**: Receives speed control commands from FPGA
- **Distance Calculation**: Computes distance based on video speed data

## Key Components

### 1. Video Streaming Pipeline
- Python client captures/processes video frames
- Frames sent as UDP packets (1452 bytes each)
- FPGA receives and stores frames in SDRAM
- VGA controller reads from SDRAM for display

### 2. Joystick Control System
- ADS1115 ADC reads analog joystick position
- SpeedCtrl module converts position to speed (0-8191 range)
- Direction control: forward, backward, stop
- Real-time speed adjustment based on joystick input

### 3. Display System
- **Video Display**: 640x480 resolution with frame buffer
- **Speed Overlay**: Real-time speed display (0-999 range)
- **Distance Overlay**: Calculated distance in centimeters
- **Timer Display**: Countdown timer based on distance

### 4. Communication Protocol
- **Video Data**: RGB pixel data sent as UDP packets
- **Control Data**: Speed/direction feedback from FPGA
- **Distance Data**: 6-digit distance value transmission

## Usage Instructions

### 1. Hardware Setup
1. Connect ADS1115 to GPIO pins (SDA: GPIO[1], SCL: GPIO[0])
2. Connect Ethernet cable to DE2-115
3. Connect VGA monitor
4. Connect joystick to ADS1115 analog inputs

### 2. Software Setup
1. Program FPGA with the compiled design
2. Configure network settings in `send_video.py`:
   ```python
   HOST, PORT = "192.168.50.8", 1234  # FPGA IP address
   ```
3. Prepare video data and labels:
   - Place video frames in `../data/Yosan/` directory
   - Ensure frame naming: `Yosan_000001.png`, `Yosan_000002.png`, etc.
   - Provide speed labels in `../data/Yosan.txt`

### 3. Running the System
1. Start the Python client:
   ```bash
   python send_video.py
   ```
2. Use joystick to control video playback speed and direction
3. Monitor real-time speed, distance, and timer on VGA display

## Technical Specifications

- **FPGA**: Altera Cyclone IV E (DE2-115)
- **Video Resolution**: 640x480 @ 30 FPS
- **Ethernet**: 1000BASE-T RGMII
- **ADC Resolution**: 16-bit (ADS1115)
- **SDRAM**: 32-bit data bus, dual-port access
- **VGA**: 25MHz pixel clock, 640x480@60Hz

## Control Interface

### Joystick Mapping
- **Left Stick (Channel 0)**: Direction control
  - Values > 0x36: Forward
  - Values < 0x32: Backward
  - Values 0x32-0x36: Stop
- **Right Stick (Channel 1)**: Speed control
  - Higher values: Increase speed
  - Lower values: Decrease speed

### Display Information
- **Speed**: 3-digit display (0-999)
- **Distance**: 6-digit display in centimeters
- **Timer**: Countdown based on distance calculation
- **Direction**: Visual indication of movement direction

## Development Tools

- **FPGA Development**: Quartus Prime (Altera/Intel)
- **Simulation**: ModelSim (if needed)
- **Python**: OpenCV for video processing
- **Network**: UDP socket programming

## File Descriptions

- `DE2_115.sv`: Main system integration and top-level module
- `ads1115_controller.sv`: I2C communication with ADS1115 ADC
- `SpeedCtrl.sv`: Joystick position to speed conversion logic
- `UDP_parser.sv`: Parses incoming UDP video packets
- `VGA_Controller.v`: VGA timing and overlay display
- `Sdram_Control.v`: SDRAM frame buffer management
- `send_video.py`: Python client for video streaming

## Troubleshooting

1. **No Video Display**: Check Ethernet connection and IP configuration
2. **Joystick Not Responding**: Verify ADS1115 I2C connections
3. **Poor Video Quality**: Check network bandwidth and packet size
4. **Display Artifacts**: Verify SDRAM timing and frame buffer addressing

## Team Information

This project was developed by Team 09 as a final project, demonstrating advanced FPGA design, real-time video processing, and embedded system integration.

## License

This project is for educational purposes. Please refer to individual module headers for specific licensing information, particularly for Terasic Technologies components.


