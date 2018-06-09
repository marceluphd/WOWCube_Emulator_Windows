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


public score = 0;
new speedX = 5;
new speedY = 0;

new positionX = 90;
new positionY = 10;

new currFace = 0;

//new allWords[5000][9];// = [[0, ...], ...];
new levelWords [][] = [["abandon"], ["sun"], ["one"], ["banana"]];
//new levelWords []{} = [{"abandon"}, {"sun"}, {"one"}, {"banana"}];
//new levelWords {} = {"abandon", "sun", "one", "banana"};
//new gameField[8][3];
new gameField {24};
//new faces2Change[8][3];// = [ [0, ... ], ... ];
new faces2Change {} = {0,0,0, 0,0,0, 0,0,0, 0,0,0,
                       0,0,0, 0,0,0, 0,0,0, 0,0,0};
//new faces2Change[3] = [-1, ...];

GetGameField() {
    for (new x = 0; x < 8; x++) {
        for (new y = 0; y < 6; y++) {
            new cubeID = abi_initial_pm[x][y][0];
            new faceID = abi_initial_pm[x][y][1];
            if (cubeID != -1) {
                //gameField[cubeID][faceID] = level[x][y];
                gameField{cubeID * 3 + faceID} = level[x][y];
            }
        }
    }
}

CheckSide(x, y) {
    if ((x < 0) || (x >= PROJECTION_MAX_X)) {
        return 0;
    }
    if((y < 0) || (y >= PROJECTION_MAX_Y)) {
        return 0;
    }
    if((abi_pm[x][y][0] == 0xFF) || (abi_pm[x][y][1] == 0xFF)) {
        return 0;
    }
    return 1;
}

onCubeAttach() {
    //printf("Cube attached\n");
   
}

onCubeDetach() {
    //printf("Cube Detached\n");
  //abi_CMD_FILL(0,255,0,0);
  //abi_CMD_FILL(1,0,255,0);
  //abi_CMD_FILL(2,0,0,255);
}

onCubeTick() {
    if (positionX >= 240) {
        //if (CheckSide(x))
        //new temp = positionX;
        positionX = positionY;
        positionY = 235;

        new temp = speedX;
        speedX = speedY;
        speedY = temp;

        speedY *= -1;
        currFace--;

        if (currFace < 0) {
            currFace = 2;
        }
    } else if (positionY >= 240) {
        //new temp = positionX;
        positionY = positionX;
        positionX = 235;

        new temp = speedY;
        speedY = speedX;
        speedX = temp;

        speedX *= -1;
        currFace++;

        if (currFace > 2) {
            currFace = 0;
        }
    }

    
    if (positionX <= 1) {
        //if (CheckSide(x+1, y)) {
            speedX *= -1;
        //}
    }
    if (positionY <= 1) {
        speedY *= -1;
    }
    abi_CMD_FILL(currFace,0,0,0);
    abi_CMD_BITMAP (currFace, 78, positionX += speedX, positionY += speedY);
}

run(const pkt[], size, const src[]) {
    //printf("run function! of cube: %d\n", abi_cubeN);
    abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_PAWN_DEBUG: {
            //printf("[%s] CMD_PAWN_DEBUG\n", src);
        }

        case CMD_TICK: {
            onCubeTick();
            //printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            //printf("[%s] CMD_ATTACH\n", src);
            abi_attached = 1;
            //if (size == 97) {
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
    //GetGameField();
    /*new face = face0;
    for (new i = 0; i<3;i++){
        printf("%d - ",face0);
        face0++;
    }
    return;*/
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}