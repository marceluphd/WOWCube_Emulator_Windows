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
        /*or(new r=0; r<TRBL_RECORDS_MAX; r++) {
            printf("TRBL[%d][0] = %d TRBL[%d][1] = %d \n", r, abi_TRBL[r][0], r, abi_TRBL[r][1]);
        }*/
        
        /*new idx = abi_TRBL_FindRecordIndex(abi_cubeN, 0);
        printf("idx = %d \n", idx);
        printf("top = %d \n", abi_topCubeN(idx));
        printf("right = %d \n", abi_rightCubeN(idx));
        printf("left = %d \n", abi_leftCubeN(idx));
        printf("bottom = %d \n", abi_bottomCubeN(idx));*/
        
    }

    case CMD_GEO:
    {
      abi_TRBL_Deserialize(pkt);
      for (new _face = 0; _face < FACES_MAX; _face++) {
            new idx = abi_TRBL_FindRecordIndex(abi_cubeN, _face);
            printf("faceN = %d it's idx = %d \n", _face, idx);
    }
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