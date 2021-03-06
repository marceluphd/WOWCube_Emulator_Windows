#if defined CUBIOS_EMULATOR
#include <core>
#include <args>
#include <string>
#include <datagram>
#else // HW
native sendpacket(const packet[], const size);
#endif

// ABI global constants
#define GUI_ADDR "127.0.0.1:9999"
#define PAWN_PORT_BASE  10000

#define CMD_GUI_BASE    0
#define CMD_REDRAW      CMD_GUI_BASE+1 /* CMD_REDRAW,faceN - copy framebuffer contents to the face specified */
#define CMD_FILL        CMD_GUI_BASE+2 /* CMD_FILL,R,G,B - to framebuffer, RGB565 */
#define CMD_BITMAP      CMD_GUI_BASE+3 /* CMD_BITMAP,resID,X,Y,angle - to framebuffer, only angle=0|90|180|270 supported */
#define CMD_BITMAP_CLIP CMD_GUI_BASE+4 /* CMD_BITMAP_CLIP,resID,X,Y,x_ofs,y_ofs,width,height,angle - to framebuffer, only angle=0|90|180|270 supported */
#define CMD_PAWN_BASE   100
#define CMD_TICK        CMD_PAWN_BASE+1
#define CMD_DETACH      CMD_PAWN_BASE+2
#define CMD_ATTACH      CMD_PAWN_BASE+3 /* CMD_ATTACH,positions_matrix_here */

#define DISPLAY_PX  240 // 240x240

#define PROJECTION_MAX_X  8
#define PROJECTION_MAX_Y  6

#define CUBES_MAX 8
#define FACES_PER_CUBE 3
#define RIBS_PER_CUBE 4

// Initial "Positions Matrix" 8x6-24 "projection", each node in 2D matrix is {cubeID,faceID}
new const abi_initial_pm[][][] = [
  [[-1,-1], [-1,-1], [ 6, 2], [ 5, 1], [-1,-1], [-1,-1]],
  [[-1,-1], [-1,-1], [ 3, 1], [ 0, 2], [-1,-1], [-1,-1]],
  [[ 6, 1], [ 3, 2], [ 3, 0], [ 0, 0], [ 0, 1], [ 5, 2]],
  [[ 7, 2], [ 2, 1], [ 2, 0], [ 1, 0], [ 1, 2], [ 4, 1]],
  [[-1,-1], [-1,-1], [ 2, 2], [ 1, 1], [-1,-1], [-1,-1]],
  [[-1,-1], [-1,-1], [ 7, 1], [ 4, 2], [-1,-1], [-1,-1]],
  [[-1,-1], [-1,-1], [ 7, 0], [ 4, 0], [-1,-1], [-1,-1]],
  [[-1,-1], [-1,-1], [ 6, 0], [ 5, 0], [-1,-1], [-1,-1]],
]

// "Projection Angle Matrix" 8x6-24, i.e. "how to rotate HW faces to get flat 2D field"
new const abi_pam[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [0,     0,  90, 180,   0,   0],
  [0,     0,   0, 270,   0,   0],
  [90,  180,  90, 180,  90, 180],
  [0,   270,   0, 270,   0, 270],
  [0,     0,  90, 180,   0,   0],
  [0,     0,   0, 270,   0,   0],
  [0,     0,  90, 180,   0,   0],
  [0,     0,   0, 270,   0,   0]
];

// ABI global variables
new abi_cubeN = 0;
new abi_pm[PROJECTION_MAX_X][PROJECTION_MAX_Y][2]; // positions matrix
new abi_attached = 0; // 0 - cubes detached (rotating), 1 - cubes attached

// ABI helpers
#if defined CUBIOS_EMULATOR
abi_LogRcvPkt(const pkt[], size, const src[])
{
  printf("[%s] rcv pkt[%d]: ", src, size);
  for(new abi_i=0; abi_i<size; abi_i++) printf(" %02x", abi_GetPktByte(pkt, abi_i));
  printf("\n");
}

abi_LogSndPkt(const pkt[], size, const cubeN)
{
  printf("[127.0.0.1:%d] snd pkt[%d]: ", PAWN_PORT_BASE+cubeN, size);
  for(new abi_i=0; abi_i<size; abi_i++) printf(" %02x", abi_GetPktByte(pkt, abi_i));
  printf("\n");
}

abi_LogPositionsMatrix()
{
  printf("PM state:\n");
  
  for(new abi_y=(PROJECTION_MAX_Y-1); abi_y>=0; abi_y--)
  {
    for(new abi_x=0; abi_x<PROJECTION_MAX_X; abi_x++)
    {
      if(abi_pm[abi_x][abi_y][0] == 0xFF) printf("      ");
      else printf("[%d,%d] ", abi_pm[abi_x][abi_y][0], abi_pm[abi_x][abi_y][1]);
    }
    printf("\n");
  }
  printf("\n");
}
#else
forward abi_GetCubeN();
forward abi_SetCubeN(const cubeN);

public abi_GetCubeN()
{
  return abi_cubeN;
}

public abi_SetCubeN(const cubeN)
{
  abi_cubeN = cubeN;
}
#endif

abi_GetPktByte(const pkt[], const n)
{
  return ((pkt[n/4] >> (8*(n%4))) & 0xFF);
}

abi_DeserializePositonsMatrix(const pkt[])
{
  for(new abi_x=0; abi_x<PROJECTION_MAX_X; abi_x++)
    for(new abi_y=0; abi_y<PROJECTION_MAX_Y; abi_y++)
      for(new abi_z=0; abi_z<2; abi_z++)
        abi_pm[abi_x][abi_y][abi_z] = abi_GetPktByte(pkt, 1+abi_x*6*2+abi_y*2+abi_z);
}

abi_FacePositionAtProjection(const cubeN, const faceN, &projX, &projY, &projRotAngle)
{
  for(new abi_x=0; abi_x<PROJECTION_MAX_X; abi_x++)
    for(new abi_y=0; abi_y<PROJECTION_MAX_Y; abi_y++)
    {
      if((abi_pm[abi_x][abi_y][0] == cubeN) && (abi_pm[abi_x][abi_y][1] == faceN))
      {
        projX = abi_x; // found!
        projY = abi_y;
        projRotAngle = abi_pam[projX][projY];
        return;
      }
    }
}

abi_InitialFacePositionAtProjection(const cubeN, const faceN, &projX, &projY, &projRotAngle)
{
  for(new abi_x=0; abi_x<PROJECTION_MAX_X; abi_x++)
    for(new abi_y=0; abi_y<PROJECTION_MAX_Y; abi_y++)
    {
      if((abi_initial_pm[abi_x][abi_y][0] == cubeN) && (abi_initial_pm[abi_x][abi_y][1] == faceN))
      {
        projX = abi_x; // found!
        projY = abi_y;
        projRotAngle = abi_pam[projX][projY];
        return;
      }
    }
}

// ABI functions - sends commands to GUI
abi_CMD_REDRAW(const faceN)
{
  new pkt[1] = 0;
  pkt[0] = ((faceN & 0xFF) << 8) | (CMD_REDRAW & 0xFF);
  //abi_LogSndPkt(pkt, 1*4, abi_cubeN);
#if defined CUBIOS_EMULATOR
  sendpacket(pkt, 1, GUI_ADDR);
#else
  sendpacket(pkt, 1);
#endif
}

abi_CMD_FILL(const R, const G, const B)
{
  new pkt[1] = 0;
  pkt[0] = ((B & 0x1F) << 24) | ((G & 0x3F) << 16) | ((R & 0x1F) << 8) | (CMD_FILL & 0xFF); // RGB565, Rmax=31, Gmax=63, Bmax=31
  //abi_LogSndPkt(pkt, 1*4, abi_cubeN);
#if defined CUBIOS_EMULATOR
  sendpacket(pkt, 1, GUI_ADDR);
#else
  sendpacket(pkt, 1);
#endif
}

abi_CMD_BITMAP(const resID, const x, const y, const angle)
{
  new pkt[3] = 0;
  pkt[0] = ((x & 0xFF) << 24) | ((resID & 0xFFFF) << 8) | (CMD_BITMAP & 0xFF);
  pkt[1] = ((angle & 0xFF) << 24) | ((y & 0xFFFF) << 8) | ((x & 0xFF00) >> 8);
  pkt[2] = ((angle & 0xFF00) >> 8);
  //abi_LogSndPkt(pkt, 3*4, abi_cubeN);
#if defined CUBIOS_EMULATOR
  sendpacket(pkt, 3, GUI_ADDR);
#else
  sendpacket(pkt, 3);
#endif
}

abi_CMD_BITMAP_CLIP(const resID, const x, const y, const x_ofs, const y_ofs, const width, const height, const angle)
{
  new pkt[5] = 0;
  pkt[0] = ((x & 0xFF) << 24) | ((resID & 0xFFFF) << 8) | (CMD_BITMAP_CLIP & 0xFF);
  pkt[1] = ((x_ofs & 0xFF) << 24) | ((y & 0xFFFF) << 8) | ((x & 0xFF00) >> 8);
  pkt[2] = ((width & 0xFF) << 24) | ((y_ofs & 0xFFFF) << 8) | ((x_ofs & 0xFF00) >> 8);
  pkt[3] = ((angle & 0xFF) << 24) | ((height & 0xFFFF) << 8) | ((width & 0xFF00) >> 8);
  pkt[4] = ((angle & 0xFF00) >> 8);
  //abi_LogSndPkt(pkt, 5*4, abi_cubeN);
#if defined CUBIOS_EMULATOR
  sendpacket(pkt, 5, GUI_ADDR);
#else
  sendpacket(pkt, 5);
#endif
}

// Process binary commands from GUI
#if defined CUBIOS_EMULATOR
@receivepacket(const packet[], size, const source[])
{
  run(packet, size, source);
}

// This is for run CLI Pawn until key press. Will not be used in MCU version.
@keypressed(key)
{
  exit;
}
#endif
