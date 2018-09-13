#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"
forward run(const pkt[], size, const src[]); // public Pawn function seen from C

#define TOP_NEIGHBOR_FACE_ANGLE 270
#define RIGHT_NEIGHBOR_FACE_ANGLE 90
#define BOTTOM_NEIGHBOR_FACE_ANGLE 270
#define LEFT_NEIGHBOR_FACE_ANGLE 90

#define PIPE_I 0
#define PIPE_ANGLE 1
#define PIPE_T 2
#define PIPE_CROSS 3
#define PIPE_ANGLE_0 0
#define PIPE_ANGLE_90 1
#define PIPE_ANGLE_180 2
#define PIPE_ANGLE_270 3

#define STEAM_BASE 5
new steam_frame=0;

new const figures[5][4][4] = [ // 5 figures, 4 angles, 4 connectors places - 256 bytes
  [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]], // PADDING
  [[1,0,1,0], [0,1,0,1], [1,0,1,0], [0,1,0,1]], // PIPE_I
  [[0,1,1,0], [0,0,1,1], [1,0,0,1], [1,1,0,0]], // PIPE_ANGLE
  [[1,1,0,1], [1,1,1,0], [0,1,1,1], [1,0,1,1]], // PIPE_T
  [[1,1,1,1], [1,1,1,1], [1,1,1,1], [1,1,1,1]] // PIPE_CROSS
]

new const level[CUBES_MAX][FACES_MAX][2] = [ // [2] - 1st - resID, 2nd - rotation angle
  [ [1,0], [2,0], [3,0] ], // cube0
  [ [1,90], [1,90], [1,90] ], // cube1
  [ [2,0], [2,0], [2,0] ], // cube2
  [ [2,0], [2,0], [2,0] ], // cube3
  [ [2,0], [2,0], [2,0] ], // cube4
  [ [2,0], [2,0], [2,0] ], // cube5
  [ [2,0], [2,0], [2,0] ], // cube6
  [ [2,0], [2,0], [2,0] ]  // cube7
];

angle2pipeangle(const angle)
{
  if(angle == 90) return PIPE_ANGLE_90;
  else if(angle == 180) return PIPE_ANGLE_180;
  else if(angle == 270) return PIPE_ANGLE_270;
  else return PIPE_ANGLE_0;
}

public run(const pkt[], size, const src[]) // public Pawn function seen from C
{
  switch(abi_ByteN(pkt, 0))
  {
    case CMD_TICK:
    {
      new thisCubeN = abi_cubeN;
      new thisFaceN = 0;
      new thisFigure = 0;
      new thisFigureAngle = 0;
      new neighborCubeN = 0xFF;
      new neighborFaceN = 0xFF;
      new neighborFigure = 0;
      new neighborFigureAngle = 0;
      for(thisFaceN=0; thisFaceN<FACES_MAX; thisFaceN++)
      {
        thisFigure = level[thisCubeN][thisFaceN][0];
        thisFigureAngle = level[thisCubeN][thisFaceN][1];
        
        abi_CMD_FILL(0,0,0);
        abi_CMD_BITMAP(thisFigure, 120, 120, thisFigureAngle); // draw figure
        
        new idx = abi_TRBL_FindRecordIndex(thisCubeN, thisFaceN);
        if(idx >= TRBL_RECORDS_MAX) continue; // TRBL record not found!
        
        // Check TOP
        neighborCubeN = abi_topCubeN(idx);
        neighborFaceN = abi_topFaceN(idx);
        
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          
          // if neighbor face has pipe, but I have no
          if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_LEFT] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_TOP] == 0))
          {
            abi_CMD_BITMAP(STEAM_BASE+steam_frame, 120, 60, 0); // draw steam TOP
          }
          // if neighbor face has pipe and I also have
          else if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_LEFT] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_TOP] == 1))
          {
            abi_CMD_BITMAP(0, 120, 16, 180); // draw connector TOP
          }
        }
        
        // Check RIGHT
        neighborCubeN = abi_rightCubeN(idx);
        neighborFaceN = abi_rightFaceN(idx);
        
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          
          // if neighbor face has pipe, but I have no
          if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_BOTTOM] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_RIGHT] == 0))
          {
            abi_CMD_BITMAP(STEAM_BASE+steam_frame, 180, 120, 90); // draw steam RIGHT
          }
          // if neighbor face has pipe and I also have
          else if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_BOTTOM] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_RIGHT] == 1))
          {
            abi_CMD_BITMAP(0, 224, 120, 270); // draw connector RIGHT
          }
        }
        
        // Check BOTTOM
        neighborCubeN = abi_bottomCubeN(idx);
        neighborFaceN = abi_bottomFaceN(idx);
        
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          
          // if neighbor face has pipe, but I have no
          if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_RIGHT] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_BOTTOM] == 0))
          {
            abi_CMD_BITMAP(STEAM_BASE+steam_frame, 120, 180, 180); // draw steam BOTTOM
          }
          // if neighbor face has pipe and I also have
          else if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_RIGHT] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_BOTTOM] == 1))
          {
            abi_CMD_BITMAP(0, 120, 224, 0); // draw connector BOTTOM
          }
        }
        
        // Check LEFT
        neighborCubeN = abi_leftCubeN(idx);
        neighborFaceN = abi_leftFaceN(idx);
        
        if((neighborCubeN < CUBES_MAX) && (neighborFaceN < FACES_MAX))
        {
          neighborFigure = level[neighborCubeN][neighborFaceN][0];
          neighborFigureAngle = level[neighborCubeN][neighborFaceN][1];
          
          // if neighbor face has pipe, but I have no
          if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_TOP] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_LEFT] == 0))
          {
            abi_CMD_BITMAP(STEAM_BASE+steam_frame, 60, 120, 270); // draw steam LEFT
          }
          // if neighbor face has pipe and I also have
          else if((figures[neighborFigure][angle2pipeangle(neighborFigureAngle)][TRBL_TOP] == 1) && (figures[thisFigure][angle2pipeangle(thisFigureAngle)][TRBL_LEFT] == 1))
          {
            abi_CMD_BITMAP(0, 16, 120, 90); // draw connector LEFT
          }
        }
        
        abi_CMD_REDRAW(thisFaceN); // redraw face frame buffer
      }
      
      steam_frame++;
      if(steam_frame >= 8) steam_frame=0;
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