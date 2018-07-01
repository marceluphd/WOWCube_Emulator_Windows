#include "cubios_abi.pwn"

new level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ -1, -1, 01, 13, -1, -1],
    [ -1, -1, 23, 00, -1, -1],
    [ 18, 23, 23, 01, 13, 14],
    [ 04, 00, 13, 00, 00, 23],
    [ -1, -1, 20, 23, -1, -1],
    [ -1, -1, 13, 14, -1, -1],
    [ -1, -1, 03, 23, -1, -1],
    [ -1, -1, 23, 23, -1, -1]
];

new adjacencyList []{} = [
                    //+x +y -y -x
                      { 2,  1, 0, 0}, { 0,  2,0,0}, { 1,  0,0,0},
                      { 5,  4, 0, 0}, { 3,  5,0,0}, { 4,  3,0,0},
                      { 8,  7, 0, 0}, { 6,  8,0,0}, { 7,  6,0,0},
                      {11, 10, 0, 0}, { 9, 11,0,0}, {10,  9,0,0},
                      {14, 13, 0, 0}, {12, 14,0,0}, {13, 12,0,0},
                      {17, 16, 0, 0}, {15, 17,0,0}, {16, 15,0,0},
                      {19, 20, 0, 0}, {18, 20,0,0}, {19, 18,0,0},
                      {23, 22, 0, 0}, {21, 23,0,0}, {22, 21,0,0}
                      ];

// Arrays storing coordinates of element for identificate the cube
//new iNx {} = {6,5,3, 7,2,0, 7,0,2, 6,3,5, 2,1,2, 3,3,4, 3,4,3, 2,2,1}; // innerNeighboursX
//new iNy {} = {2,2,0, 2,0,3, 3,3,5, 3,5,3, 2,2,1, 2,1,2, 3,3,4, 3,4,3}; // innerNeighboursY
//new iNx {} = {6, 7, 7, 6, 2, 3, 3, 2}; // innerNeighboursX
//new iNy {} = {2, 2, 3, 3, 2, 2, 3, 3}; // innerNeighboursY
new iNx {} = {6,5,3,        7,0,2,        2,1,2,        3,4,3}; // innerNeighboursX
new iNy {} = {2,2,0,        3,3,5,        2,2,1,        3,3,4}; // innerNeighboursY
// Arrays storing coordinates of each face outer neighbour
/*new oNx {} =  {7,6, 5,4, 3,2,
               7,6, 3,2, 1,0,
               6,7, 0,1, 2,3,
               6,7, 2,3, 4,5,
               3,2, 1,0, 2,3,
               3,2, 2,3, 5,4,
               2,3, 4,5, 3,2,
               2,3, 3,2, 0,1};  // outerNeighboursX
new oNy {} =  {2,3, 3,2, 1,0,
               3,2, 0,1, 2,3,
               3,2, 2,3, 4,5,
               2,3, 5,4, 3,2,
               2,3, 3,2, 0,1,
               3,2, 1,0, 2,3,
               3,2, 2,3, 5,4,
               2,3, 4,5, 3,2};  // outerNeighboursY*/
// Arrays storing coordinates of each face outer neighbour
new oNx {} =  {7,6, 5,4, 3,2,
               //7,6, 3,2, 1,0,
               6,7, 0,1, 2,3,
               //6,7, 2,3, 4,5,
               3,2, 1,0, 2,3,
               //3,2, 2,3, 5,4,
               2,3, 4,5, 3,2};
               //2,3, 3,2, 0,1};  // outerNeighboursX
new oNy {} =  {2,3, 3,2, 1,0,
               //3,2, 0,1, 2,3,
               3,2, 2,3, 4,5,
               //2,3, 5,4, 3,2,
               2,3, 3,2, 0,1,
               //3,2, 1,0, 2,3,
               3,2, 2,3, 5,4};
               //2,3, 4,5, 3,2};  // outerNeighboursY
// Border type of the cube:
// 0 - no exit
// 1 - full exit
// 2 - half exit up (closer to 0 coordinate)
// 3 - half exit down (closer to 240 coordinate)
// Which side we cross  x y
new exitsFromCube {} = {1,1, 0,0, 0,0,
                        0,1, 0,0, 0,0,
                        1,1, 0,0, 0,0,
                        1,1, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0};

public score = 0;
new speedX = 5;
new speedY = 4;

new positionX = 90;
new positionY = 10;

new currFacePos = 0;
new currCubePos = 0;

CheckNeighbour (neighbour, coordinates, sideFlag) {
    //printf("check neighbour = %d, coordinates = %d\n", neighbour, coordinates);
    new cube;
    new face;
    GetCubeAndFace (neighbour, cube, face);
    return CheckFaceExit (exitsFromCube{cube * 6 + 2 * face + sideFlag}, coordinates);
}

CheckFaceExit (side, coordinates) {
    //printf("side = %d, coordinates = %d\n", side, coordinates);
    new res = 0;
    switch (side) {
        //case 0: { res = 0; }
        case 1: { res = 1; }
        case 2: { if (coordinates > 120) {res = 1;} }
        case 3: { if (coordinates < 120) {res = 1;} }
        //default: {return 0;}
    }
    //printf("res = %d\n", res);
    return res;
}

// xN - positive x, inner neighbour
// yN - positive y, inner neighbour
AddInnerNeightbour (me, xN, yN) {
    adjacencyList [me] {0} = xN;
    adjacencyList [me] {1} = yN;
}

// nxN - negative x, outer neighbour
// nyN - negative y, outer neighbour
AddOuterNeighbour (me, nxN, nyN) {
    adjacencyList [me]  {2} = nxN;
    adjacencyList [nxN] {3} = me;

    adjacencyList [me]  {3} = nyN;
    adjacencyList [nyN] {2} = me;
}

GetNeightbours () {
    new face0;
    new face1;
    new face2;
    new faceX;
    new faceY;
    new cube;
    // Get outer neighbours, connection between edges -x and -y
    for (new i = 0, j = 0; i < 12; i += 3) {
        // Get number of cube on exact corrdinates
        cube = abi_pm[iNx{i}][iNy{i}][0];
        face0 = cube * 3 + abi_pm[iNx{i    }][iNy{i    }][1];
        face1 = cube * 3 + abi_pm[iNx{i + 1}][iNy{i + 1}][1];
        face2 = cube * 3 + abi_pm[iNx{i + 2}][iNy{i + 2}][1];

        // Connect both inner neighbours for each face
        // 1 face
        //AddInnerNeightbour (face0, face2, face1);
        // 2 face
        //AddInnerNeightbour (face1, face0, face2);
        // 3 face
        //AddInnerNeightbour (face2, face1, face0);

        // If cube's number is odd
        //if ((cube % 2) > 0) {
            // Find and connect both outer neighbours for each face
            // 1 face
            faceX = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            faceY = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            AddOuterNeighbour (face0, faceX, faceY);
            // 2 face
            faceX = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            faceY = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            AddOuterNeighbour (face1, faceX, faceY);
            // 3 face
            faceX = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            faceY = abi_pm[oNx{j}][oNy{j}][0] * 3 + abi_pm[oNx{j}][oNy{j ++}][1];
            AddOuterNeighbour (face2, faceX, faceY);
            //j += 6;
        //}
    }
}

PrintNeighbours(){
    printf("PrintNeighbours\n");
    for (new cube = 0; cube < 8; cube++) {
        for (new face = 0; face < 3; face++) {
            printf("%d %d %d %d\n",adjacencyList[cube*3+face]{0},
                                   adjacencyList[cube*3+face]{1},
                                   adjacencyList[cube*3+face]{2},
                                   adjacencyList[cube*3+face]{3});
        }
    }
}

onCubeAttach() {
    for (new face = 0; face < 3 ; face++){
        // ♪ i see the red do...face and want it to turn black ♫
        abi_CMD_BITMAP (currFacePos, 0, 0, 0);
        //abi_CMD_FILL (currFacePos, 0, 0, 0);
    }
    GetNeightbours();
    PrintNeighbours();
    //GetNeightbours();
    //PrintNeighbours();
    //printf("Cube attached\n");
   
}

onCubeDetach() {
    //printf("Cube Detached\n");
  //abi_CMD_FILL(0,255,0,0);
  //abi_CMD_FILL(1,0,255,0);
  //abi_CMD_FILL(2,0,0,255);
}

GetCubeAndFace (faceNumber, &cube, &face) {
    cube = faceNumber/3;
    face = faceNumber%3;
    //printf("cube = %d, face = %d\n", cube, face);
}

MoveTo (&posX, &posY, &spdX, &spdY, destination) {
    new temp;
    // "Swap" positions
    temp = posX;
    posX = posY;
    posY = temp;

    // Swap speeds
    temp = spdX;
    spdX = spdY;
    spdY = temp;

    // Moving to another face we change axis to move
    spdY *= -1;

    if (posX >= 240) {
        posX = 239;
    }
    if (posY >= 240) {
        posY = 239;
    }
    // Clear previous face
    abi_CMD_BITMAP (currFacePos, 0, 0, 0);
    // Get new cube and face
    GetCubeAndFace (destination, currCubePos, currFacePos);
    //abi_CUBE_2_CUBE(currCubePos);
    //printf("change to cube = %d face = %d\n", currCubePos, currFacePos);
}

onCubeTick() {
    //printf("abi_cubeN = %d currCubePos = %d\n", abi_cubeN, currCubePos);
    //if (abi_cubeN == currCubePos) {
        /*if (positionX >= 240) {
            MoveTo (positionX, positionY, speedX, speedY,
                    adjacencyList[currCubePos * 3 + currFacePos]{0});
        }
        else if (positionY >= 240) {
            MoveTo (positionY, positionX, speedY, speedX,
                    adjacencyList[currCubePos * 3 + currFacePos]{1});
        }
        // Decreasing X we cross Y
        else */if (positionY <= 0) {
            new yNeighbour = adjacencyList[currCubePos * 3 + currFacePos]{2}; 
            if (CheckFaceExit (exitsFromCube{currCubePos * 6 + 2 * currFacePos}, positionX) &&
                CheckNeighbour (yNeighbour, positionX, 1)) {
                //CheckNeighbour (adjacencyList[currCubePos * 3 + currFacePos]{2}, positionX)) {
                //printf("MoveTo -x\n");
                MoveTo (positionX, positionY, speedY, speedX, yNeighbour);
                        //adjacencyList[currCubePos * 3 + currFacePos]{2});
            } else {
                speedY *= -1;
            }
        }
        // Decreasing Y we cross X
        else if (positionX <= 0) {
            new xNeighbour = adjacencyList[currCubePos * 3 + currFacePos]{3}; 
            if (CheckFaceExit (exitsFromCube{currCubePos * 6 + 2 * currFacePos + 1}, positionY) &&
                CheckNeighbour (xNeighbour, positionY, 0)) {
                //printf("MoveTo -y\n");
                MoveTo (positionX, positionY, speedX, speedY, xNeighbour);
                        //adjacencyList[currCubePos * 3 + currFacePos]{3});
            } else {
                speedX *= -1;
            }
        }
                
        if (positionX >= 220) {
            speedX *= -1;
        }
        if (positionY >= 220) {
            speedY *= -1;
        }

        if (abi_cubeN == currCubePos) {
            abi_CMD_BITMAP (currFacePos, 0, 0, 0);
            abi_CMD_BITMAP (currFacePos, 90, positionX, positionY);
        }
        positionX += speedX;
        positionY += speedY;
    //}
}

run(const pkt[], size, const src[]) {
    //printf("run function! of cube: %d\n", abi_cubeN);
    //abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_PAWN_DEBUG: {
            //printf("[%s] CMD_PAWN_DEBUG\n", src);
        }

        case CMD_TICK: {
            onCubeTick();
            //printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            printf("[%s] CMD_ATTACH\n", src);
            abi_attached = 1;
            abi_DeserializePositonsMatrix(pkt);
            abi_LogPositionsMatrix(); // DEBUG

            onCubeAttach();
        }

        case CMD_DETACH: {
            //printf("[%s] CMD_DETACH\n", src);
            abi_attached = 0;
            onCubeDetach();
        }
    }
}

main() {
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}