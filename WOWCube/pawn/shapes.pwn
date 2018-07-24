#define CUBIOS_EMULATOR
#include <float>
#define INITIAL_POS_RES_ID 124
#define INITIAL_BACK 0
#define GREEN_BACK 1
#define FACES_PER_PLANE 4
#include "cubios_abi.pwn"
forward run(const pkt[], size, const src[]) // public Pawn function seen from C

new shapesID[CUBES_MAX][FACES_PER_CUBE]; // Game Field
new initial = 0;

new back_pm[FACES_PER_CUBE]; // BACKGROUND's
new angles_rotate[FACES_PER_CUBE];
new const level[PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
  [ 0,  0,  1,  2,  0,  0],
  [ 0,  0,  4,  3,  0,  0],
  [ 8,  5,  9, 10, 13, 14],
  [ 7,  6, 12, 11, 16, 15],
  [ 0,  0, 17, 18,  0,  0],
  [ 0,  0, 20, 19,  0,  0],
  [ 0,  0, 21, 22,  0,  0],
  [ 0,  0, 24, 23,  0,  0]
];
CheckRules()
{
  new x = 0;
  new y = 0;
  new i=0;
  new j=0;
  new temp;
  new Figures[FACES_PER_PLANE];
  new Cubios[FACES_PER_PLANE];
  new Faces[FACES_PER_PLANE];
  for(x=0; x<PROJECTION_MAX_X;x+=2)
  {
    for(y=0; y<PROJECTION_MAX_Y;y+=2)
    {
      if (abi_pm[x][y][0] == 0xFF)
        continue;
      Cubios[0]=abi_pm[x][y][0];
      Cubios[1]=abi_pm[x+1][y][0];
      Cubios[2]=abi_pm[x][y+1][0];
      Cubios[3]=abi_pm[x+1][y+1][0];
      Faces[0]=abi_pm[x][y][1];
      Faces[1]=abi_pm[x+1][y][1];
      Faces[2]=abi_pm[x][y+1][1];
      Faces[3]=abi_pm[x+1][y+1][1];
      Figures[0]=shapesID[Cubios[0]][Faces[0]];
      Figures[1]=shapesID[Cubios[1]][Faces[1]];
      Figures[2]=shapesID[Cubios[2]][Faces[2]];
      Figures[3]=shapesID[Cubios[3]][Faces[3]];
      for (i = 0; i < FACES_PER_PLANE - 1; i++) 
        for (j = 0; j < FACES_PER_PLANE - i - 1; j++) 
          if (Figures[j] > Figures[j + 1])
          {
            temp = Figures[j];
            Figures[j] = Figures[j + 1];
            Figures[j + 1] = temp;
            temp = Cubios[j];
            Cubios[j] = Cubios[j + 1];
            Cubios[j + 1] = temp;
            temp = Faces[j];
            Faces[j] = Faces[j + 1];
            Faces[j + 1] = temp;
          }
      //4 faces have the equal images
      temp = Figures[FACES_PER_PLANE-1] / FACES_PER_PLANE;
      printf("temp=%d Fig0=%d\n",temp,Figures[FACES_PER_PLANE-1]);
      if ((temp * FACES_PER_PLANE == Figures[FACES_PER_PLANE-1]) && (Figures[FACES_PER_PLANE-1]-Figures[0]==FACES_PER_PLANE-1))
      {
          for(i=0;i<FACES_PER_PLANE;i++)
            if (Cubios[i]==abi_cubeN)
              back_pm[Faces[i]]=GREEN_BACK;
        continue;
      }
    }
  }
}
reCalcFigure()
{
  new cubeN = 0;
  new faceN = 0;
  new x = 0; // projection X
  new y = 0; // projection Y
  new a = 0; // projection Angle (face rotated at)
  for(cubeN=0; cubeN<CUBES_MAX; cubeN++)
  {
    for(faceN=0; faceN<FACES_PER_CUBE; faceN++)
    {
      abi_InitialFacePositionAtProjection(cubeN, faceN, x, y, a);
      shapesID[cubeN][faceN] = level[x][y];
      back_pm[faceN]=0;
    }
  }
}
DrawFace(faceN)
{
  new x=0;
  new y=0;
  new angle=0;
  abi_CMD_BITMAP_CLIP(INITIAL_POS_RES_ID, 0, 0, 240*back_pm[faceN], 0, 240, 240, 0);
  abi_InitialFacePositionAtProjection(abi_cubeN, faceN, x, y, angle);
  //abi_CMD_BITMAP(level[x][y]+INITIAL_POS_RES_ID, 0, 0, 0);
  if (back_pm[faceN]==INITIAL_BACK)
    angles_rotate[faceN] = random(FACES_PER_PLANE);
  else
    angles_rotate[faceN]=0;
  abi_CMD_BITMAP_CLIP(level[x][y]+INITIAL_POS_RES_ID, 0, 0, 240*angles_rotate[faceN], 0, 240, 240, 0);
}
onCubeAttach()
{
  new faceN;//counter for face
  reCalcFigure();
  CheckRules();
  
  for(faceN=0;faceN<FACES_PER_CUBE;faceN++)
  {
    DrawFace(faceN);
    abi_CMD_REDRAW(faceN);
  }
  return;
}
onCubeDetach()
{
  return;
}

public run(const pkt[], size, const src[]) // public Pawn function seen from C
{
  switch(abi_GetPktByte(pkt, 0))
  {
    case CMD_TICK:
    {
      //onTick();
    }

    case CMD_ATTACH:
    {
      abi_attached = 1;
      abi_DeserializePositonsMatrix(pkt);
      abi_LogPositionsMatrix(); // DEBUG
      onCubeAttach();
    }

    case CMD_DETACH:
    {
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