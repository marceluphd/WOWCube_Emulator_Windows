#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"

new gameField {24} = {79,81,78,
                      80,79,78,
                      78,79,78,
                      79,81,80,
                      81,81,80,
                      79,78,80,
                      80,78,79,
                      79,81,81};

new facesToChange {24};
new facesLength = 0;

new changeFlag = 0;
new changeShift = 1;
new shift = 1;
new score = 0;

new gameover = 0;

new gameCurTimer = 0;
new gameEndTimer = 400;

GetRandomInterval (min, max) {
    return random(max - min) + min;
}

GetLine (coords[][], line{}) {
    for (new i = 0; i < CUBES_MAX; i++) {
        line{i} = gameField{coords[i][0] * 3 + coords[i][1]};
    }
}

RememberCoords(begin, length, coords[][]) {
    //printf("begin = %d, length = %d\n", begin, length);
    new j = strlen(facesToChange);
    for (new i = begin; (i < 8) && (length > 0); i++, j++, length--) {
        // +1 Only because of 0 face
        facesToChange {j} = coords[i][0] * 3 + coords[i][1] + 1;
        //printf("facesToChange {%d} = %d\n", j, facesToChange {j} - 1);
        if (i == 8 - 1) {
            i = -1;
        }
    }
    changeFlag = 1;
}

CheckSequence (doubleLine{}, coords[][]) {
    new order = 1;
    new begin = 0;
    new curValue = doubleLine {0};
    for (new i = 1; i < 16; i++) {
        if (curValue == doubleLine{i}){
            //printf ("(curvalue %d == doubleLine{%d} %d)", curValue, i, doubleLine{i});
            order++;
        } else {
            curValue = doubleLine{i};
            if (begin < 8 && order >= 3) {
                RememberCoords (begin, order, coords);
            }
            begin = i;
            //printf ("%d-",order);
            order = 1;
        }
    }
    //printf ("\n");
}

GetCubeAndFace (faceNumber, &cube, &face) {
    cube = faceNumber / 3;
    face = faceNumber % 3;
}

FindMatches (coords[][]) {
    new line{8};
    GetLine(coords, line);
    //printf ("line = %s\n", line)
    new doubleLine{16};
    strcat(doubleLine,line,16);
    strcat(doubleLine,line,16);
    //printf ("doubleLine = %s\n", doubleLine);
    CheckSequence(doubleLine, coords);
}

Check_X_Axis() {
    //printf("Axis X\n");
    new coordinates [8][2];
    new offset = 5;
    for (new x = 2; x < 4; x++) {
        for (new y = 0; y < 6; y++) {
            coordinates[y][0] = abi_pm[x][y][0];
            coordinates[y][1] = abi_pm[x][y][1];
            if (y == 2) {
                coordinates[y+5][0] = abi_pm[x+offset][y][0];
                coordinates[y+5][1] = abi_pm[x+offset][y][1];
            } else if (y == 3) {
                coordinates[y+3][0] = abi_pm[x+offset][y][0];
                coordinates[y+3][1] = abi_pm[x+offset][y][1];
            }
        }
        offset = 3;
        FindMatches(coordinates);
    }
}

Check_Y_Axis() {
    //printf("Axis Y\n");
    new coordinates [8][2];
    for (new y = 2; y < 4; y++ ) {
        for (new x = 0; x < CUBES_MAX; x++) {
            //printf("C=%d F=%d-",abi_pm[x][y][0],abi_pm[x][y][1]);
            coordinates [x][0] = abi_pm[x][y][0];
            coordinates [x][1] = abi_pm[x][y][1];
        }
        //printf("\n");
        FindMatches(coordinates);
    }
}

Check_Z_Axis() {
    //printf("Axis Z\n");
    new coordinates [8][2];
    new N = 2;
    // First iteration it's inner ring (letters around debug red dot, !NOT! face with red dot!)
    // and second is outer ring
    for (new i = 0; i < N; i++) {
        new j = 0;
        for (new k = 2 * N - 1; k >= N; k--) {
            coordinates [j]  [0] = abi_pm[N - 1 - i][k][0];
            coordinates [j++][1] = abi_pm[N - 1 - i][k][1];
        }
        for (new k = N; k < 2 * N; k++) {
            coordinates [j]  [0] = abi_pm[k][N - 1 - i][0];
            coordinates [j++][1] = abi_pm[k][N - 1 - i][1];
        }
        for (new k = N; k < 2 * N; k++) {
            coordinates [j]  [0] = abi_pm[2 * N + i][k][0];
            coordinates [j++][1] = abi_pm[2 * N + i][k][1];
        }
        for (new k = 2 * N - 1; k >= N; k--) {
            coordinates [j]  [0] = abi_pm[k][2 * N + i][0];
            coordinates [j++][1] = abi_pm[k][2 * N + i][1];
        }
        FindMatches(coordinates);
    }
}

CheckRotationAxis() {
    changeFlag = 0;
    facesToChange = {0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0, 0,0,0};
    Check_X_Axis();
    Check_Y_Axis();
    Check_Z_Axis();
    facesLength = strlen(facesToChange);
    score += facesLength;
    for (new faceN = 0; faceN < FACES_PER_CUBE; faceN++) {
        abi_CMD_BITMAP (gameField{abi_cubeN * 3 + faceN}, 0, 0, 0);
        PrintScore (180, 200, score);
        abi_CMD_REDRAW (faceN);
    }
}

GenerateGameField() {
    // Get random elements to each face
    for (new cubeID = 0; cubeID < CUBES_MAX; cubeID++){
        for (new faceID = 0; faceID < FACES_PER_CUBE; faceID++) {
            gameField{cubeID * 3 + faceID} = GetRandomInterval(78, 82);
            //printf ("%d ", gameField{cubeID * 3 + faceID});
        }
        //printf ("\n");
    }
}

GenerateNewFaces(toChange{}) {
    //printf ("generate new colors for faces!!!\n");
    for (new i = 0; i < facesLength; i++) {
        //printf ("toChange{%d} = %d!!!\n",i, toChange{i});
        //printf ("field %d ", gameField{toChange{i} - 1});
        gameField{toChange{i} - 1} = GetRandomInterval(78, 82);
        //printf ("change to %d\n", gameField{toChange{i} - 1});
        //toChange{i} = 0;
    }
    //printf ("finish generate colors!!!\n");
}

PrintScore (xPos, yPos, finalScore) {
    new digit;
    for (new offset = xPos; finalScore != 0; offset += 25) {
        // Get last digit in number
        digit = finalScore % 10;
        // Print it
        abi_CMD_BITMAP (100 + digit, offset, yPos, 0);
        // Cut this printed digit and move on
        finalScore /= 10;
    }
}

ShowFinalScore () {
    new power = 1;
    new finder = score;
    for (;(finder /= 10) != 0;) {
        power++;
    }
    new offsets{} = {110,100,90,80};
    abi_CMD_BITMAP (110, 5, 70, 0);
    PrintScore(offsets{power - 1}, 82, score);
    abi_CMD_REDRAW (0);
}

onCubeAttach() {
    CheckRotationAxis();
}

onCubeDetach() {

}

onTick() {

    if (!gameover) {
        gameCurTimer += 1;

        if (gameCurTimer >= gameEndTimer) {
            gameover = 1;
            ShowFinalScore();
            return;
        } 
    
        if (changeFlag) {
            //printf ("flag changed!!!");
            new cube;
            new face;
            for (new i = 0; i < facesLength ; i++) {
                GetCubeAndFace (facesToChange{i} - 1, cube, face);
                //printf ("cube = %d, face = %d\n", cube, face);
                changeShift += shift;
                if (cube == abi_cubeN) {
                    //printf("changeShift = %d\n", changeShift);
                    if (changeShift <= 0) {
                        changeShift = 0;
                    }
                    abi_CMD_BITMAP(0, 0, 0, 0);
                    abi_CMD_BITMAP(gameField{cube * 3 + face}, changeShift * 30, changeShift * 30, 0);
                    abi_CMD_REDRAW(face);
                }
            }

            if ((changeShift * 30) >= 210) {
                //printf ("change colors!!! %d\n", changeShift * 12);
                GenerateNewFaces (facesToChange);
                shift = -1;
            }

            if (changeShift <= 0) {
                //printf ("stop animation!!! %d\n", changeShift);
                changeFlag = 0;
                changeShift = 1;
                shift = 1;
                CheckRotationAxis();
            }
        }
    }
}

run(const pkt[], size, const src[]) {
    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_TICK: {
            onTick();
        }

        case CMD_ATTACH: {
            abi_attached = 1;
            abi_DeserializePositonsMatrix(pkt);
            abi_LogPositionsMatrix();
            if (!gameover) {
                onCubeAttach();
            }
        }

        case CMD_DETACH: {
            abi_attached = 0;
            onCubeDetach();
        }
    }
}

main() {
    //GenerateGameField();
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}