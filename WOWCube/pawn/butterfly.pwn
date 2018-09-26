#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"
forward run(const pkt[], size, const src[]); // public Pawn function seen from C

#define TOP_NEIGHBOR_FACE_ANGLE 270
#define RIGHT_NEIGHBOR_FACE_ANGLE 90
#define BOTTOM_NEIGHBOR_FACE_ANGLE 270
#define LEFT_NEIGHBOR_FACE_ANGLE 90

#define BUTTERFLY 14
#define COUNT_FLY 3
#define BLANK 0
#define FIGURES 1

new flys=0;
new sign=1;
//angles = 180 & 270 
new const left_figures[FIGURES] = [14];
//angles = 0 & 90
new const right_figures[FIGURES] = [18];
/*
new const level[CUBES_MAX][FACES_MAX][2] = [ // [2] - 1st - resID, 2nd - rotation angle
  [ [14, 180], [ 0,   0], [ 0,   0] ], // cube0
  [ [18,  90], [14, 180], [ 0,   0] ], // cube1
  [ [ 0,   0], [ 0,   0], [ 0,   0] ], // cube2
  [ [ 0,   0], [ 0,   0], [ 0,   0] ], // cube3
  [ [ 0,   0], [ 0,   0], [18,  90] ], // cube4
  [ [ 0,   0], [ 0,   0], [ 0,   0] ], // cube5
  [ [ 0,   0], [ 0,   0], [ 0,   0] ], // cube6
  [ [ 0,   0], [ 0,   0], [ 0,   0] ]  // cube7
];*/

new const level[CUBES_MAX][FACES_MAX][2] = [ // [2] - 1st - resID, 2nd - rotation angle
  [ [14, 180], [ 0,   0], [ 0,   0] ], // cube0
  [ [18,  90], [14, 180], [ 0,   0] ], // cube1
  [ [ 0,   0], [ 0,   0], [14, 270] ], // cube2
  [ [ 0,   0], [ 0,   0], [14, 270] ], // cube3
  [ [ 0,   0], [ 0,   0], [18,  90] ], // cube4
  [ [ 0,   0], [ 0,   0], [ 0,   0] ], // cube5
  [ [ 0,   0], [18,   0], [ 0,   0] ], // cube6
  [ [ 0,   0], [18,   0], [ 0,   0] ]  // cube7
];
isLeftFure(const figure)
{
  for(new figureN=0; figureN<FIGURES; figureN++)
    if (figure == left_figures[figureN])
      return 1;
  return 0;
}
isRightFure(const figure)
{
  for(new figureN=0; figureN<FIGURES; figureN++)
    if (figure == right_figures[figureN])
      return 1;
  return 0;
}
onTick()
{
  new thisCubeN = abi_cubeN;
  new thisFaceN = 0;
  new thisFigure = 0;
  new thisFigureAngle = 0;
  new neighborCubeN = 0xFF;
  new neighborFaceN = 0xFF;
  new neighborFigure = 0;
  new neighborFigureAngle = 0;
  new isDraw;

  for(thisFaceN=0; thisFaceN<FACES_MAX; thisFaceN++)
  {
    isDraw=0;
    thisFigure = level[thisCubeN][thisFaceN][0];
    thisFigureAngle = level[thisCubeN][thisFaceN][1];
    new idx = abi_TRBL_FindRecordIndex(thisCubeN, thisFaceN);
    if(idx >= TRBL_RECORDS_MAX) continue; // TRBL record not found!

    abi_CMD_FILL(0,0,0);
    
    if (isLeftFure(thisFigure))
    {
      if (thisFigureAngle==180)
      {
        neighborCubeN = abi_leftCubeN(idx);
        neighborFaceN = abi_leftFaceN(idx);
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          if ((neighborFigure!=BLANK) && (isRightFure(neighborFigure) && (neighborFigureAngle==90)))
            isDraw=flys;
        }
      }
      else if (thisFigureAngle==270)
      {
        neighborCubeN = abi_topCubeN(idx);
        neighborFaceN = abi_topFaceN(idx);
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          if ((neighborFigure!=BLANK) && (isRightFure(neighborFigure) && (neighborFigureAngle==0)))
            isDraw=flys;

        }
      }
    }
    else if (isRightFure(thisFigure))
    {
      if (thisFigureAngle==0)
      {
        neighborCubeN = abi_leftCubeN(idx);
        neighborFaceN = abi_leftFaceN(idx);
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          if ((neighborFigure!=BLANK) && (isLeftFure(neighborFigure) && (neighborFigureAngle==270)))
            isDraw=flys;
        }
      }
      else if (thisFigureAngle==90)
      {
        neighborCubeN = abi_topCubeN(idx);
        neighborFaceN = abi_topFaceN(idx);
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          if ((neighborFigure!=BLANK) && (isLeftFure(neighborFigure) && (neighborFigureAngle==180)))
            isDraw=flys;
        }
      }
    }
    
    if (thisFigure!=BLANK)
    {
      if (isLeftFure(thisFigure))
        switch(thisFigureAngle)
        {
          case   0: {abi_CMD_BITMAP(thisFigure+isDraw, 240-(134/2-isDraw*9/2), 120, thisFigureAngle); }
          case  90: {abi_CMD_BITMAP(thisFigure+isDraw, 120, 134/2-isDraw*9/2, thisFigureAngle); }
          case 180: {abi_CMD_BITMAP(thisFigure+isDraw, 134/2-isDraw*9/2, 120, thisFigureAngle); }
          case 270: {abi_CMD_BITMAP(thisFigure+isDraw, 120, 240-(134/2-isDraw*9/2), thisFigureAngle); }
        }
      else if (isRightFure(thisFigure))
      switch(thisFigureAngle)
        {
          case   0: {abi_CMD_BITMAP(thisFigure+isDraw, 134/2-isDraw*9/2, 120, thisFigureAngle); }
          case  90: {abi_CMD_BITMAP(thisFigure+isDraw, 120, 240-(134/2-isDraw*9/2), thisFigureAngle); }
          case 180: {abi_CMD_BITMAP(thisFigure+isDraw, 240-(134/2-isDraw*9/2), 120, thisFigureAngle); }
          case 270: {abi_CMD_BITMAP(thisFigure+isDraw, 120, 134/2-isDraw*9/2, thisFigureAngle); }
        }
    }
    printf("face=%d flys=%d\n",thisFaceN,flys);
    abi_CMD_REDRAW(thisFaceN); // redraw face frame buffer
  }
  flys=flys + sign;
  if(flys == 0) 
    sign = 1;
  if (flys == COUNT_FLY)
    sign = -1;
}
public run(const pkt[], size, const src[]) // public Pawn function seen from C
{
  switch(abi_ByteN(pkt, 0))
  {
    case CMD_TICK:
    {
      onTick();
    }
    case CMD_GEO:
    {
      abi_TRBL_Deserialize(pkt);
    }
  }
}

main()
{
  new opt{100};
  argindex(0, opt);
  abi_cubeN = strval(opt);
  printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
  listenport(PAWN_PORT_BASE+abi_cubeN);
}