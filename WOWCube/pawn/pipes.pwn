 #include "cubios_abi.pwn"

// TODO: put your Game logic here
#define PIPES_BASE 0
#define STEAM_BASE 16
#define PIPES_COUNT 16
#define STEAM_COUNT 9

new const level[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0, 12,  6,  0,  0],
  [ 0, 12, 15, 11,  6,  0],
  [ 0,  9, 15, 14,  3,  0],
  [ 0,  0,  9,  3,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];

rotateFigureBitwise(figure, angle)
{
  new r = figure;
  
  switch(angle)
  {
    case  -90: { r = ((figure >> 1) & 0x7) | ((figure << 3) & 0x8); } // 90
    case -180: { r = ((figure >> 2) & 0x3) | ((figure << 2) & 0xC); } // 180
    case -270: { r = ((figure >> 3) & 0x1) | ((figure << 1) & 0xE); } // 270
    case   90: { r = ((figure << 1) & 0xE) | ((figure >> 3) & 0x1); } // -90
    case  180: { r = ((figure << 2) & 0xC) | ((figure >> 2) & 0x3); } // -180
    case  270: { r = ((figure << 3) & 0x8) | ((figure >> 1) & 0x7); } // -270
  }
  
  return r;
}

drawInterPipesConnector(x, y, _resID)
{
  new resID = rotateFigureBitwise(_resID, abi_pam[x][y]);
  //new cubeN = abi_pm[x][y][0];
  new faceN = abi_pm[x][y][1];

  switch(resID)
  {
    case 8: { abi_CMD_BITMAP(faceN, resID, 240/2-120/2, 0); } // top 1000
    case 4: { abi_CMD_BITMAP(faceN, resID, 240-32, 240/2-120/2); } // right 0100
    case 2: { abi_CMD_BITMAP(faceN, resID, 240/2-120/2, 240-32); } // bottom 0010
    case 1: { abi_CMD_BITMAP(faceN, resID, 0, 240/2-120/2); } // left 0001
  }
}

isFace(x, y) // is face in Projection Matrix is out-of-bound or empty field or normal cube's face
{
  if((x < 0) || (x >= PROJECTION_MAX_X)) return 0;
  if((y < 0) || (y >= PROJECTION_MAX_Y)) return 0;
  if((abi_pm[x][y][0] == 0xFF) || (abi_pm[x][y][1] == 0xFF)) return 0;
  return 1;
}

hasTopPipe(figure)
{
  return ((figure >> 3) & 0x1);
}

hasRightPipe(figure)
{
  return ((figure >> 2) & 0x1);
}

hasBottomPipe(figure)
{
  return ((figure >> 1) & 0x1);
}

hasLeftPipe(figure)
{
  return ((figure >> 0) & 0x1);
}

onCubeAttach()
{
  new cubeN = 0;
  new faceN = 0;
  new x = 0; // projection X
  new y = 0; // projection Y
  new a = 0; // projection Angle (face rotated at)
  new pipesResIDRotated[CUBES_MAX][FACES_PER_CUBE]; // Game Field
  new pipesResIDOriginal[CUBES_MAX][FACES_PER_CUBE];
  new thisFigure = 0;
  new compareFigure = 0;

  // I know that calculate all the game field is quite NOT RATIONAL :(
  for(cubeN=0; cubeN<CUBES_MAX; cubeN++)
    for(faceN=0; faceN<FACES_PER_CUBE; faceN++)
    {
      // calculate faces and rotated bitmaps positions
      abi_InitialFacePositionAtProjection(cubeN, faceN, x, y, a);
      pipesResIDOriginal[cubeN][faceN] = level[x][y];
      pipesResIDRotated[cubeN][faceN] = rotateFigureBitwise(level[x][y], a);
    }

  // Draw a part of level on this cube's face 0-2
  for(faceN=0; faceN<3; faceN++)
  {
    abi_CMD_BITMAP(faceN, pipesResIDRotated[abi_cubeN][faceN], 0, 0);
  }
  
  // Check if top or right neighbors are connected
  for(x=0; x<PROJECTION_MAX_X; x++)
  {
    for(y=0; y<PROJECTION_MAX_Y; y++)
    {
      if(abi_pm[x][y][0] != abi_cubeN) continue; // for this cube only!
      //if(0 == isFace(x, y)) continue; // no cube/face at this position matrix position!
      
      thisFigure = pipesResIDOriginal[abi_pm[x][y][0]][abi_pm[x][y][1]];
      
      /*if(isFace(x, y))
      {
        if((x==0 || !isFace(x-1,y)) && hasLeftPipe(thisFigure)) drawInterPipesConnector(x, y, 1);
        if((y==0 || !isFace(x,y-1)) && hasBottomPipe(thisFigure)) drawInterPipesConnector(x, y, 2);
      }*/
      
      if(isFace(x, y) && isFace(x+1, y)) // lookup right
      {
        compareFigure = pipesResIDOriginal[abi_pm[x+1][y][0]][abi_pm[x+1][y][1]];
        if(hasRightPipe(thisFigure) && hasLeftPipe(compareFigure))
          drawInterPipesConnector(x, y, 4); // 0100 = 4 = right pipe connector
      }
      /*else if(isFace(x, y))
      {
        if(hasRightPipe(thisFigure))
          drawInterPipesConnector(x, y, 4); // 0100 = 4 = right pipe connector
      }*/
      
      /*if(isFace(x, y) && isFace(x-1, y)) // lookup left
      {
        compareFigure = pipesResIDOriginal[abi_pm[x-1][y][0]][abi_pm[x-1][y][1]];
        if(hasLeftPipe(thisFigure) && hasRightPipe(compareFigure))
          drawInterPipesConnector(x, y, 1); // 0001 = 1 = left pipe connector
      }
      else if(isFace(x, y))
      {
        if(hasLeftPipe(thisFigure))
          drawInterPipesConnector(x, y, 1); // 0001 = 1 = left pipe connector
      }*/
    }
  }
}

onCubeDetach()
{
  //abi_CMD_FILL(0,255,0,0);
  //abi_CMD_FILL(1,0,255,0);
  //abi_CMD_FILL(2,0,0,255);
}

run(const pkt[], size, const src[])
{
  abi_LogRcvPkt(pkt, size, src); // debug

  switch(abi_GetPktByte(pkt, 0))
  {
    case CMD_PAWN_DEBUG:
    {
      printf("[%s] CMD_PAWN_DEBUG\n", src);
    }

    case CMD_TICK:
    {
      printf("[%s] CMD_TICK\n", src);
    }

    case CMD_ATTACH:
    {
      printf("[%s] CMD_ATTACH\n", src);
      abi_attached = 1;
      abi_DeserializePositonsMatrix(pkt);
      abi_LogPositionsMatrix(); // DEBUG
      onCubeAttach();
    }

    case CMD_DETACH:
    {
      printf("[%s] CMD_DETACH\n", src);
      abi_attached = 0;
      onCubeDetach();
    }
  }
}

main()
{
  new opt{100}
  argindex(0, opt);
  abi_cubeN = strval(opt);
  printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
  listenport(PAWN_PORT_BASE+abi_cubeN);
}
