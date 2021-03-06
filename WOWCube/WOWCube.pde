import hypermedia.net.*;
UDP udp;

final int FSP = 260; // FACE_SIZE_PIXELS
final int SSP = 240; // SCREEN_SIZE_PIXELS
final int CUBES = 8;
final int FPC = 3  ; // FACES_PER_CUBE

float camRotX = -35; // in degrees!
float camRotY = -45;

int timer = 0;

CCubeSet cs;
CDebugPanel dp;
CRotatePanel rp;
CPawnLogic logic;

enum animType
{
  ANIM_X_CW,
  ANIM_X_CCW,
  ANIM_Y_CW,
  ANIM_Y_CCW,
  ANIM_Z_CW,
  ANIM_Z_CCW,
  ANIM_NONE
};

final int GUI_PORT = 9999;

// Pawn
final String PAWN_HOST = "127.0.0.1";
final int PAWN_PORT_BASE = 10000; // +cubeN

// Each command applies to face's display, which number is next after command.
final byte CMD_GUI_BASE    = 0;
final byte CMD_REDRAW      = CMD_GUI_BASE +  1; // CMD_REDRAW,faceN - copy framebuffer contents to the face specified
final byte CMD_FILL        = CMD_GUI_BASE +  2; // CMD_FILL,R,G,B - to framebuffer, RGB565
final byte CMD_BITMAP      = CMD_GUI_BASE +  3; // CMD_BITMAP,resID,X,Y,angle - to framebuffer, only angle=0|90|180|270 supported
final byte CMD_BITMAP_CLIP = CMD_GUI_BASE +  4; // CMD_BITMAP_CLIP,resID,X,Y,x_ofs,y_ofs,width,height,angle - to framebuffer, only angle=0|90|180|270 supported

final byte CMD_PAWN_BASE   = 100;
final byte CMD_TICK        = CMD_PAWN_BASE + 1;
final byte CMD_DETACH      = CMD_PAWN_BASE + 2;
final byte CMD_ATTACH      = CMD_PAWN_BASE + 3; // CMD_ATTACH,positions_matrix_here
final byte TICK_DELAY      = 100; //Tick Deley in milliseconds

// LCD display object at cube's face
class CDisplay
{
  CFace pface; // backlink to parent Face
  public PGraphics g;

  private PFont fontForCubeID = createFont("Courier New Bold", 125);
  private PFont fontForFaceID = createFont("Courier New Bold", 75);
  private PFont fontForEdgeID = createFont("Courier New Bold", 28);
  private PFont fontForAxis = createFont("Courier New Bold", 32);

  private final int opacityCubeID = 150;
  private final int opacityAxis   = 150;
  private final int opacityEdgeID  = 200;

  CDisplay(CFace _pface)
  {
    pface = _pface;
    g = createGraphics(SSP, SSP, P2D);
  }
  
  void drawOverlay(boolean _drawCubeID, boolean _drawAxis, boolean _drawEdgeID) // draw overlay with cubeID, faceID, axis direction, etc. 
  {
    g.beginDraw();
      if(_drawCubeID)
      {
        g.textFont(fontForCubeID);
        g.textAlign(CENTER, CENTER);
        g.fill(255,0,0,opacityCubeID);
        g.text(""+pface.pcube.cubeN, 0, 0, SSP, SSP);
        g.textFont(fontForFaceID);
        g.fill(255,255,255,opacityCubeID);
        g.text(""+pface.faceN, 0, 0, parseInt((float)2/2*SSP), parseInt((float)1/2.5*SSP));
      }
      if(_drawAxis)
      {
        g.strokeWeight(5); // Face coordinates directions
        g.textFont(fontForAxis);
        g.stroke(255,0,0,opacityAxis);
        g.fill(255,0,0,opacityAxis);
        g.line(5,5,SSP-5,5);
        g.text("X",SSP-25,25);
        g.stroke(0,255,0,opacityAxis);
        g.fill(0,255,0,opacityAxis);
        g.line(5,5,5,SSP-5);
        g.text("Y",25,SSP-25);
      }
      if(_drawEdgeID)
      {
        g.textFont(fontForEdgeID);
        g.textAlign(CENTER, CENTER);
        
        switch(pface.faceN)
        {
          case 0:
            g.fill(255,0,0,opacityEdgeID);
            g.text("1",SSP/2,15);
            g.fill(0,255,0,opacityEdgeID);
            g.text("3",15,SSP/2);
          break;
          
          case 1:
            g.fill(255,0,0,opacityEdgeID);
            g.text("3",SSP/2,15);
            g.fill(0,255,0,opacityEdgeID);
            g.text("2",15,SSP/2);
          break;
          
          case 2:
            g.fill(255,0,0,opacityEdgeID);
            g.text("2",SSP/2,15);
            g.fill(0,255,0,opacityEdgeID);
            g.text("1",15,SSP/2);
          break;
        }
      }
    g.endDraw();
  }
}

// Cube's (1/8 of WOWCube) one face with LCD display on it.
class CFace
{
  public CCube pcube; // backlink to parent Cube
  public int faceN;
  
  CDisplay d;
  PShape sf; // cube's face
  PShape sd; // face's display
  
  CFace(CCube _pcube, int _faceN)
  {
    pcube = _pcube;
    faceN = _faceN;
    
    d = new CDisplay(this);
    
    sf = createShape();
    sf.beginShape(QUADS);
    sf.fill(50, 50, 50);
    sf.vertex(0, 0, 0);
    sf.vertex(FSP, 0, 0);
    sf.vertex(FSP, FSP, 0);
    sf.vertex(0, FSP, 0);
    sf.endShape();
    
    sd = createShape();
    sd.beginShape(QUADS);
    sd.texture(d.g);
    sd.vertex(0, 0, 0, 0, 0);
    sd.vertex(SSP, 0, 0, 1, 0);
    sd.vertex(SSP, SSP, 0, 1, 1);
    sd.vertex(0, SSP, 0, 0, 1);
    sd.endShape();
    sd.translate((FSP-SSP)/2, (FSP-SSP)/2, 1);
  }
  
  void draw()
  {
    shape(sf);
    shape(sd);
  }
  
  void drawOverlay(boolean _drawCubeID, boolean _drawAxis, boolean _drawEdgeID)
  {
    d.drawOverlay(_drawCubeID, _drawAxis, _drawEdgeID);
  }
  
  void translate(int x, int y, int z)
  {
    sf.translate(x,y,z);
    sd.translate(x,y,z);
  }
  
  void rotateX(int deg)
  {
    sf.rotateX(radians(deg));
    sd.rotateX(radians(deg));
  }
  
  void rotateY(int deg)
  {
    sf.rotateY(radians(deg));
    sd.rotateY(radians(deg));
  }
  
  void rotateZ(int deg)
  {
    sf.rotateZ(radians(deg));
    sd.rotateZ(radians(deg));
  }
}

// Cube object is 1/8 of WOWCube. It has 3 faces with LCD displays. It uses 1 framebuffer.
class CCube
{
  public int cubeN;
  public CFace[] f = new CFace[3];
  public PGraphics framebuffer;
  
  CCube(int _cubeN)
  {
    cubeN = _cubeN;
    f[0] = new CFace(this, 0);
    f[0].translate(-FSP/2,-FSP/2,FSP/2);
    f[0].rotateZ(180);
    f[1] = new CFace(this, 1);
    f[1].translate(-FSP/2,-FSP/2,0);
    f[1].rotateZ(90);
    f[1].rotateX(90);
    f[1].translate(0,-FSP/2,0);
    f[2] = new CFace(this, 2);
    f[2].translate(-FSP/2,-FSP/2,0);
    f[2].rotateZ(90);
    f[2].rotateY(-90);
    f[2].rotateX(-180);
    f[2].translate(-FSP/2,0,0);
    framebuffer = createGraphics(SSP, SSP, P2D);
  }
  
  void draw()
  {
    f[0].draw();
    f[1].draw();
    f[2].draw();
  }
  
  void drawOverlays(boolean _drawCubeID, boolean _drawAxis, boolean _drawEdgeID)
  {
    f[0].d.drawOverlay(_drawCubeID, _drawAxis, _drawEdgeID);
    f[1].d.drawOverlay(_drawCubeID, _drawAxis, _drawEdgeID);
    f[2].d.drawOverlay(_drawCubeID, _drawAxis, _drawEdgeID);
  }
  
  void translate(int x, int y, int z)
  {
    f[0].translate(x,y,z);
    f[1].translate(x,y,z);
    f[2].translate(x,y,z);
  }
  
  void rotateX(int deg)
  {
    f[0].rotateX(deg);
    f[1].rotateX(deg);
    f[2].rotateX(deg);
  }
  
  void rotateY(int deg)
  {
    f[0].rotateY(deg);
    f[1].rotateY(deg);
    f[2].rotateY(deg);
  }
  
  void rotateZ(int deg)
  {
    f[0].rotateZ(deg);
    f[1].rotateZ(deg);
    f[2].rotateZ(deg);
  }
}

// WOWCube object - 8 cubes, each has 3 faces with LCD displays.
class CCubeSet
{
  public CCube[] c;
  public animType anim = animType.ANIM_NONE;
  
  private byte[] p = new byte[]{0,1,2,3,4,5,6,7}; // initial positions
  
  public byte[][][] pm = new byte[][][] // "positions matrix" 8x6-24 "projection", each node in 2D matrix is {cubeID,faceID}
  {
    /////// ----- Y ------>
    /* | */ {{-1,-1}, {-1,-1}, { 6, 2}, { 5, 1}, {-1,-1}, {-1,-1}},
    /* | */ {{-1,-1}, {-1,-1}, { 3, 1}, { 0, 2}, {-1,-1}, {-1,-1}},
    /* | */ {{ 6, 1}, { 3, 2}, { 3, 0}, { 0, 0}, { 0, 1}, { 5, 2}},
    /* X */ {{ 7, 2}, { 2, 1}, { 2, 0}, { 1, 0}, { 1, 2}, { 4, 1}},
    /* | */ {{-1,-1}, {-1,-1}, { 2, 2}, { 1, 1}, {-1,-1}, {-1,-1}},
    /* | */ {{-1,-1}, {-1,-1}, { 7, 1}, { 4, 2}, {-1,-1}, {-1,-1}},
    /* | */ {{-1,-1}, {-1,-1}, { 7, 0}, { 4, 0}, {-1,-1}, {-1,-1}},
    /* V */ {{-1,-1}, {-1,-1}, { 6, 0}, { 5, 0}, {-1,-1}, {-1,-1}},
  };
  
  public final short pam[][] = // constant "projection angle matrix" 8x6-24, i.e. "how to rotate HW faces to get flat 2D field" ;-)
  {
    /////// ----- Y ------>
    /* | */ {0,     0,  90, 180,   0,   0},
    /* | */ {0,     0,   0, 270,   0,   0},
    /* | */ {90,  180,  90, 180,  90, 180},
    /* X */ {0,   270,   0, 270,   0, 270},
    /* | */ {0,     0,  90, 180,   0,   0},
    /* | */ {0,     0,   0, 270,   0,   0},
    /* | */ {0,     0,  90, 180,   0,   0},
    /* V */ {0,     0,   0, 270,   0,   0},
  };
  
  private int animAngle = 0;
  private int animSpeed = 5;
  
  CCubeSet()
  {
    c = new CCube[CUBES];
    
    for(int i=0; i<CUBES; i++)
    {
      c[i] = new CCube(i);
      
      switch(i)
      {
        case 0:
          c[i].translate(-FSP/2,-FSP/2,FSP/2);
          break;
          
        case 1:
          c[i].rotateZ(90);
          c[i].translate(FSP/2,-FSP/2,FSP/2);
          break;
          
        case 2:
          c[i].rotateZ(180);
          c[i].translate(FSP/2,FSP/2,FSP/2);
          break;
          
        case 3:
          c[i].rotateZ(270);
          c[i].translate(-FSP/2,FSP/2,FSP/2);
          break;

        case 4:
          c[i].translate(-FSP/2,-FSP/2,-FSP/2);
          break;
          
        case 5:
          c[i].rotateZ(90);
          c[i].translate(FSP/2,-FSP/2,-FSP/2);
          break;
          
        case 6:
          c[i].rotateZ(180);
          c[i].translate(FSP/2,FSP/2,-FSP/2);
          break;
          
        case 7:
          c[i].rotateZ(270);
          c[i].translate(-FSP/2,FSP/2,-FSP/2);
          break;
      }
    }
    
    c[4].rotateY(180);
    c[4].translate(0,0,-FSP);
    c[5].rotateY(180);
    c[5].translate(0,0,-FSP);
    c[6].rotateY(180);
    c[6].translate(0,0,-FSP);
    c[7].rotateY(180);
    c[7].translate(0,0,-FSP);
  }
  
  void draw()
  {
    switch(anim)
    {
      case ANIM_X_CW:
        animAngle += animSpeed;
        c[p[1]].rotateX(animSpeed);
        c[p[2]].rotateX(animSpeed);
        c[p[4]].rotateX(animSpeed);
        c[p[7]].rotateX(animSpeed);
        if(animAngle % 90 == 0) anim_X_CW_end();
      break;
      
      case ANIM_X_CCW:
        animAngle -= animSpeed;
        c[p[1]].rotateX(-animSpeed);
        c[p[2]].rotateX(-animSpeed);
        c[p[4]].rotateX(-animSpeed);
        c[p[7]].rotateX(-animSpeed);
        if(animAngle % 90 == 0) anim_X_CCW_end();
      break;

      case ANIM_Y_CW:
        animAngle -= animSpeed;
        c[p[0]].rotateY(-animSpeed);
        c[p[1]].rotateY(-animSpeed);
        c[p[4]].rotateY(-animSpeed);
        c[p[5]].rotateY(-animSpeed);
        if(animAngle % 90 == 0) anim_Y_CCW_end();
      break;

      case ANIM_Y_CCW:
        animAngle += animSpeed;
        c[p[0]].rotateY(animSpeed);
        c[p[1]].rotateY(animSpeed);
        c[p[4]].rotateY(animSpeed);
        c[p[5]].rotateY(animSpeed);
        if(animAngle % 90 == 0) anim_Y_CW_end();
      break;
      
      case ANIM_Z_CW:
        animAngle += animSpeed;
        c[p[0]].rotateZ(animSpeed);
        c[p[1]].rotateZ(animSpeed);
        c[p[2]].rotateZ(animSpeed);
        c[p[3]].rotateZ(animSpeed);
        if(animAngle % 90 == 0) anim_Z_CW_end();
      break;
      
      case ANIM_Z_CCW:
        animAngle -= animSpeed;
        c[p[0]].rotateZ(-animSpeed);
        c[p[1]].rotateZ(-animSpeed);
        c[p[2]].rotateZ(-animSpeed);
        c[p[3]].rotateZ(-animSpeed);
        if(animAngle % 90 == 0) anim_Z_CCW_end();
      break;
      
      case ANIM_NONE:
      default:
        animAngle = 0;
      break;
    }
    
    for(int i=0; i<CUBES; i++) c[i].draw();
  }

  void drawOverlays(boolean _drawCubeID, boolean _drawAxis, boolean _drawEdgeID, boolean _drawPMIndexes)
  {
    for(int i=0; i<CUBES; i++) c[i].drawOverlays(_drawCubeID, _drawAxis, _drawEdgeID);
    
    if(_drawPMIndexes)
    {
      for(int y=0; y<6; y++)
      {
        for(int x=0; x<8; x++)
        {
          int cubeID = pm[x][y][0];
          int faceID = pm[x][y][1];
          
          if(cubeID != -1)
          {
            PGraphics g = this.c[cubeID].f[faceID].d.g;
            // draw array indexes
            g.beginDraw();
              g.text("["+x+","+y+"]",50,20);
            g.endDraw();
          }
        }
      }
    }
  }
 
  void anim_X_CW_begin()  { anim = animType.ANIM_X_CW;  logic.onCsDetach(); } // w
  void anim_X_CCW_begin() { anim = animType.ANIM_X_CCW; logic.onCsDetach(); } // s
  void anim_Y_CW_begin()  { anim = animType.ANIM_Y_CW;  logic.onCsDetach(); } // q
  void anim_Y_CCW_begin() { anim = animType.ANIM_Y_CCW; logic.onCsDetach(); } // e
  void anim_Z_CW_begin()  { anim = animType.ANIM_Z_CW;  logic.onCsDetach(); } // d
  void anim_Z_CCW_begin() { anim = animType.ANIM_Z_CCW; logic.onCsDetach(); } // a
  
  private void anim_X_CW_end() // w
  {
    p = new byte[]{p[0], p[2], p[7], p[3], p[1], p[5], p[6], p[4]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[0][3][0], pm[0][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[1][2][0], pm[1][2][1]}, {pm[1][3][0], pm[1][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[2][1][0], pm[2][1][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[2][3][0], pm[2][3][1]}, {pm[2][4][0], pm[2][4][1]}, {pm[2][5][0], pm[2][5][1]}},
      /* X */ {{pm[6][3][0], pm[6][3][1]}, {pm[6][2][0], pm[6][2][1]}, {pm[3][0][0], pm[3][0][1]}, {pm[3][1][0], pm[3][1][1]}, {pm[3][2][0], pm[3][2][1]}, {pm[3][3][0], pm[3][3][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][2][0], pm[5][2][1]}, {pm[4][2][0], pm[4][2][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][3][0], pm[5][3][1]}, {pm[4][3][0], pm[4][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[3][5][0], pm[3][5][1]}, {pm[3][4][0], pm[3][4][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void anim_X_CCW_end() // s
  {
    p = new byte[]{p[0], p[4], p[1], p[3], p[7], p[5], p[6], p[2]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[0][3][0], pm[0][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[1][2][0], pm[1][2][1]}, {pm[1][3][0], pm[1][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[2][1][0], pm[2][1][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[2][3][0], pm[2][3][1]}, {pm[2][4][0], pm[2][4][1]}, {pm[2][5][0], pm[2][5][1]}},
      /* X */ {{pm[3][2][0], pm[3][2][1]}, {pm[3][3][0], pm[3][3][1]}, {pm[3][4][0], pm[3][4][1]}, {pm[3][5][0], pm[3][5][1]}, {pm[6][3][0], pm[6][3][1]}, {pm[6][2][0], pm[6][2][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[4][3][0], pm[4][3][1]}, {pm[5][3][0], pm[5][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[4][2][0], pm[4][2][1]}, {pm[5][2][0], pm[5][2][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[3][1][0], pm[3][1][1]}, {pm[3][0][0], pm[3][0][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void anim_Y_CW_end() // q
  {
    p = new byte[]{p[5], p[0], p[2], p[3], p[1], p[4], p[6], p[7]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[6][3][0], pm[6][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[1][2][0], pm[1][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[2][1][0], pm[2][1][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[0][3][0], pm[0][3][1]}, {pm[2][5][0], pm[2][5][1]}, {pm[3][5][0], pm[3][5][1]}},
      /* X */ {{pm[3][0][0], pm[3][0][1]}, {pm[3][1][0], pm[3][1][1]}, {pm[3][2][0], pm[3][2][1]}, {pm[1][3][0], pm[1][3][1]}, {pm[2][4][0], pm[2][4][1]}, {pm[3][4][0], pm[3][4][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[4][2][0], pm[4][2][1]}, {pm[2][3][0], pm[2][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][2][0], pm[5][2][1]}, {pm[3][3][0], pm[3][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[6][2][0], pm[6][2][1]}, {pm[4][3][0], pm[4][3][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[5][3][0], pm[5][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void anim_Y_CCW_end() // e
  {
    p = new byte[]{p[1], p[4], p[2], p[3], p[5], p[0], p[6], p[7]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[2][3][0], pm[2][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[1][2][0], pm[1][2][1]}, {pm[3][3][0], pm[3][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[2][1][0], pm[2][1][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[4][3][0], pm[4][3][1]}, {pm[3][4][0], pm[3][4][1]}, {pm[2][4][0], pm[2][4][1]}},
      /* X */ {{pm[3][0][0], pm[3][0][1]}, {pm[3][1][0], pm[3][1][1]}, {pm[3][2][0], pm[3][2][1]}, {pm[5][3][0], pm[5][3][1]}, {pm[3][5][0], pm[3][5][1]}, {pm[2][5][0], pm[2][5][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[4][2][0], pm[4][2][1]}, {pm[6][3][0], pm[6][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][2][0], pm[5][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[6][2][0], pm[6][2][1]}, {pm[0][3][0], pm[0][3][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[1][3][0], pm[1][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void anim_Z_CW_end() // d
  {
    p = new byte[]{p[3], p[0], p[1], p[2], p[4], p[5], p[6], p[7]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[0][3][0], pm[0][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[3][1][0], pm[3][1][1]}, {pm[2][1][0], pm[2][1][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[4][2][0], pm[4][2][1]}, {pm[3][2][0], pm[3][2][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[1][2][0], pm[1][2][1]}, {pm[2][5][0], pm[2][5][1]}},
      /* X */ {{pm[3][0][0], pm[3][0][1]}, {pm[4][3][0], pm[4][3][1]}, {pm[3][3][0], pm[3][3][1]}, {pm[2][3][0], pm[2][3][1]}, {pm[1][3][0], pm[1][3][1]}, {pm[3][5][0], pm[3][5][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[3][4][0], pm[3][4][1]}, {pm[2][4][0], pm[2][4][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][2][0], pm[5][2][1]}, {pm[5][3][0], pm[5][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[6][2][0], pm[6][2][1]}, {pm[6][3][0], pm[6][3][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void anim_Z_CCW_end() // a
  {
    p = new byte[]{p[1], p[2], p[3], p[0], p[4], p[5], p[6], p[7]};
    pm = new byte[][][]
    {
      /////// ----- Y ------>
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[0][2][0], pm[0][2][1]}, {pm[0][3][0], pm[0][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[2][4][0], pm[2][4][1]}, {pm[3][4][0], pm[3][4][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{pm[2][0][0], pm[2][0][1]}, {pm[1][3][0], pm[1][3][1]}, {pm[2][3][0], pm[2][3][1]}, {pm[3][3][0], pm[3][3][1]}, {pm[4][3][0], pm[4][3][1]}, {pm[2][5][0], pm[2][5][1]}},
      /* X */ {{pm[3][0][0], pm[3][0][1]}, {pm[1][2][0], pm[1][2][1]}, {pm[2][2][0], pm[2][2][1]}, {pm[3][2][0], pm[3][2][1]}, {pm[4][2][0], pm[4][2][1]}, {pm[3][5][0], pm[3][5][1]}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[2][1][0], pm[2][1][1]}, {pm[3][1][0], pm[3][1][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[5][2][0], pm[5][2][1]}, {pm[5][3][0], pm[5][3][1]},                    {-1,-1},                    {-1,-1}},
      /* | */ {{-1,-1},                                       {-1,-1}, {pm[6][2][0], pm[6][2][1]}, {pm[6][3][0], pm[6][3][1]},                    {-1,-1},                    {-1,-1}},
      /* V */ {{-1,-1},                                       {-1,-1}, {pm[7][2][0], pm[7][2][1]}, {pm[7][3][0], pm[7][3][1]},                    {-1,-1},                    {-1,-1}},
    };
    onAnyAnimEnd();
  }
  
  private void onAnyAnimEnd()
  {
    anim = animType.ANIM_NONE;
    logic.onCsAttach();
    //printPositionMatrix();
  }
  
  public void printPositionMatrix()
  {
    for(int y=5; y>=0; y--)
    {
      for(int x=0; x<8; x++)
      {
        if(pm[x][y][0] == -1) print("      ");
        else print("["+pm[x][y][0]+","+pm[x][y][1]+"] ");
      }
      print("\n");
    }
    print("\n");
  }
}

// "Cross" projection of the cube at top-left
class CDebugPanel
{
  final float scale = 0.25; // scale of model
  final int X = 8;
  final int Y = 6;
  PShape s[] = new PShape[X*Y];
  
  CDebugPanel()
  {
    for(int y=0; y<Y; y++)
    {
      for(int x=0; x<X; x++)
      {
        if(cs.pm[x][y][0] != -1)
        {
          s[y*8+x] = createShape();
          s[y*8+x].translate(-(SSP*scale)/2, -(SSP*scale)/2, 0);
          s[y*8+x].rotateZ(radians(cs.pam[x][y]));
          s[y*8+x].translate(x*(SSP*scale)+(SSP*scale)/2, (SSP*scale)*5-y*(SSP*scale)+(SSP*scale)/2, 0);
          s[y*8+x].beginShape(QUADS);
          //s[y*8+x].tint(255,127); // opacity!
          s[y*8+x].texture(cs.c[cs.pm[x][y][0]].f[cs.pm[x][y][1]].d.g);
          s[y*8+x].vertex(0, 0, 0, 0, 0);
          s[y*8+x].vertex(SSP*scale, 0, 0, 1, 0);
          s[y*8+x].vertex(SSP*scale, SSP*scale, 0, 1, 1);
          s[y*8+x].vertex(0, SSP*scale, 0, 0, 1);
          s[y*8+x].endShape();
        }
      }
    }
  }
  
  void draw()
  {
    for(int y=0; y<Y; y++)
    {
      for(int x=0; x<X; x++)
      {
        if(cs.pm[x][y][0] != -1)
        {
          s[y*8+x].setTexture(cs.c[cs.pm[x][y][0]].f[cs.pm[x][y][1]].d.g);
          shape(s[y*8+x]); // draw!
        }
      }
    }
  }
}

class CRotatePanel
{
  final float PANEL_SCALE = 0.5;
  final int SHAPE_SIZE = 256;
  final int X_OFS = 800-SHAPE_SIZE-10;
  final int Y_OFS = 10;
  private PShape s = new PShape();
  private PGraphics g;
  private PImage img_base = new PImage();
  private PImage img_axis_x_ccw = new PImage();
  private PImage img_axis_x_ccw_hover = new PImage();
  private PImage img_axis_x_cw = new PImage();
  private PImage img_axis_x_cw_hover = new PImage();
  private PImage img_axis_y_ccw = new PImage();
  private PImage img_axis_y_ccw_hover = new PImage();
  private PImage img_axis_y_cw = new PImage();
  private PImage img_axis_y_cw_hover = new PImage();
  private PImage img_axis_z_ccw = new PImage();
  private PImage img_axis_z_ccw_hover = new PImage();
  private PImage img_axis_z_cw = new PImage();
  private PImage img_axis_z_cw_hover = new PImage();

  CRotatePanel()
  {
    img_base = loadImage("forGUI/axis_base.png");
    img_axis_x_ccw = loadImage("forGUI/axis_x-ccw.png");
    img_axis_x_ccw_hover = loadImage("forGUI/axis_x-ccw_hover.png");
    img_axis_x_cw = loadImage("forGUI/axis_x-cw.png");
    img_axis_x_cw_hover = loadImage("forGUI/axis_x-cw_hover.png");
    img_axis_y_ccw = loadImage("forGUI/axis_y-ccw.png");
    img_axis_y_ccw_hover = loadImage("forGUI/axis_y-ccw_hover.png");
    img_axis_y_cw = loadImage("forGUI/axis_y-cw.png");
    img_axis_y_cw_hover = loadImage("forGUI/axis_y-cw_hover.png");
    img_axis_z_ccw = loadImage("forGUI/axis_z-ccw.png");
    img_axis_z_ccw_hover = loadImage("forGUI/axis_z-ccw_hover.png");
    img_axis_z_cw = loadImage("forGUI/axis_z-cw.png");
    img_axis_z_cw_hover = loadImage("forGUI/axis_z-cw_hover.png");
    g = createGraphics(SHAPE_SIZE,SHAPE_SIZE+10,P2D);
    s = createShape();
    s.beginShape(QUADS);
    s.translate(X_OFS,Y_OFS);
    s.noStroke();
    s.vertex(0, 0, 0, 0, 0);
    s.vertex(SHAPE_SIZE, 0, 0, 1, 0);
    s.vertex(SHAPE_SIZE, SHAPE_SIZE, 0, 1, 1);
    s.vertex(0, SHAPE_SIZE, 0, 0, 1);
    s.endShape();
  }

  void draw()
  {
    g.beginDraw();
      g.image(img_base,0,0,img_base.width*PANEL_SCALE,img_base.height*PANEL_SCALE);
      // X CCW
      if((mouseX > X_OFS+128) && (mouseX < X_OFS+128*2) && (mouseY > Y_OFS+132+66) && (mouseY < Y_OFS+132*2))
      {
        g.image(img_axis_x_ccw_hover,128,132+66,img_axis_x_ccw_hover.width*PANEL_SCALE,img_axis_x_ccw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_X_CCW_begin();
      }
      else
      {
        g.image(img_axis_x_ccw,128,132+66,img_axis_x_ccw.width*PANEL_SCALE,img_axis_x_ccw.height*PANEL_SCALE);
      }
      // X CW
      if((mouseX > X_OFS+128) && (mouseX < X_OFS+128*2) && (mouseY > Y_OFS+132) && (mouseY < Y_OFS+132+66))
      {
        g.image(img_axis_x_cw_hover,128,132,img_axis_x_cw_hover.width*PANEL_SCALE,img_axis_x_cw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_X_CW_begin();
      }
      else
      {
        g.image(img_axis_x_cw,128,132,img_axis_x_cw.width*PANEL_SCALE,img_axis_x_cw.height*PANEL_SCALE);
      }
      // Y CCW
      if((mouseX > X_OFS+128) && (mouseX < X_OFS+128*2) && (mouseY > Y_OFS) && (mouseY < Y_OFS+95))
      {
        g.image(img_axis_y_ccw_hover,128,0,img_axis_y_ccw_hover.width*PANEL_SCALE,img_axis_y_ccw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_Y_CCW_begin();
      }
      else
      {
        g.image(img_axis_y_ccw,128,0,img_axis_y_ccw.width*PANEL_SCALE,img_axis_y_ccw.height*PANEL_SCALE);
      }
      // Y CW
      if((mouseX > X_OFS) && (mouseX < X_OFS+128) && (mouseY > Y_OFS) && (mouseY < Y_OFS+95))
      {
        g.image(img_axis_y_cw_hover,0,0,img_axis_y_cw_hover.width*PANEL_SCALE,img_axis_y_cw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_Y_CW_begin();
      }
      else
      {
        g.image(img_axis_y_cw,0,0,img_axis_y_cw.width*PANEL_SCALE,img_axis_y_cw.height*PANEL_SCALE);
      }
      // Z CCW
      if((mouseX > X_OFS) && (mouseX < X_OFS+128) && (mouseY > Y_OFS+132) && (mouseY < Y_OFS+132+66))
      {
        g.image(img_axis_z_ccw_hover,0,132,img_axis_z_ccw_hover.width*PANEL_SCALE,img_axis_z_ccw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_Z_CCW_begin();
      }
      else
      {
        g.image(img_axis_z_ccw,0,132,img_axis_z_ccw.width*PANEL_SCALE,img_axis_z_ccw.height*PANEL_SCALE);
      }
      // Z CW
      if((mouseX > X_OFS) && (mouseX < X_OFS+128) && (mouseY > Y_OFS+132+66) && (mouseY < Y_OFS+132+132))
      {
        g.image(img_axis_z_cw_hover,0,132+66,img_axis_z_cw_hover.width*PANEL_SCALE,img_axis_z_cw_hover.height*PANEL_SCALE);
        if(mousePressed) cs.anim_Z_CW_begin();
      }
      else
      {
        g.image(img_axis_z_cw,0,132+66,img_axis_z_cw.width*PANEL_SCALE,img_axis_z_cw.height*PANEL_SCALE);
      }
    g.endDraw();
    s.setTexture(g);
    shape(s);
  }
}

class CPawnCmd
{
  public int cubeN;
  public byte[] pkt;
  
  CPawnCmd(int _cubeN, byte[] _pkt)
  {
    this.cubeN = _cubeN;
    this.pkt = new byte[_pkt.length];
    arrayCopy(_pkt,this.pkt);
  }
}

class CPawnLogic // interface to/from Pawn
{
  private PImage res[]; // resources are loaded in "by name" order from Resources folder for all games
  private ArrayList<CPawnCmd> pawn_cmd_queue = new ArrayList<CPawnCmd>(); 
  
  CPawnLogic()
  {
    // Load all files for "Resources"
    int count_files =0;
    ArrayList <String> files = new ArrayList<String>();
    File f = new File("../WOWCube/Resources");
    for (File item : f.listFiles())
      if (!item.isDirectory())
        files.add(item.getName());
    count_files = files.size();
    res = new PImage[count_files];
    for(int i=0;i<count_files;i++)
      res[i] = loadImage("Resources/"+files.get(i));
  }
  
  void draw()
  {
    while(!pawn_cmd_queue.isEmpty())
    {
      CPawnCmd c = pawn_cmd_queue.remove(0); // pop command from Pawn

      try
      {
        switch(c.pkt[0])
        {
          case CMD_REDRAW:
            int faceN = c.pkt[1];
            println("CMD_REDRAW: FRAMEBUFFER["+c.cubeN+"] --> cubeN="+c.cubeN+" faceN="+faceN);
            PGraphics src = cs.c[c.cubeN].framebuffer;
            PGraphics dst = cs.c[c.cubeN].f[faceN].d.g;
            src.loadPixels();
            dst.loadPixels();
            dst.beginDraw();
            arrayCopy(src.pixels, dst.pixels);
            dst.updatePixels();
            dst.endDraw();
          break;
          
          case CMD_FILL:
          {
            int R = unhex(hex(c.pkt[1]));
            int G = unhex(hex(c.pkt[2]));
            int B = unhex(hex(c.pkt[3]));
            println("CMD_FILL: R="+R+" G="+G+" B="+B+" --> FRAMEBUFFER["+c.cubeN+"]");
            PGraphics g = cs.c[c.cubeN].framebuffer;
            g.beginDraw();
              g.background(R,G,B);
            g.endDraw();
          }
          break;
          
          case CMD_BITMAP:
          {
            int resID = unhex(hex(c.pkt[2])+hex(c.pkt[1]));
            int x = unhex(hex(c.pkt[4])+hex(c.pkt[3]));
            int y = unhex(hex(c.pkt[6])+hex(c.pkt[5]));
            int angle = unhex(hex(c.pkt[8])+hex(c.pkt[7]));
            println("CMD_BITMAP: resID="+resID+" x="+x+" y="+y+" angle="+angle+" --> FRAMEBUFFER["+c.cubeN+"]");
            PGraphics g = cs.c[c.cubeN].framebuffer;
            g.beginDraw();
              g.image(res[resID],x,y);
            g.endDraw();
          }
          break;

          case CMD_BITMAP_CLIP:
          {
            int resID = unhex(hex(c.pkt[2])+hex(c.pkt[1]));
            int x = unhex(hex(c.pkt[4])+hex(c.pkt[3]));
            int y = unhex(hex(c.pkt[6])+hex(c.pkt[5]));
            int x_ofs = unhex(hex(c.pkt[8])+hex(c.pkt[7]));
            int y_ofs = unhex(hex(c.pkt[10])+hex(c.pkt[9]));
            int lv_width = unhex(hex(c.pkt[12])+hex(c.pkt[11]));
            int lv_height = unhex(hex(c.pkt[14])+hex(c.pkt[13]));
            int angle = unhex(hex(c.pkt[16])+hex(c.pkt[15]));
            println("CMD_BITMAP_CLIP: resID="+resID+" x="+x+" y="+y+" angle="+angle+" --> FRAMEBUFFER["+c.cubeN+"]");
            PGraphics g = cs.c[c.cubeN].framebuffer;
            PImage crop = res[resID].get(x_ofs,y_ofs,lv_width,lv_height);
            g.beginDraw();
              g.image(crop,x,y);
            g.endDraw();
          }
          break;
        }
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }
    }
  }
  
  void tick() // on timer
  {
    byte[] data = new byte[1];
    data[0] = CMD_TICK;
    for(int i=0; i<CUBES; i++) udp.send(data, PAWN_HOST, PAWN_PORT_BASE+i);
  }
  
  void onCsDetach() // cubeset detached (rotate anim started) 
  {
    byte[] data = new byte[1];
    data[0] = CMD_DETACH;
    for(int i=0; i<CUBES; i++) udp.send(data, PAWN_HOST, PAWN_PORT_BASE+i);
  }
  
  void onCsAttach() // cubeset attached (rotate anim ends)
  {
    byte[] data = new byte[1+8*6*2];
    data[0] = CMD_ATTACH;
    for(int x=0; x<8; x++)
      for(int y=0; y<6; y++)
        for(int z=0; z<2; z++)
          data[1+x*6*2+y*2+z] = cs.pm[x][y][z]; // serialize positions matrix
    for(int i=0; i<CUBES; i++) udp.send(data, PAWN_HOST, PAWN_PORT_BASE+i);
  }

  void logUDP(byte[] pkt, String ip, int port)
  {
    print("["+ip+":"+port+"] rcv pkt["+pkt.length+"]: ");
    for(int i=0; i<pkt.length; i++) print(hex(pkt[i])+" ");
    println();
  }

  void onUDP(byte[] pkt, String ip, int port)
  {
    logUDP(pkt, ip, port); // debug
    pawn_cmd_queue.add(new CPawnCmd((port-PAWN_PORT_BASE), pkt)); // push command from Pawn
  }
}

void setup()
{
  size(800, 700, P3D); // can use only numbers, not constants here :(
  textureMode(NORMAL);
  cs = new CCubeSet();
  dp = new CDebugPanel();
  rp = new CRotatePanel();
  logic = new CPawnLogic();
  udp = new UDP(this, GUI_PORT);
  udp.listen(true);
  logic.onCsAttach(); // start attached!
  
  // debug
  cs.printPositionMatrix();
  // debug
}

void draw()
{
  background(230);
  noStroke();
  
  if(millis() - timer >= TICK_DELAY)
  {
    logic.tick();
    timer = millis();
  }

  logic.draw();
  cs.drawOverlays(false, false, false, false);
 
  pushMatrix();
    translate(2.2*FSP, 2.2*FSP, -3.0*FSP);
    rotateX(radians(camRotX));
    rotateY(radians(camRotY));
    cs.draw();
  popMatrix();
  
  dp.draw();
  rp.draw();
}

void mouseDragged()
{
  float rate = 0.1;
  camRotX += (pmouseY-mouseY) * rate;
  camRotY += (mouseX-pmouseX) * rate;
}

void keyPressed()
{
  if(cs.anim == animType.ANIM_NONE)
  {
    if(key == 'w') { cs.anim_X_CW_begin(); }
    if(key == 's') { cs.anim_X_CCW_begin(); }
    if(key == 'e') { cs.anim_Y_CW_begin(); }
    if(key == 'q') { cs.anim_Y_CCW_begin(); }
    if(key == 'd') { cs.anim_Z_CW_begin(); }
    if(key == 'a') { cs.anim_Z_CCW_begin(); }
  }
}

void receive(byte[] pkt, String ip, int port) {
  logic.onUDP(pkt, ip, port);
}