#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"
//#pragma dynamic 100

forward run(const pkt[], size, const src[]) // public Pawn function seen from C

// TODO: put your Game logic here
#define PIPES_BASE 0
#define STEAM_BASE 16
#define PIPES_COUNT 16
#define STEAM_COUNT 9
#define COMPLETED 52
#define NUMBERS 57
#define DIGIT_WIDTH 22
#define COLON 10
#define score_base 1000
#define score_per_move 100
#define score_per_sec 10
#define MOVES_BASE 20
#define SEC_BASE 120

new draw_steams[FACES_PER_CUBE];//Check to draw steam
new steam_frame[FACES_PER_CUBE][RIBS_PER_CUBE];//resID of steam to draw
new steam_angle[FACES_PER_CUBE];
new draw_connectors[FACES_PER_CUBE];//resID of connectors to draw
new pipesResIDRotated[CUBES_MAX][FACES_PER_CUBE]; // Game Field
new pipesResIDRotatedForPipes[CUBES_MAX][FACES_PER_CUBE]; // Game Field
new Boolen:level_completed;
new moves;
new score;
new times;

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
rotateFigureBitwise(figure, _angle)
{
  new r = figure;
  
  switch(_angle)
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
rotateFigureBitwisePipes(figure, _angle)
{
  new r = figure;
  
  switch(_angle)
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
drawInterConnector(_resID,_faceN)
{
  new x,y,angle;
  abi_FacePositionAtProjection(abi_cubeN, _faceN, x, y, angle);
  new resID = rotateFigureBitwise(_resID, abi_pam[x][y]);
  switch(resID)
  {
    case 8: { abi_CMD_BITMAP(resID, 240/2-120/2, 0, 0);} // top 1000
    case 4: { abi_CMD_BITMAP(resID, 240-32, 240/2-120/2, 0);} // right 0100
    case 2: { abi_CMD_BITMAP(resID, 240/2-120/2, 240-32, 0);} // bottom 0010
    case 1: { abi_CMD_BITMAP(resID, 0, 240/2-120/2, 0);} // left 0001
  }
}
isFace(_x, _y) // is face in Projection Matrix is out-of-bound or empty field or normal cube's face
{
  if((_x < 0) || (_x >= PROJECTION_MAX_X)) return 0;
  if((_y < 0) || (_y >= PROJECTION_MAX_Y)) return 0;
  if((abi_pm[_x][_y][0] == 0xFF) || (abi_pm[_x][_y][1] == 0xFF)) return 0;
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
hasSteamAndConn(figure, shift)
{
  return((figure >> shift) & 0x1);
}
reCalcFigure()
{
  new faceN; //counter faces
  new cubeN; // counter cubios
  new x; // projection X
  new y; // projection Y
  new angle; // angle rotation
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
      abi_InitialFacePositionAtProjection(cubeN, faceN, x, y, angle);
      pipesResIDRotated[cubeN][faceN] = rotateFigureBitwise(curr_level[x][y], angle);
      abi_FacePositionAtProjection(cubeN, faceN, x_real, y_real, a_real);
      pipesResIDRotatedForPipes[cubeN][faceN] = rotateFigureBitwisePipes(curr_level[x][y], angle-a_real);
      //
      if (cubeN==abi_cubeN)
        steam_angle[faceN]=a_real;
    }
  }
}

drawPipesAndConnectors()
{
  new faceN; //counter faces
  new cubeN; // counter cubios
  new x; // projection X
  new y; // projection Y
  new angle; // angle rotation
  new thisFigure = 0;
  new compareFigure = 0;
  level_completed=true;
  for(cubeN=0;cubeN<CUBES_MAX;cubeN++)
  {
    for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
    {
      //get the coordinates in the matrix abi_pm
      abi_FacePositionAtProjection(cubeN, faceN, x, y, angle);
      thisFigure = pipesResIDRotatedForPipes[cubeN][faceN];
      //let's draw the first layer - pipes
      if  (cubeN == abi_cubeN)
      {
        draw_steams[faceN]=0;
        draw_connectors[faceN]=0;
      }
      //calculate the location of the connectors and draw them in frame_buffer
      if (isFace(x, y))
      {
        if((x==0 || !isFace(x-1,y)) && hasLeftPipe(thisFigure) && (cubeN == abi_cubeN)) 
          draw_connectors[faceN]+=1;//rotateFigureBitwise(1, abi_pam[x][y]);
          //drawInterPipesConnector(x, y, 1);
        if((y==0 || !isFace(x,y-1)) && hasBottomPipe(thisFigure) && (cubeN == abi_cubeN)) 
          draw_connectors[faceN]+=2;//rotateFigureBitwise(2, abi_pam[x][y]);
          //drawInterPipesConnector(x, y, 2);
      }
      //Check compare figure, but draw only on this cube
      if (isFace(x,y))
      {
        if (isFace(x,y+1))//Check Top figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y+1][0]][abi_pm[x][y+1][1]];
          if (hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=8;//rotateFigureBitwise(8, abi_pam[x][y]);
            //drawInterPipesConnector(x, y, 8); // 1000 = 8 = top pipe connector
          if (!hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_steams[abi_pm[x][y][1]]+=8;
          if (!hasTopPipe(thisFigure) && (hasBottomPipe(compareFigure)))
            level_completed=false;
        }
        else
        {
          if (hasTopPipe(thisFigure) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=8;//rotateFigureBitwise(8, abi_pam[x][y]);
            //drawInterPipesConnector(x, y, 8); // 1000 = 8 = top pipe connector
        }
      
        if (y>0 && isFace(x,y-1))//Check Bottom figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x][y-1][0]][abi_pm[x][y-1][1]];
          if (hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=2;//rotateFigureBitwise(2, abi_pam[x][y]);
            //drawInterPipesConnector(x, y, 2); // 0010 = 2 = bottom pipe connector
          if (!hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_steams[abi_pm[x][y][1]]+=2;
          if (!hasBottomPipe(thisFigure) && (hasTopPipe(compareFigure)))
            level_completed=false;
        }
        if (isFace(x+1,y))//Check Right figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x+1][y][0]][abi_pm[x+1][y][1]];
          if (hasRightPipe(thisFigure) && hasLeftPipe(compareFigure) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=4;//rotateFigureBitwise(4, abi_pam[x][y]);
            //drawInterPipesConnector(x,y,4); // 0100 = 4 = rigth pipe connector
          if (!hasRightPipe(thisFigure) && hasLeftPipe(compareFigure) && (cubeN == abi_cubeN))
            draw_steams[abi_pm[x][y][1]]+=4;
          if (!hasRightPipe(thisFigure) && hasLeftPipe(compareFigure))
            level_completed=false;
        }
        else
        {
          if (hasRightPipe(thisFigure) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=4;//rotateFigureBitwise(4, abi_pam[x][y]);
            //drawInterPipesConnector(x,y,4); // 0100 = 4 = rigth pipe connector
        }
        if (x>0 && isFace(x-1,y))//Check Left figure
        {
          compareFigure = pipesResIDRotatedForPipes[abi_pm[x-1][y][0]][abi_pm[x-1][y][1]];
          if (hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_connectors[faceN]+=1;//rotateFigureBitwise(1, abi_pam[x][y]);
            //drawInterPipesConnector(x, y, 1); // 0001 = 1 = left pipe connector
          if (!hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)) && (cubeN == abi_cubeN))
            draw_steams[abi_pm[x][y][1]]+=1;
          if (!hasLeftPipe(thisFigure) && (hasRightPipe(compareFigure)))
            level_completed=false;
        }
      }
    }
  }
  //drawing all figures
  for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
  {
    abi_CMD_BITMAP(pipesResIDRotated[abi_cubeN][faceN], 0, 0, 0);
    drawSteam(faceN);
    if (level_completed==true)
    {
      abi_CMD_BITMAP(COMPLETED, 0, 0, 0);
      abi_FacePositionAtProjection(abi_cubeN, faceN, x, y, angle);
      //logo
      if ((x-(x/2)*2==0) && (y-(y/2)*2!=0))
      {
        abi_CMD_BITMAP(COMPLETED+1, 0, 0, 0);
      }
      //time
      if ((x-(x/2)*2==0) && (y-(y/2)*2==0))
      {
        draw_results(times/10,2);
        //14x49
        abi_CMD_BITMAP(COMPLETED+4, 180-14, 120-49/2, 0);
      }
      //movies
      if ((x-(x/2)*2!=0) && (y-(y/2)*2==0))
      {
        draw_results(moves,3);
        //67x15
        abi_CMD_BITMAP(COMPLETED+2, 120-67/2, 180-15, 0);
      }
      //score
      if ((x-(x/2)*2!=0) && (y-(y/2)*2!=0))
      {
        score = score_base + (MOVES_BASE-moves)*score_per_move + (SEC_BASE - times/10)*score_per_sec;
        if(score < 0)
          score = 0;
        draw_results(score,1);
        //15x78
        abi_CMD_BITMAP(COMPLETED+3, 240-180-2, 120-78/2, 0);
      }
      
    }
    abi_CMD_REDRAW(faceN);
  }
}
draw_results(number, side)
{
  new range;
  new digit;
  new temp;
  new power;
  new width;
  if (number<10)
    {range=1;power=10;}
  else if (number<100)
    {range=2;power=100;}
  else if (number<1000)
    {range=3;power=1000;}
  else 
    {range=4;power=10000;}

  width=120-DIGIT_WIDTH*range/2-(range-1);
  if (side==2)
  {
    range=4;
    power=10000;
    width=120+DIGIT_WIDTH*(range-1)/2+range;
  }
  for(new x=0;x<range;x++)
  {
    temp=number/power;
    power/=10;
    digit=number/power;
    digit-=temp*10;
    switch(side)
    {
      case 1:{abi_CMD_BITMAP_CLIP(NUMBERS, 240-100-12, width, 0, digit*DIGIT_WIDTH, 32, DIGIT_WIDTH, 0); width+=DIGIT_WIDTH+2;}
      case 2:
            {
              if (x==2)
                {abi_CMD_BITMAP_CLIP(NUMBERS+2, 100-DIGIT_WIDTH, width, 0, 256-(COLON+1)*DIGIT_WIDTH, 32, DIGIT_WIDTH, 0); width-=DIGIT_WIDTH+2;}
              abi_CMD_BITMAP_CLIP(NUMBERS+2, 100-DIGIT_WIDTH, width, 0, 256-(digit+1)*DIGIT_WIDTH, 32, DIGIT_WIDTH, 0); width-=DIGIT_WIDTH+2;
            }
      case 3:{abi_CMD_BITMAP_CLIP(NUMBERS+1, width, 100-DIGIT_WIDTH, digit*DIGIT_WIDTH, 0, DIGIT_WIDTH, 32, 0); width+=DIGIT_WIDTH+2;}
    }
    
  }
}
//get coordinates for drawing Steams relative to ribs
getSteamsCoord(_faceN, ribN)
{
  switch (ribN)
  {
    case 0:
    {
      switch(steam_angle[_faceN])
      {
        case 270: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[_faceN][ribN], 240/2-120/2,           0, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[_faceN][ribN],         120,       120/2, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,         120, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[_faceN][ribN],           0,       120/2, 0);} 
      }
    }
    case 1:
    {
      switch(steam_angle[_faceN])
      {
        case 270: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[_faceN][ribN],           0,       120/2, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,           0, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[_faceN][ribN],         120,       120/2, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,         120, 0);} 
      }
    }
    case 2:
    {
      switch(steam_angle[_faceN])
      {
        case 270: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,         120, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[_faceN][ribN],           0,       120/2, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[_faceN][ribN], 240/2-120/2,           0, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[_faceN][ribN],         120,       120/2, 0);} 
      }
    }
    case 3:
    {
      switch(steam_angle[_faceN])
      {
        case 270: {abi_CMD_BITMAP(STEAM_BASE + 0*STEAM_COUNT + steam_frame[_faceN][ribN],         120,       120/2, 0);}
        case 180: {abi_CMD_BITMAP(STEAM_BASE + 1*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,         120, 0);}
        case  90: {abi_CMD_BITMAP(STEAM_BASE + 2*STEAM_COUNT + steam_frame[_faceN][ribN],           0, 240/2-120/2, 0);}
        case   0: {abi_CMD_BITMAP(STEAM_BASE + 3*STEAM_COUNT + steam_frame[_faceN][ribN],       120/2,           0, 0);} 
      }
    }
  }
}
drawSteam(_faceN)
{
  for(new ribN=0; ribN<RIBS_PER_CUBE; ribN++)
  {
    if (steam_frame[_faceN][ribN]==STEAM_COUNT)
      steam_frame[_faceN][ribN]=0;
    if (steam_frame[_faceN][ribN]==0 && hasSteamAndConn(draw_steams[_faceN],ribN))
      steam_frame[_faceN][ribN]=1;
    if (steam_frame[_faceN][ribN]==5 && hasSteamAndConn(draw_steams[_faceN],ribN))
      steam_frame[_faceN][ribN]=3;
    if (hasSteamAndConn(draw_connectors[_faceN],ribN))
      drawInterConnector(1<<ribN,_faceN);

    if (steam_frame[_faceN][ribN]>0)
    {
      getSteamsCoord(_faceN, ribN);
      steam_frame[_faceN][ribN]++;
    }
  }
}
onTick()
{
  drawPipesAndConnectors();
  if (level_completed==false)
    times+=1;
}
onCubeAttach()
{
  moves++;
  //Recalculate the positions of the pipes
  reCalcFigure();
  drawPipesAndConnectors();
  
  //create leveling
  /*
  for(new cubeN=0; cubeN<CUBES_MAX; cubeN++)
    for(new faceN=0; faceN<FACES_PER_CUBE; faceN++)
      printf("cubeN=%d faceN=%d Figure=%d\n",cubeN,faceN,pipesResIDRotatedForPipes[cubeN][faceN]);
  */
}
onCubeDetach()
{
  for(new faceN=0; faceN<FACES_PER_CUBE; faceN++)
  { 
    draw_steams[faceN]=0;
  }
  if (level_completed==true)
    set_level();
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
  moves=-1;
  times=0;
}
main()
{
  moves=0;
  set_level();
  new opt{100}
  argindex(0, opt);
  abi_cubeN = strval(opt);
  printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
  listenport(PAWN_PORT_BASE+abi_cubeN);
}
