#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"

new adjacencyList []{} = [
                     //+x  +y -y -x
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
new iNx {} = {6,5,3, 7,0,2, 2,1,2, 3,4,3}; // innerNeighboursX
new iNy {} = {2,2,0, 3,3,5, 2,2,1, 3,3,4}; // innerNeighboursY
// Arrays storing coordinates of each face outer neighbour
new oNx {} =  {7,6, 5,4, 3,2,
               6,7, 0,1, 2,3,
               3,2, 1,0, 2,3,
               2,3, 4,5, 3,2}; // outerNeighboursX
new oNy {} =  {2,3, 3,2, 1,0,
               3,2, 2,3, 4,5,
               2,3, 3,2, 0,1,
               3,2, 2,3, 5,4}; // outerNeighboursY
// Border type of the cube:
// 0 - no exit
// 1 - full exit
// 2 - half exit up (closer to 0 coordinate)
// 3 - half exit down (closer to 240 coordinate)
// Which side we cross  x y
new exitsFromCube {} = {0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0,
                        0,0, 0,0, 0,0};

// Faces which locked after ball leave them
new lockedFaces{3};
// Array of perks and antiperks
new perks{24};

// Gameplay variables
new score = 50;
new maxTouches = 4;
new wallTouch = 0;
new gameover = 0;
new startBallEndPic = 90; // Picture for start "Shake to start", ball itself, end "URGH..."
new gameEndTimer = 800;//2400;  // 3 minutes  240000 millisecond, but we send tick every 100 millisecond. so /100
new gameCurTimer = 0;     // Current game time

new speedPerkActive = 0;
//new speedBonus = 6;

// Variables of position
new speedX = 6;
new speedY = 6;

new positionX = 90;
new positionY = 50;

new currFacePos = 0;
new currCubePos = 0;

CheckNeighbour (neighbour, x, y, sideFlag) {
    //printf("check neighbour = %d\n", neighbour);
    if (neighbour >= 0) {
        new cube;
        new face;
        GetCubeAndFace (neighbour, cube, face);
        return CheckFaceExit (exitsFromCube{cube * 6 + 2 * face + sideFlag}, x, y);
    } else {
        return 0;
    }
}

CheckFaceExit (side, x , y) {
    //printf("side = %d\n", side);
    new res = 0;
    switch (side) {
        case 1: { res = 1; }
        case 2: { if (!CheckCollision(x, y,   0, 0, 120, 25)) {res = 1;} }
        case 3: { if (!CheckCollision(x, y, 120, 0, 120, 25)) {res = 1;} }
    }
    //printf("res = %d\n", res);
    return res;
}

CheckLockedFaces () {
    //printf("strlength = %d\n", strlen(lockedFaces));
    for (new i = 0; i < 3; i++ ) {
        if (lockedFaces{i} - 1 >= 0) {
            new cube, face;
            GetCubeAndFace(lockedFaces{i} - 1, cube, face);
            new lockedFaceNum = cube * 3 + face;
            new currFaceNum = currCubePos * 3 + currFacePos;
            //printf("cube = %d face = %d\n", cube, face);
            //printf("lockedFace-y = %d curFace = %d\n", adjacencyList [curFaceNum]{2}, currCubePos * 3 + currFacePos);
            //printf("lockedFace-x = %d curFace = %d\n", adjacencyList [curFaceNum]{3}, currCubePos * 3 + currFacePos);
            if (adjacencyList [lockedFaceNum]{2} != (currFaceNum) &&
               (adjacencyList [lockedFaceNum]{3} != (currFaceNum))) {
                exitsFromCube {lockedFaceNum * 2}     = GetRandomExit();
                exitsFromCube {lockedFaceNum * 2 + 1} = GetRandomExit();
                //printf("unlock xside = %d yside = %d\n", exitsFromCube {curFaceNum * 2}, exitsFromCube {curFaceNum * 2 + 1});
                // Clear locked face
                lockedFaces{i} = 0;
                perks{lockedFaceNum} = GetRandomPerk(113, 124);
            }
        }
    }
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
        // Get number of cube on exact coordinates
        cube = abi_pm[iNx{i}][iNy{i}][0];
        face0 = cube * 3 + abi_pm[iNx{i    }][iNy{i    }][1];
        face1 = cube * 3 + abi_pm[iNx{i + 1}][iNy{i + 1}][1];
        face2 = cube * 3 + abi_pm[iNx{i + 2}][iNy{i + 2}][1];

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
    }
}

GetSign (number) {
    return number < 0 ? -1 : 1;
}
/*
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
*/
GetCoordinates (faceNumber, exitNumber, &pic, &posX, &posY) {
    posX = 0;
    posY = 0;
    new even = faceNumber % 2;
    switch (exitNumber) {
        case 0: {   if (even) {  // 1
                        pic = 95;
                        posY = 4;
                    } else {     // 0
                        pic = 94;
                        posX = 1;
                    }
                }
        case 2: {   if (even) {
                        pic = 97;
                    } else {
                        pic = 96;
                    }
                }
        case 3: {   if (even) {
                        pic = 99;
                        posY = 120;
                    } else {
                        pic = 98;
                        posX = 120;
                    }
                }
    }
}

DrawFace (cube, face) {
    // Close corners
    abi_CMD_BITMAP (91, 0, 0, 0);
    abi_CMD_BITMAP (92, 215, 3, 0);
    abi_CMD_BITMAP (93, 0, 215, 0);
    //printf("draw face %d %d\n", cube, face);
    new faceNumber = cube * 6 + 2 * face;
    new pic, posX, posY;
    // Place walls
    // ♫ All in all you just another... Break in the wall! ♫
    if (exitsFromCube{faceNumber} != 1) {
        GetCoordinates (faceNumber, exitsFromCube{faceNumber}, pic, posX, posY);
        //printf("pic = %d, posX = %d, posY = %d\n", pic, posX, posY);
        abi_CMD_BITMAP (pic, posX, posY, 0);
    }
    if (exitsFromCube{faceNumber + 1} != 1) {
        GetCoordinates (faceNumber + 1, exitsFromCube{faceNumber + 1}, pic, posX, posY);
        //printf("pic = %d, posX = %d, posY = %d\n", pic, posX, posY);
        abi_CMD_BITMAP (pic, posX, posY, 0);
    }
    //abi_CMD_BITMAP (90, 0,0,0);
    new perk = perks{faceNumber/2};
    if (perk > 100) {
        abi_CMD_BITMAP (perk, 120, 150, 0);
    }
}

// Get random wall
GetRandomExit () {
    new procents = random(100);
    //printf ("%d\n", procents);
    if (procents >= 95) {
        return 0;
    }
    else if (procents >= 90) {
        return 3;
    }
    else if (procents >= 85) {
        return 2;
    }
    else {
        return 1;
    }
}

GetRandomPerk (min, max) {
    return random(max - min) + min;
}

GenerateRandomLevel () {
    // Walls
    for (new i = 0; i < 48; i++) {
        exitsFromCube{i} = GetRandomExit();
    }
    // Perks
    for (new i = 1; i < 24; i++) {
        perks{i} = GetRandomPerk(113, 124);
    }
}
/*
Drawlevel(){
    for (new i = 0; i < 48; i++) {
        if ((i%6)==0){
            printf("\n");
        }
        printf("%d ",exitsFromCube{i});
    }
}
*/
onCubeAttach() {
    GetNeightbours();
    CheckLockedFaces();
    for (new face = 0; face < 3 ; face++){
        DrawFace(abi_cubeN, face);
        abi_CMD_REDRAW (face);
    }
    //Drawlevel();
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
    cube = faceNumber / 3;
    face = faceNumber % 3;
    //printf("cube = %d, face = %d\n", cube, face);
}

MoveTo (&posX, &posY, &spdX, &spdY, destination) {
    // Clear wall touches (death counter)
    wallTouch = 0;

    new temp;
    // "Swap" positions
    temp = posX;
    posX = posY;
    posY = temp;

    // If we somehow go out of bounds
    if (posY >= 150) posY = 149;
    if (posX >= 150) posX = 149;

    // Swap speeds
    temp = spdX;
    spdX = spdY;
    spdY = temp;

    // Moving to another face we change axis to move
    spdY *= -1;

    // Clear previous face and lock it
    new currCubeLocked = currCubePos * 6 + 2 * currFacePos;
    exitsFromCube{currCubeLocked}     = 0;
    exitsFromCube{currCubeLocked + 1} = 0;
    // Clear perk if didn't get it and lock face
    perks{currCubeLocked / 2} = 0;
    
    //printf("lock length %d\n", length);
    for (new j = 0; j < 3; j++) {
        if (lockedFaces{j} == 0) {
            // +1 because packed strings cant hold 0 numbers
            lockedFaces{j} = currCubeLocked / 2 + 1;
            break;
        }
    }
    //printf("previouse cube = %d face = %d\n", currCubePos, currFacePos);
    if (abi_cubeN == currCubePos) {
        DrawFace (currCubePos, currFacePos);
        abi_CMD_REDRAW (currFacePos);
    }
    // Get new cube and face
    GetCubeAndFace (destination, currCubePos, currFacePos);
    //printf("change to cube = %d face = %d\n", currCubePos, currFacePos);
}

ShowScore (finalScore) {
    if (abi_cubeN == currCubePos) {
        new power = 1;
        new finder = finalScore;
        for (;(finder /= 10) != 0;) {
            power++;
        }
        new offsets{} = {110,100,90,80};
        new digit;
        abi_CMD_BITMAP (110, 5, 70, 0);
        for (new offset = offsets{power - 1}; finalScore != 0; offset += 25) {
            // Get last digit in number
            digit = finalScore % 10;
            // Print it
            abi_CMD_BITMAP (100 + digit, offset, 82, 0);
            // Cut this printed digit and move on
            finalScore /= 10;
        }
        abi_CMD_REDRAW (currFacePos);
    }
}

PerkEffect (perkNumber) {
    switch (perkNumber) {
        case 113: {
            // Medkit
            //printf("get medkit\n");
            maxTouches++;
        }
        case 114: {
            //printf("get +10 score\n");
            score += 10;
        }
        case 115: {
            //printf("get +20 score\n");
            score += 20;
        }
        case 116: {
            //printf("get +30 score\n");
            score += 30;
        }
        case 117: {
            //printf("get x2 score\n");
            score *= 2;
        }
        case 118: {
            //printf("get x3 score\n");
            score *= 3;
        }
        case 119: {
            //printf("get speed bust\n");
            //speedX += GetSign(speedX) * speedBonus;
            //speedY += GetSign(speedY) * speedBonus;
            speedX += GetSign(speedX) * 6;
            speedY += GetSign(speedY) * 6;
            speedPerkActive = 1;
        }
        case 120: {
            score -= 10;
        }
        case 121: {
            score -= 20;
        }
        case 122: {
            score -= 30;
        }
        case 123: {
            maxTouches--;
        }
    }
}

ABS (value) {
    return value < 0 ? value * -1 : value; 
}

// Standard rectangle collision detection
CheckCollision (pos_x_A, pos_y_A, pos_x_B, pos_y_B, width_B, height_B) {
    return (( pos_x_A + 64 > pos_x_B          ) &&
            ( pos_x_A      < pos_x_B + width_B) &&
            ( pos_y_A + 64 > pos_y_B          ) &&
            ( pos_y_A      < pos_y_B + height_B ));
}

CheckPerk () {
    new curSide = currCubePos * 3 + currFacePos;
    new hasPerk = perks {curSide};
    if (hasPerk > 0) {
        // Medkit 45x45 other perks are 64x64
        if (hasPerk == 113 && CheckCollision(positionX, positionY, 120, 150, 45, 45)) {
            PerkEffect(hasPerk);
            perks {curSide} = 0;
        } else if (CheckCollision(positionX, positionY, 120, 150, 64, 64)) {
            PerkEffect(hasPerk);
            perks {curSide} = 0;
        }
    }
}

ChecklWallTouch () {
    wallTouch++;
    score++;
    if (speedPerkActive) {
        speedX = speedX + GetSign(speedX) * -1;
        speedY = speedY + GetSign(speedY) * -1;
        //printf("decrease speed speedX = %d speedY = %d\n", ABS(speedX), ABS(speedY));
        score++;
        if (ABS(speedX) == 6) {
            speedPerkActive = 0;
        }
    }
}

onCubeTick() {

    if (gameCurTimer < 20) {
        gameCurTimer += 1;
        if (abi_cubeN == currCubePos) {
            DrawFace (currCubePos, currFacePos);
            abi_CMD_BITMAP (112, 5, 70, 0);
            abi_CMD_REDRAW (currFacePos);
        }
        return;
    }

    //printf("abi_cubeN = %d currCubePos = %d\n", abi_cubeN, currCubePos);
    if (!gameover) {
        gameCurTimer += 1;
        new sideNumber = currCubePos * 3 + currFacePos;
        //printf("positionX = %d positionY = %d\n", positionX, positionY);
        if ((positionY <= 0)) {
            new yNeighbour = adjacencyList[sideNumber]{2}; 
            if (CheckNeighbour (yNeighbour, positionX, positionY, 1)) {
                //printf("MoveTo -x\n");
                MoveTo (positionX, positionY, speedY, speedX, yNeighbour);
            } else {
                //printf("Can't move through Y block OUTSIDE\n");
                ChecklWallTouch();
                speedY *= -1;
            }
        }
        else if ((positionY >= 150) || (positionY <= 25) && !CheckFaceExit (exitsFromCube{sideNumber * 2}, positionX, positionY) && (speedY < 0)) {
            //printf("Can't move through Y block INSIDE\n");
            ChecklWallTouch();
            speedY *= -1;
        }
        // Decreasing Y we cross X
        else if (positionX <= 0) {
            new xNeighbour = adjacencyList[sideNumber]{3}; 
            if (CheckNeighbour (xNeighbour, positionY, positionX, 0)) {
                //printf("MoveTo -y\n");
                MoveTo (positionX, positionY, speedX, speedY, xNeighbour);
            } else {
                //printf("Can't move through X block OUTSIDE\n");
                ChecklWallTouch();
                speedX *= -1;
            }
        }
        else if ((positionX >= 150) || (positionX <= 25) && !CheckFaceExit (exitsFromCube{sideNumber * 2 + 1}, positionY, positionX) && (speedX < 0)) {
            //printf("Can't move through X block INSIDE\n");
            ChecklWallTouch();
            speedX *= -1;
        }

        CheckPerk();

        if ((wallTouch == maxTouches) || (score < 0)) {
            // Gameover
            gameover = 1;
            startBallEndPic = 111;
            positionX = 20;
            positionY = 70;
        }

        if (gameCurTimer >= gameEndTimer) {
            gameover = 1;
            ShowScore(score);
            return;
        }

        if (abi_cubeN == currCubePos) {
            DrawFace (currCubePos, currFacePos);
            abi_CMD_BITMAP (100 + wallTouch, 110, 110, 0);
            abi_CMD_BITMAP (startBallEndPic, positionX, positionY, 0);
            abi_CMD_REDRAW (currFacePos);
        }

        positionX += speedX;
        positionY += speedY;
    }
}

run(const pkt[], size, const src[]) {
    //printf("run function! of cube: %d\n", abi_cubeN);
    //abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_TICK: {
            onCubeTick();
            //printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            //printf("[%s] CMD_ATTACH\n", src);
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
    //GenerateRandomLevel();
    //Drawlevel();
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}