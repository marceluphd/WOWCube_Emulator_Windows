#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"
//#pragma dynamic 100

forward run(const pkt[], size, const src[]) // public Pawn function seen from C

// TODO: put your Game logic here
#define PIPES_BASE 0
#define STEAM_BASE 16
#define PIPES_COUNT 16
#define STEAM_COUNT 9
#define MAX_LEVELS 5
#define COMPLETED 52

new steam_draw [FACES_PER_CUBE];//Check to draw steam
new steam_frame[FACES_PER_CUBE][RIBS_PER_CUBE];//resID of steam to draw
new steam_angle[FACES_PER_CUBE];
new steam_count_base[RIBS_PER_CUBE];
new pipesResIDRotated[CUBES_MAX][FACES_PER_CUBE]; // Game Field
new pipesResIDRotatedForPipes[CUBES_MAX][FACES_PER_CUBE]; // Game Field
new steams_counter;
new timer_completed;
new const timer_completed_max=10;

new faceN, cubeN;

new const level1[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  3,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  9,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  9,  3,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];
new const level2[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0, 15,  0,  0,  0],
  [ 0,  9,  3,  0,  0,  6],
  [ 0,  0,  0,  0,  0,  3],
  [ 0,  0,  0,  6,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];
new const level3[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0, 12,  0,  0],
  [ 0,  0,  0,  3,  9,  0],
  [ 0,  9,  7,  0, 13,  5],
  [ 0,  0,  9, 12,  0,  0],
  [ 0,  0,  0,  9,  0,  0],
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];
new const level4[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0,  5, 12,  0,  0],
  [ 0,  0,  9,  3,  9,  0],
  [ 6,  0,  0,  0, 12,  0],
  [ 0,  0,  0, 10,  0,  0],
  [ 0,  0,  3,  0,  0,  0],
  [ 0,  0,  6,  0,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];
new const level5[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  0,  0,  0,  0],
  [ 0,  0, 12,  0,  0,  0],
  [ 0, 12, 15,  0,  0,  0],
  [12,  6, 12,  0,  0,  6],
  [ 0,  0, 15,  0,  0,  0],
  [ 0,  0,  7, 13,  0,  0],
  [ 0,  0,  9,  3,  0,  0],
  [ 0,  0,  0,  0,  0,  0]
];
new curr_level[PROJECTION_MAX_X][PROJECTION_MAX_Y];
new level=0;
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
rotateFigureBitwisePipes(figure, angle)
{
  new r = figure;
  
  switch(angle)
  {
    case  -90: { r = ((figure << 3) & 0xF) | (figure >> 1 & 0xF); } // 90
    case -180: { r = ((figure << 2) & 0xF) | (figure >> 2 & 0xF); } // 180
    case -270: { r = ((figure << 1) & 0xF) | (figure >> 3 & 0xF); } // 270
    case   90: { r = ((figure << 1) & 0xF) | (figure >> 3 & 0xF); } // -90
    case  180: { r = ((figure << 2) & 0xF) | (figure >> 2 & 0xF); } // -180
    case  270: { r = ((figure << 3) & 0xF) | (figure >> 1 & 0xF); } // -270
  }
  return r;
}
drawInterPipesConnector(x, y, _resID)
{
  new resID = rotateFigureBitwise(_resID, abi_pam[x][y]);
  switch(resID)
  {
    case 8: { abi_CMD_BITMAP(resID, 240/2-120/2, 0, 0);} // top 1000
    case 4: { abi_CMD_BITMAP(resID, 240-32, 240/2-120/2, 0);} // right 0100
    case 2: { abi_CMD_BITMAP(resID, 240/2-120/2, 240-32, 0);} // bottom 0010
    case 1: { abi_CMD_BITMAP(resID, 0, 240/2-120/2, 0);} // left 0001
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
hasSteam(figure, shift)
{
  return((figure >> shift) & 0x1);
}
reCalcFigure()
{
  new x = 0; // projection X
  new y = 0; // projection Y
  new a = 0; // projection Angle (face rotated at)
  new a_real = 0;
  new x_real = 0;
  new y_real = 0; //the correct angle for the planar view
  //I know that calculate all the game field is quite NOT RATIONAL
  //But otherwise we will not know the figures on adjacent cubes
  for(cubeN=0; cubeN<CUBES_MAX; cubeN++)
  {
    //printf("CubeN=%d\n",cubeN);
    for(faceN=0; faceN<FACES_PER_CUBE; faceN++)
    {
      // calculate faces and rotated bitmaps positions
      abi_InitialFacePositionAtProjection(cubeN, faceN, x, y, a);
      pipesResIDRotated[cubeN][faceN] = rotateFigureBitwise(curr_level[x][y], a);
      abi_FacePositionAtProjection(cubeN, faceN, x_real, y_real, a_real);
      pipesResIDRotatedForPipes[cubeN][faceN] = rotateFigureBitwisePipes(curr_level[x][y], a-a_real);
      //
      if (cubeN==abi_cubeN)
        steam_angle[faceN]=a_real;
    }
  }
}
drawPipesAndConnectors(faceN)
{
  new thisFigure = 0;
  new compareFigure = 0;
  cubeN = abi_cubeN;
  new x = 0; // projection X
  new y = 0; // projection Y
  new angle = 0;
  //get the coordinates in the matrix abi_pm
  abi_FacePositionAtProjection(cubeN, faceN, x, y, angle);
  thisFigure = pipesResIDRotatedForPipes[cubeN][faceN];
  //let's draw the first layer - pipes
  abi_CMD_BITMAP(pipesResIDRotated[cubeN][faceN], 0, 0, 0);
  //calculate the location of the connectors and draw them in frame_buffer
  if (isFace(x, y))
  {
    if((x==0 || !isFace(x-1,y)) && hasLeftPipe(thisFigure)) drawInterPipesConnector(x, y, 1);
    if((y==0 || !isFace(x,y-1)) && hasBottomPipe(thisFigure)) drawInterPipesConnector(x, y, 2);
  }
  //Check compare figure, but draw only on this cube
  if (isFace(x,y))
  {
    if (isFace(x,y+1))//Check Top figure
    {
      compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y+1][0]][abi_pm[x][y+1][1]];
      if (hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)))
        drawInterPipesConnector(x, y, 8); // 1000 = 8 = top pipe connector
        if (!hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)))
          steam_draw[abi_pm[x][y][1]]+=8;
    }
    else
    {
      if (hasTopPipe(thisFigure))
        drawInterPipesConnector(x, y, 8); // 1000 = 8 = top pipe connector
    }
  
    if (y>0 && isFace(x,y-1))//Check Bottom figure
    {
      compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y-1][0]][abi_pm[x][y-1][1]];
      if (hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)))
        drawInterPipesConnector(x, y, 2); // 0010 = 2 = bottom pipe connector
      if (!hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)))
        steam_draw[abi_pm[x][y][1]]+=2;
    }
    if (isFace(x+1,y))//Check Right figure
    {
      compareFigure = pipesResIDRotatedForPipes[abi_pm[x+1][y][0]][abi_pm[x+1][y][1]];
      if (hasRightPipe(thisFigure) && hasLeftPipe(compareFigure))
        drawInterPipesConnector(x,y,4); // 0100 = 4 = rigth pipe connector
      if (!hasRightPipe(thisFigure) && hasLeftPipe(compareFigure))
        steam_draw[abi_pm[x][y][1]]+=4;
    }
    else
    {
      if (hasRightPipe(thisFigure))
        drawInterPipesConnector(x,y,4); // 0100 = 4 = rigth pipe connector
    }
    if (x>0 && isFace(x-1,y))//Check Left figure
    {
      compareFigure = pipesResIDRotatedForPipes[abi_pm[x-1][y][0]][abi_pm[x-1][y][1]];
      if (hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)))
        drawInterPipesConnector(x, y, 1); // 0001 = 1 = left pipe connector
      if (!hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)))
        steam_draw[abi_pm[x][y][1]]+=1;
    }
  }
  /*
  thisFigure = pipesResIDRotatedForPipes[abi_pm[x][y][0]][abi_pm[x][y][1]];
  //testing rendering of all connectors regardless of adjacent ones Fases
  if (isFace(x,y))
  {
    abi_CMD_BITMAP(pipesResIDRotated[abi_pm[x][y][0]][abi_pm[x][y][1]], 0, 0, 0);
    printf("cub=%d face=%d fig=%d r=%d l=%d t=%d b=%d\n",abi_cubeN,abi_pm[x][y][1],thisFigure,hasRightPipe(thisFigure),hasLeftPipe(thisFigure),hasTopPipe(thisFigure),hasBottomPipe(thisFigure));
    if (hasRightPipe(thisFigure)==1)
      drawInterPipesConnector(x, y, 4); // 0100 = 4 = right pipe connector
    if (hasLeftPipe(thisFigure)==1)
      drawInterPipesConnector(x, y, 1); // 0100 = 4 = right pipe connector
    if (hasTopPipe(thisFigure)==1)
      drawInterPipesConnector(x, y, 8); // 0100 = 4 = right pipe connector
    if (hasBottomPipe(thisFigure)==1)
      drawInterPipesConnector(x, y, 2); // 0100 = 4 = right pipe connector
  }/**/
}
CheckCompleted()
{
  new thisFigure = 0;
  new compareFigure = 0;
  new x = 0; // projection X
  new y = 0; // projection Y
  new angle = 0;
  steams_counter=0;
  for(cubeN=0;cubeN<CUBES_MAX;cubeN++)
  {

    for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
    {
      //get the coordinates in the matrix abi_pm
      abi_FacePositionAtProjection(cubeN, faceN, x, y, angle)
      thisFigure = pipesResIDRotatedForPipes[cubeN][faceN];
      //Check compare figure, but draw only on this cube
      if (isFace(x,y))
      {
        if (isFace(x,y+1))//Check Top figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y+1][0]][abi_pm[x][y+1][1]];
          if (!hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)))
          {
            steams_counter++;
            return;
          }
        }
        if (y>0 && isFace(x,y-1))//Check Bottom figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y-1][0]][abi_pm[x][y-1][1]];
          if (!hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)))
          {
            steams_counter++;
            return;
          }
        }
        if (isFace(x+1,y))//Check Right figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x+1][y][0]][abi_pm[x+1][y][1]];
          if (!hasRightPipe(thisFigure) && hasLeftPipe(compareFigure))
          {
            steams_counter++;
            return;
          }
        }
        if (x>0 && isFace(x-1,y))//Check Left figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x-1][y][0]][abi_pm[x-1][y][1]];
          if (!hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)))
          {
            steams_counter++;
            return;
          }
        }
      }
    }
  }
}
//get coordinates for drawing Steams relative to ribs
getSteamsCoord(faceN, ribN)
{
  switch (ribN)
  {
    case 0://abi_CMD_BITMAP(STEAM_BASE + steam_count_base[ribN]*STEAM_COUNT + steam_frame[faceN][ribN], steam_x[ribN], steam_y[ribN], 0);
    {
      switch(steam_angle[faceN])
      {/*
        case 270: {steam_count_base[ribN]=3; steam_x[ribN]=240/2-120/2; steam_y[ribN]=0;}
        case 180: {steam_count_base[ribN]=0; steam_x[ribN]=120; steam_y[ribN]=120/2;}
        case  90: {steam_count_base[ribN]=1; steam_x[ribN]=120/2; steam_y[ribN]=120;}
        case   0: {steam_count_base[ribN]=2; steam_x[ribN]=0; steam_y[ribN]=120/2;} */

        case 270: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[faceN][ribN], 240/2-120/2,     0, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[faceN][ribN],         120, 120/2, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,   120, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[faceN][ribN],           0, 120/2, 0);} 
      }
    }
    case 1:
    {
      switch(steam_angle[faceN])
      {/*
        case 270: {steam_count_base[ribN]=2; steam_x[ribN]=0; steam_y[ribN]=120/2;}
        case 180: {steam_count_base[ribN]=3; steam_x[ribN]=120/2; steam_y[ribN]=0;}
        case  90: {steam_count_base[ribN]=0; steam_x[ribN]=120; steam_y[ribN]=120/2;}
        case   0: {steam_count_base[ribN]=1; steam_x[ribN]=120/2; steam_y[ribN]=120;} */

        case 270: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[faceN][ribN],           0,       120/2, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,           0, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[faceN][ribN],         120,       120/2, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,         120, 0);} 
      }
    }
    case 2:
    {
      switch(steam_angle[faceN])
      {/*
        case 270: {steam_count_base[ribN]=1; steam_x[ribN]=120/2; steam_y[ribN]=120;}
        case 180: {steam_count_base[ribN]=2; steam_x[ribN]=0; steam_y[ribN]=120/2;}
        case  90: {steam_count_base[ribN]=3; steam_x[ribN]=240/2-120/2; steam_y[ribN]=0;}
        case   0: {steam_count_base[ribN]=0; steam_x[ribN]=120; steam_y[ribN]=120/2;} */

        case 270: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,         120, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[faceN][ribN],           0,       120/2, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[faceN][ribN], 240/2-120/2,           0, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[faceN][ribN],         120,       120/2, 0);} 
      }
    }
    case 3:
    {
      switch(steam_angle[faceN])
      {/*
        case 270: {steam_count_base[ribN]=0; steam_x[ribN]=120; steam_y[ribN]=120/2;}
        case 180: {steam_count_base[ribN]=1; steam_x[ribN]=120/2; steam_y[ribN]=120;}
        case  90: {steam_count_base[ribN]=2; steam_x[ribN]=0; steam_y[ribN]=240/2-120/2;}
        case   0: {steam_count_base[ribN]=3; steam_x[ribN]=120/2; steam_y[ribN]=0;} */

        case 270: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[faceN][ribN],         120,       120/2, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,         120, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[faceN][ribN],           0, 240/2-120/2, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[faceN][ribN],       120/2,           0, 0);} 
      }
    }
  }
}
drawSteam(faceN)
{
  for(new ribN=0; ribN<RIBS_PER_CUBE; ribN++)
  {
    if (steam_frame[faceN][ribN]==STEAM_COUNT)
      steam_frame[faceN][ribN]=0;
    if (steam_frame[faceN][ribN]==0 && hasSteam(steam_draw[faceN],ribN))
      steam_frame[faceN][ribN]=1;
    if (steam_frame[faceN][ribN]==5 && hasSteam(steam_draw[faceN],ribN))
      steam_frame[faceN][ribN]=3;
    steam_count_base[ribN]=ribN;

    if (steam_frame[faceN][ribN]>0)
    {
      getSteamsCoord(faceN, ribN);
      steam_frame[faceN][ribN]++;
    }
  }
}
onTick()
{
  
  for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
  {
    steam_draw[faceN]=0;
    //Draw pipes. Calculate the location of the connectors and steams. Draw connectors in frame_buffer
    drawPipesAndConnectors(faceN);
    //Draw steams in frame_buffer
    drawSteam(faceN);
    if (steams_counter==0)
    {
      abi_CMD_BITMAP(COMPLETED, 10, 100, 0) ;
    }
    //Draw frame_buffer in Face
    abi_CMD_REDRAW(faceN);
  }
  
  if ((timer_completed==0) && (steams_counter==0))
    timer_completed=0;
  if (steams_counter==0)
    timer_completed++;
  if ((timer_completed>=timer_completed_max) && (steams_counter==0))
  {
    set_level();
    reCalcFigure();
    CheckCompleted();
    steams_counter=1;
    timer_completed=0;
  }
}
onCubeAttach()
{
  steams_counter=0;
  //Recalculate the positions of the pipes
  reCalcFigure();
  CheckCompleted();
  for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
  {
    steam_draw[faceN]=0;
    drawPipesAndConnectors(faceN);
    abi_CMD_REDRAW(faceN);
  }
  /*
  //create leveling
  new cubeN;
  for(cubeN=0; cubeN<CUBES_MAX; cubeN++)
    for(faceN=0; faceN<FACES_PER_CUBE; faceN++)
      printf("cubeN=%d faceN=%d Figure=%d\n",cubeN,faceN,pipesResIDRotatedForPipes[cubeN][faceN]);
  */
}
onCubeDetach()
{
  for( faceN=0; faceN<FACES_PER_CUBE; faceN++)
  { 
    steam_draw[faceN]=0;
  }
}

public run(const pkt[], size, const src[]) // public Pawn function seen from C
{
  //abi_LogRcvPkt(pkt, size, src); // debug
  
  switch(abi_GetPktByte(pkt, 0))
  {
    case CMD_TICK:
    {
      //printf("[%s] CMD_TICK\n", src);
      onTick();
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
set_level()
{
  
  new x=0, y=0;
  switch(level)
    {
      case 0: {curr_level=level1;}
      case 1: {curr_level=level2;}
      case 2: {curr_level=level3;}
      case 3: {curr_level=level4;}
      case 4: {curr_level=level5;}
      case 5: {curr_level=level1; level=0;}
    }
    level++;
    printf("level=%d\n",level);
}
main()
{
  set_level();
  new opt{100}
  argindex(0, opt);
  abi_cubeN = strval(opt);
  printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
  listenport(PAWN_PORT_BASE+abi_cubeN);
}
