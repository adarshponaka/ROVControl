import processing.serial.*;
import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;
import cc.arduino.*;
import org.firmata.*;
import java.awt.datatransfer.*;
import java.awt.Toolkit;
import processing.opengl.*;
import saito.objloader.*;
import g4p_controls.*;

//Controllor
ControlDevice cont;
ControlIO control;
ControlButton buttonA;

//Main Arduino
Arduino arduino;

//Thruster
float leftPower, rightPower;
int FRpos = 5, FLpos = 4;
int FLservopos = 8;

//IMU info
float roll  = 0.0F;
float pitch = 0.0F;
float yaw   = 0.0F;
float temp  = 0.0F;
float alt   = 0.0F;

//3D Rendering
OBJModel model;

// Serial port state
Serial       port;
String       buffer = "";
final String serialConfigFile = "serialconfig.txt";




void setup() {
  size(400, 550, OPENGL);
  
  model = new OBJModel(this);
  model.load("rovPrototype4.obj");
  model.scale(10);
 
  // Set serial port.
  setSerialPort("COM5");
  
  control = ControlIO.getInstance(this);
  cont = control.getMatchedDevice("rovcontrolinfo");
  buttonA = cont.getButton("90mode");
  
  if (cont == null) {
    println("not today chump"); // write better exit statements than me
    System.exit(-1);
  }
  //println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[1], 57600);
  arduino.pinMode(FLpos, Arduino.SERVO);
  arduino.pinMode(FRpos, Arduino.SERVO);
  arduino.pinMode(FLservopos, Arduino.SERVO);
  arduino.servoWrite(FLpos,1500);
  arduino.servoWrite(FRpos,1500);
  arduino.servoWrite(FLservopos,0);

  printArray(Serial.list());
  
  delay(7000);

}

public void getUserInput() {
  leftPower = map(cont.getSlider("thrusterFL").getValue(), -1, 1, 1260, 1740);
  rightPower = map(cont.getSlider("thrusterFR").getValue(), -1, 1, 1740, 1260);
  
}

void draw() {
  getUserInput();
  background(0,0,0);


  // Set a new co-ordinate space
  pushMatrix();

  // Simple 3 point lighting for dramatic effect.
  // Slightly red light in upper right, slightly blue light in upper left, and white light from behind.
  pointLight(255, 200, 200,  400, 400,  500);
  pointLight(200, 200, 255, -400, 400,  500);
  pointLight(255, 255, 255,    0,   0, -500);
  
  // Displace objects from 0,0
  translate(200, 300, 0);
  
  // Rotate shapes around the X/Y/Z axis (values in radians, 0..Pi*2)
  rotateZ(radians(roll));
  rotateX(radians(pitch));
  rotateY(radians(yaw));

  pushMatrix();
  noStroke();
  model.draw();
  popMatrix();
  popMatrix();
  
  
  
  arduino.servoWrite(FLpos,(int)leftPower);
  arduino.servoWrite(FRpos,(int)rightPower);
  
  if(buttonA.pressed()){
      arduino.servoWrite(FLservopos,90);
  }else{
      arduino.servoWrite(FLservopos,0);
  }

}


void serialEvent(Serial p) 
{
  String incoming = p.readString();
  
  if ((incoming.length() > 8))
  {
    String[] list = split(incoming, " ");
    if ( (list.length > 0) && (list[0].equals("Orientation:")) ) 
    {
      roll  = float(list[3]); // Roll = Z
      pitch = float(list[2]); // Pitch = Y 
      yaw   = float(list[1]); // Yaw/Heading = X
      buffer = incoming;
    }
    if ( (list.length > 0) && (list[0].equals("Alt:")) ) 
    {
      alt  = float(list[1]);
      buffer = incoming;
    }
    if ( (list.length > 0) && (list[0].equals("Temp:")) ) 
    {
      temp  = float(list[1]);
      buffer = incoming;
    }
  }
}


// Set serial port to desired value.
void setSerialPort(String portName) {
  // Close the port if it's currently open.
  if (port != null) {
    port.stop();
  }
  try {
    // Open port.
    port = new Serial(this, portName, 115200);
    port.bufferUntil('\n');
    // Persist port in configuration.
    saveStrings(serialConfigFile, new String[] { portName });
  }
  catch (RuntimeException ex) {
    // Swallow error if port can't be opened, keep port closed.
    port = null; 
  }
}
