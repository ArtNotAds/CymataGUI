/*
 
 HemeshGuiLight v0.2
 by Amnon Owed (http://amnonp5.wordpress.com)
 
 v0.2 changes:
 * Adapted HemeshGui to run under the latest Processing version (1.5.1)
 * Adapted HemeshGui to run under the latest Hemesh version (Beta 1.4.9)
 
 Requires:
 - Hemesh Beta 1.4.9 by Frederik Vanhoutte
 - controlP5 0.5.4 by Andreas Schlegel
 
 Installation instructions:
 http://code.google.com/p/amnonp5

*/

import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

import processing.opengl.*;

Minim minim; 
AudioPlayer player;
AudioInput in;
AudioSample kick;
FFT fft;    

float[][] values=new float[1024][1024];

// general settings
int sceneWidth = 1280;                 // sketch width
int sceneHeight = 720;                 // sketch height

// view
float zoom = 20;                       // zoom factor
float actualZoom = 20;                 // zoom smoothing
boolean autoRotate = true;             // toggle autorotation
boolean translation;                   // toggle translation
boolean rotation;                      // toggle rotation
float translateX, translateXchange;    // (change in) translation in the X-direction
float translateY, translateYchange;    // (change in) translation in the Y-direction
float rotationX, rotationXchange;      // (change in) rotation around the X-axis
float rotationY, rotationYchange;      // (change in) rotation around the Y-axis
float changeSpeedX = 1.5;              // speed of changes for X in translation and rotation
float changeSpeedY = 1.5;              // speed of changes for Y in translation and rotation

// presentation
color bgcolor = color(230,230,230);    // background color
color shapecolor;                      // shape color
boolean facesOn = true;                // toggle display of faces
boolean edgesOn = true;                // toggle display of edges
float shapeHue = 57;                   // default hue
float shapeSaturation = 100;           // default saturation
float shapeBrightness = 96;            // default brightness
float shapeTransparency = 100;         // default transparency

// basic shape variables
int creator = 2;                       // default shape: Dodecahedron
float create0 = 4;                     // default shape value
float create1 = 4;                     // default shape value
float create2 = 4;                     // default shape value
float create3 = 4;                     // default shape value

// saving variables
boolean saveOn;                        // toggle saving: globally
boolean saveContinuous;                // toggle saving: continuous (versus just once)
boolean saveNormal;                    // toggle saving: regular opengl (without gui)
boolean saveGui;                       // toggle saving: regular opengl (with gui)
String timestamp;                      // timestamp to distinguish saves

// assorted
ArrayList modifiers = new ArrayList(); // arraylist to hold all the modifiers
int numForLoop = 20;                   // max number of shapes, modifiers and/or subdividors in the gui (for convenience, just increase when there are more)
boolean drawControlP5 = true;          // toggle drawing of controlP5 gui

void setup() {
  size(sceneWidth,sceneHeight,OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);
   minim = new Minim(this);
  //in = minim.getLineIn(Minim.STEREO, 1024);
  kick = minim.loadSample("Pylons.mp3", 1024);
  fft = new FFT(kick.bufferSize(), kick.sampleRate());
  smooth();
  gui();
  createHemesh();
}

void draw() {
  background(bgcolor);
  perspective(0.518,(float)width/height,1,100000);
  lights();

//Minim analysis
  fft.forward(kick.mix);
  fft.window(FFT.HAMMING);
  float threshold = 100;
  float leftLevel = kick.left.level();
  float rightLevel = byte(kick.right.level());

  if (leftLevel > threshold) {              
    leftLevel = threshold;
  }
  if (rightLevel > threshold) {
    rightLevel = threshold;
  }
  
  for (int j = 0; j < fft.specSize(); j++) {
    for (int i = 0; i < fft.specSize(); i++) {
      values[i][j]=20*fft.getBand(i)*noise(0.5*fft.getBand(i),0.5*fft.getBand(j));
    }
  }
  //End Minim analysis

  pushMatrix();
  viewport();
  drawHemesh();
  popMatrix();
  
  //Export the faces and vertices to apply FFT values
    float[][] vertices =myShape.getVerticesAsFloat(); // first index = vertex index, second index = 0..2, x,y,z coordinate
    int [][] faces = myShape.getFacesAsInt();// first index = face index, second index = index of vertex belonging to face
     
    //Do something with the vertices
    for(int i=0;i<myShape.numberOfVertices();i++){
     vertices[i][0]+=values[i][0]; 
     vertices[i][1]+=values[i][1]; 
     vertices[i][2]+=values[i][2]; 
    }
     
    //Use the exported faces and vertices as source for a HEC_FaceList
    HEC_FromFacelist faceList=new HEC_FromFacelist().setFaces(faces).setVertices(vertices);
    myShape=new HE_Mesh(faceList);



  // save frame(s) without gui
  if (saveOn == true && saveNormal == true) {
    if (saveContinuous) { save("output/" + timestamp + "_Normal/Sequence_" + nf(frameCount-1,4) + ".tga"); }
    else { save("output/screenshots/" + timestamp + " (normal).png"); }
  }

  if (drawControlP5) {
    perspective();
    hint(DISABLE_DEPTH_TEST);
    controlP5.draw(); 
    hint(ENABLE_DEPTH_TEST);
  }

  // save frame(s) with gui
  if (saveOn == true && saveGui == true) {
    if (saveContinuous) { save("output/" + timestamp + "_Gui/Sequence_" + nf(frameCount-1,4) + ".tga"); }
    else { save("output/screenshots/" + timestamp + " (gui).png"); }
  }

  // turn off saving after one frame if continuous is set to false
  if (saveOn == true && saveContinuous == false) {
    saveOn = false;
    println("Saving stopped after one frame (non-continuous)");
  }
  
  
  
}


void stop() {
    // always close Minim audio classes when you are done with them
    kick.close();
    minim.stop();
    
    super.stop();
  }

