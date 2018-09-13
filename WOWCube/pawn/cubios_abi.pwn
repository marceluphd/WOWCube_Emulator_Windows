#if defined CUBIOS_EMULATOR
#include <core>
#include <args>
#include <string>
#include <datagram>
#else // HW
native sendpacket(const packet[], const size);
#endif

// ABI global constants
#if defined CUBIOS_EMULATOR
#define GUI_ADDR "127.0.0.1:9999"
#define PAWN_PORT_BASE  10000
#endif

#define CMD_GUI_BASE    0
#define CMD_REDRAW      CMD_GUI_BASE+1 /* CMD_REDRAW,faceN - copy framebuffer contents to the face specified */
#define CMD_FILL        CMD_GUI_BASE+2 /* CMD_FILL,R,G,B - to framebuffer, RGB565 */
#define CMD_BITMAP      CMD_GUI_BASE+3 /* CMD_BITMAP,resID,X,Y,angle - to framebuffer, only angle=0|90|180|270 supported */
#define CMD_BITMAP_CLIP CMD_GUI_BASE+4 /* CMD_BITMAP_CLIP,resID,X,Y,x_ofs,y_ofs,width,height,angle - to framebuffer, only angle=0|90|180|270 supported */
#define CMD_PAWN_BASE   100
#define CMD_TICK        CMD_PAWN_BASE+1
#define CMD_GEO         CMD_PAWN_BASE+2 /* CMD_ATTACH, n_records, <TRBL records here> */

#define CUBES_MAX 8
#define FACES_MAX 3
#define TRBL_TOP 0
#define TRBL_RIGHT 1
#define TRBL_BOTTOM 2
#define TRBL_LEFT 3
#define TRBL_RECORDS_MAX CUBES_MAX*FACES_MAX // number of faces total

// ABI global variables
new abi_cubeN = 0;
new abi_TRBL[TRBL_RECORDS_MAX][2]; // TRBL neighbors cubeN,faceN => top(cubeN,faceN),right(cubeN,faceN),bottom(cubeN,faceN),left(cubeN,faceN)

// ABI helpers
#if defined CUBIOS_EMULATOR
abi_LogRcvPkt(const pkt[], size, const src[])
{
  printf("[%s] rcv pkt[%d]: ", src, size);
  for(new abi_i=0; abi_i<size; abi_i++) printf(" %02x", abi_ByteN(pkt, abi_i));
  printf("\n");
}

abi_LogSndPkt(const pkt[], size, const cubeN)
{
  printf("[127.0.0.1:%d] snd pkt[%d]: ", PAWN_PORT_BASE+cubeN, size);
  for(new abi_i=0; abi_i<size; abi_i++) printf(" %02x", abi_ByteN(pkt, abi_i));
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

abi_ByteN(const arr[], const n)
{
  return ((arr[n/4] >> (8*(n%4))) & 0xFF);
}

abi_TRBL_Deserialize(const pkt[])
{
  new n_r = abi_ByteN(pkt, 1); // number of records passed in the pkt
  new rb;
  for(new r=0; r<TRBL_RECORDS_MAX; r++)
  {
    
    if(r < n_r)
    {
      // store record
      rb = 2+r*6; // record base offset
      abi_TRBL[r][0] = (abi_ByteN(pkt, rb+0) << 24) | (abi_ByteN(pkt, rb+1) << 16) | (abi_ByteN(pkt, rb+2) << 8) | abi_ByteN(pkt, rb+3); // cubeN, faceN, topCubeN, topFaceN
      abi_TRBL[r][1] = (abi_ByteN(pkt, rb+4) << 24) | (abi_ByteN(pkt, rb+5) << 16) | 0xFFFF; // leftCubeN, leftFaceN, <TRBL record padding 0xFFFF>
    }
    else
    {
      // fill rest with FFs
      abi_TRBL[r][0] = 0xFFFFFFFF;
      abi_TRBL[r][1] = 0xFFFFFFFF;
    }
  }

}

abi_TRBL_FindRecordIndex(const _cubeN, const _faceN)
{
  for(new idx=0; idx<TRBL_RECORDS_MAX; idx++) if((abi_TRBL[idx][0] >> 16) == ((_cubeN << 8) | (_faceN))) return idx;
  return TRBL_RECORDS_MAX; // not found
}


abi_topCubeN(const _idx)
{
  return (abi_TRBL[_idx][0] >> 8) & 0xFF;
}

abi_topFaceN(const _idx)
{
  return (abi_TRBL[_idx][0] >> 0) & 0xFF;
}

abi_rightCubeN(const _idx)
{
  return abi_cubeN; // always same cube
}

abi_rightFaceN(const _idx)
{
  new screen = ((abi_TRBL[_idx][0] >> 16) & 0xFF); // screen for which we look screen @ right
  return ((screen == 0) ? 2 : ((screen == 1) ? 0 : 1));
}

abi_bottomCubeN(const _idx)
{
  return abi_cubeN; // always same cube
}

abi_bottomFaceN(const _idx)
{
  new screen = ((abi_TRBL[_idx][0] >> 16) & 0xFF); // screen for which we look screen @ bottom
  return ((screen == 0) ? 1 : ((screen == 1) ? 2 : 0));
}

abi_leftCubeN(const _idx)
{
  return (abi_TRBL[_idx][1] >> 24) & 0xFF;
}

abi_leftFaceN(const _idx)
{
  return (abi_TRBL[_idx][1] >> 16) & 0xFF;
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
