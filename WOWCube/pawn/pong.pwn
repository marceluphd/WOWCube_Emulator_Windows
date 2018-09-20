#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"
/*
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
 */              
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
new lockedFaces{6};
// Array of perks and antiperks
new perks{24};
// MtCtGoSbCcCfScore is a struct, where:
// Mt - maximum touches    = 4 bits 
// Ct - current touches    = 4 bits (4 bits because, may be, player collect more then 8 medkits)
// Go - game over flag     = 1 bit
// Sb - speed bonus active = 1 bit
// Cc - current cube       = 3 bits
// Cf - current face       = 2 bits
// Score - player's score  = 16 bits
//   4 byte    3 byte    2 byte    1 byte
// 0000 0000 0000 0000 0000 0000 0000 0000
// 0100 0111  111 1110                        
//  Mt   Ct  GoSbCc Cf  Score
//new MtCtGoSbCcCfScore = (4 << 28) | (0 << 24) | (0 << 22) | (0 << 21) | (0 << 18) | (0 << 16) | 50;
// Gameplay variables
new score = 50;
new maxTouches = 4;
new wallTouch = 0;
new gameover = 0;
new startBallEndPic = 90; // Picture for start "Shake to start", ball itself, end "URGH..."
new gameEndTimer = 400;//2400;  // 3 minutes  240000 millisecond, but we send tick every 100 millisecond. so /100
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

new xyMaxBorder = 188;
new xyMinBorder = 25;

CheckNeighbour (neighbour, face, x, y, sideFlag) {
    //printf("check neighbour = %d, face = %d\n", neighbour, face);
    return ((neighbour >= 0) ? CheckFaceExit (exitsFromCube{neighbour * 6 + 2 * face + sideFlag}, x, y) : 0 );
}

CheckFaceExit (exitType, x , y) {
    //printf("exitType = %d\n", exitType);
    new res = 0;
    switch (exitType) {
        case 1: { res = 1; }
        case 2: { if (!CheckCollision(x, y,   0, 0, 120, 25)) {res = 1;} }
        case 3: { if (!CheckCollision(x, y, 120, 0, 120, 25)) {res = 1;} }
    }
    //printf("res = %d\n", res);
    return res;
}

GetSign (number) {
    return number < 0 ? -1 : 1;
}

GetCoordinates (faceSideXorY, exitNumber, &pic, &posX, &posY, &angle) {
    // To reduce size of .amx
    posX = posY = angle = 0;
    pic = 96;
    switch (exitNumber) {
        case 0: {   pic = 92;
                    posX = posY = 120;
                    if (faceSideXorY) {  // if 1 then y
                        posX = 13;                        
                        angle = 180;
                    } else {     // if 0 then x
                        posY = 228;
                        angle = 270;
                    }
                }
        case 1: {   pic = 0; posY = 400; }
        case 2: {   posY = posX = 55;
                    if (faceSideXorY) {
                        pic = 97;
                        posX = 10;
                    } else {
                        posY = 10;
                    }
                }
        case 3: {   if (faceSideXorY) {
                        posY = 60;
                        posX = 10;
                        angle = 270;
                    } else {
                        pic = 97;
                        posX = 180;
                        posY = 228;
                        angle = 90;
                    }
                }
    }
}

DrawFace (cube, face) {
    // Background
    abi_CMD_BITMAP (91, 120, 120, 0);
    // Close corners
    abi_CMD_BITMAP (92, 228, 119, 0);
    abi_CMD_BITMAP (92, 119, 13, 90);
    //printf("draw cube = %d face = %d\n", cube, face);
    new faceNumber = cube * 6 + 2 * face;
    new pic, posX, posY, angle;
    // Place walls
    // ♫ All in all you just another... Break in the wall! ♫
    for (new i = 0; i < 2; i++) {
        GetCoordinates (i, exitsFromCube{faceNumber + i}, pic, posX, posY, angle);
        abi_CMD_BITMAP (pic, posX, posY, angle);
    }
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
    printf("\n");
}
*/
onCubeAttach() {
    //printf("Attached\n");
    for (new i = 0; i < 6; i+=2 ) {
        if (lockedFaces{i} - 1 >= 0) {
            //printf("locked cube = %d and face = %d\n", lockedFaces{i} - 1, lockedFaces{i+1});
            new idx = abi_TRBL_FindRecordIndex(lockedFaces{i} - 1, lockedFaces{i+1});
            //printf("cube = %d face = %d\n", cube, face);
            //printf("lockedFace-y = %d curFace = %d\n", adjacencyList [curFaceNum]{2}, currCubePos * 3 + currFacePos);
            //printf("lockedFace-x = %d curFace = %d\n", adjacencyList [curFaceNum]{3}, currCubePos * 3 + currFacePos);
            if ( (abi_leftCubeN(idx)*3 + abi_leftFaceN(idx)) != (currCubePos*3+currFacePos) &&
                 (abi_topCubeN(idx)*3 + abi_topFaceN(idx)) != (currCubePos*3+currFacePos) ) {
                    idx = (lockedFaces{i} - 1) * 6 + lockedFaces{i+1} * 2; 
                    //printf("idx = %d\n", idx);
                    exitsFromCube {idx} = GetRandomExit();
                    exitsFromCube {idx + 1} = GetRandomExit();
                    //printf("new exits x = %d and y = %d\n", exitsFromCube {idx}, exitsFromCube {idx+1});
                    lockedFaces{i} = lockedFaces{i+1} = 0;
                    perks{idx/2} = GetRandomPerk(113, 124);
            }
        }
    }
    for (new face = 0; face < 3 ; face++){
        DrawFace(abi_cubeN, face);
        abi_CMD_REDRAW (face);
    }
    //Drawlevel();
    //PrintNeighbours();
    //printf("Cube attached\n");
}

MoveTo (&posX, &posY, &spdX, &spdY) {
    // Clear wall touches (death counter)
    wallTouch = 0;

    new temp;
    // "Swap" positions
    temp = posX;
    posX = posY;
    posY = temp;

    // If we somehow go out of bounds
    if (posY >= xyMaxBorder) posY = xyMaxBorder - 1;
    if (posY <= 0) posY = 0;
    if (posX >= xyMaxBorder) posX = xyMaxBorder - 1;
    if (posX <= 0) posX = 0;

    // Swap speeds
    temp = spdX;
    spdX = spdY;
    spdY = temp;

    // Moving to another face we change axis to move
    spdY *= -1;

    // Clear previous face and lock it
    new currCubeLocked = currCubePos * 6 + 2 * currFacePos;
    // Clear perk if didn't get it and lock face
    exitsFromCube{currCubeLocked} = exitsFromCube{currCubeLocked + 1} = perks{currCubeLocked / 2} = 0;
    
    //printf("lock length %d\n", length);
    for (new j = 0; j < 6; j += 2) {
        if (lockedFaces{j} == 0) {
            // +1 because packed strings cant hold 0 numbers
            lockedFaces{j    } = currCubePos + 1;
            lockedFaces{j + 1} = currFacePos;
            break;
        }
    }
    //printf("previouse cube = %d face = %d\n", currCubePos, currFacePos);
    if (abi_cubeN == currCubePos) {
        DrawFace (currCubePos, currFacePos);
        abi_CMD_REDRAW (currFacePos);
    }
    /*for (new i = 0; i < 6; i += 2) {
        printf ("cube = %d ",lockedFaces{i    });
        printf ("face = %d \n",lockedFaces{i + 1});
    }*/
    // Get new cube and face
    //GetCubeAndFace (destination, currCubePos, currFacePos);
    //currCubePos = newCube;
    //currFacePos = newFace;
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
        abi_CMD_BITMAP (110, 120, 120, 0);
        for (new offset = offsets{power - 1}; finalScore != 0; offset += 25) {
            // Get last digit in number
            digit = finalScore % 10;
            // Print it
            abi_CMD_BITMAP (100 + digit, offset, 89, 0);
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
            //MtCtGoSbCcCfScore += 0x10000000;
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
            speedX += GetSign(speedX) * 6;
            speedY += GetSign(speedY) * 6;
            //MtCtGoSbCcCfScore = (1 << 21) | MtCtGoSbCcCfScore;
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
            //MtCtGoSbCcCfScore -= 0x10000000;
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
            //MtCtGoSbCcCfScore = (1 << 21) | MtCtGoSbCcCfScore;
            speedPerkActive = 0;
        }
    }
}

onCubeTick() {

    if (gameCurTimer < 20) {
        gameCurTimer += 1;
        if (abi_cubeN == currCubePos) {
            DrawFace (currCubePos, currFacePos);
            abi_CMD_BITMAP (112, 120, 120, 0);
            abi_CMD_REDRAW (currFacePos);
        }
        return;
    }

    //printf("abi_cubeN = %d currCubePos = %d\n", abi_cubeN, currCubePos);
    if (!gameover) {
        gameCurTimer += 1;
        new curSideNum = abi_TRBL_FindRecordIndex(currCubePos, currFacePos);
        //printf("positionX = %d positionY = %d\n", positionX, positionY);
        //printf("speedX = %d speedY = %d\n", speedX, speedY);
        if (positionY <= 32) {
            if (speedY < 0) {
                new yNeighbourCube = abi_topCubeN(curSideNum);
                new yNeighbourFace = abi_topFaceN(curSideNum);
                if (CheckNeighbour (yNeighbourCube, yNeighbourFace, positionX, positionY, 1)) {
                    if (positionY <= 0){// && (speedY < 0) ) {
                        //printf("MoveTo -x\n");
                        MoveTo (positionX, positionY, speedY, speedX);
                        //printf("OLD currCubePos = %d currFacePos = %d\n", currCubePos, currFacePos);
                        currCubePos = yNeighbourCube;
                        currFacePos = yNeighbourFace;
                        //printf("NEW currCubePos = %d currFacePos = %d\n", currCubePos, currFacePos);
                    }
                } else {
                    //printf("Can't move through X block OUTSIDE\n");
                    ChecklWallTouch();
                    speedY *= -1;
                }
            }
        }
        else if ((positionY >= xyMaxBorder) || (positionY <= xyMinBorder + 32) && !CheckFaceExit (exitsFromCube{currCubePos * 6 + currFacePos * 2}, positionX, positionY)&& (speedY < 0)) {
            //if (!CheckFaceExit (exitsFromCube{currCubePos * 6 + currFacePos * 2}, positionX, positionY) && (speedY < 0)) {
                //printf("Can't move through X block INSIDE\n");
                ChecklWallTouch();
                speedY *= -1;
        }
        // Decreasing Y we cross X
        if (positionX <= 32) {
            if (speedX < 0) {
                new xNeighbourCube = abi_leftCubeN(curSideNum);
                new xNeighbourFace = abi_leftFaceN(curSideNum);
                if (CheckNeighbour (xNeighbourCube, xNeighbourFace, positionY, positionX, 0)) {
                    if ((positionX <= 0)){// && (speedX < 0)) {
                        //printf("MoveTo through -y\n");
                        //printf("OLD currCubePos = %d currFacePos = %d\n", currCubePos, currFacePos);
                        MoveTo (positionX, positionY, speedX, speedY);
                        currCubePos = xNeighbourCube;
                        currFacePos = xNeighbourFace;
                        //printf("NEW currCubePos = %d currFacePos = %d\n", currCubePos, currFacePos);
                    }
                } else {
                    //printf("Can't move through Y block OUTSIDE\n");
                    ChecklWallTouch();
                    speedX *= -1;
                }
            }
        }
        else if ((positionX >= xyMaxBorder) || (positionX <= xyMinBorder + 32) && !CheckFaceExit (exitsFromCube{currCubePos * 6 + currFacePos * 2 + 1}, positionY, positionX)){
        //if (!CheckFaceExit (exitsFromCube{currCubePos * 6 + currFacePos * 2 + 1}, positionY, positionX) && (speedX < 0)) {
            //printf("Can't move through Y block INSIDE\n");
            ChecklWallTouch();
            speedX *= -1;
        }

        CheckPerk();

        if ((wallTouch == maxTouches) || (score < 0)) {
            // Gameover
            gameover = 1;
            //MtCtGoSbCcCfScore = (1 << 22) | MtCtGoSbCcCfScore;
            startBallEndPic = 111;
            positionX = 120;
            positionY = 120;
        }

        if (gameCurTimer >= gameEndTimer) {
            gameover = 1;
            //MtCtGoSbCcCfScore = (1 << 22) | MtCtGoSbCcCfScore;
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
    switch(abi_ByteN(pkt, 0)) {
        case CMD_TICK: {
            onCubeTick();
        }

        case CMD_GEO: {
            abi_TRBL_Deserialize(pkt);
            if (!gameover) {
                onCubeAttach();
            }
        }
    }
}

bin(n)
{
    for (new i = 1 << 30; i > 0; i = i / 2) {
        //printf ("testByte");
        (n & i) ? printf("1"): printf("0");
    }
    printf("\n");
}

main() {
    GenerateRandomLevel();
    //Drawlevel();
    /*new testByte = 0;
    testByte =(4 << 28);// | (7 << 24) | (1 << 22) | (1 << 21) | (7 << 18) | (2 << 16) | 50;//(240 << 24) | (240 << 16) | (240 << 8) | 240;
    bin (testByte);
    testByte += 0x10000000
    bin (testByte);
    printf ("testByte = %d\n", (testByte));
    return;*/
    //new testByte{6};
    /*for (new i = 8; i < 24; i+=8) {
        testByte = 54 | (testByte << 8);//54 = 0011 0110
        testByte = 32 | (testByte << 8);//32 = 0010 0000
        testByte = 41 | (testByte << 8);//41 = 0010 1001
    }*/
    /*printf ("testByte = %d, size = %\n", testByte, sizeof(testByte));
    bin (testByte);
    for (new i = 0; i <24;i+=8){
        printf ("%d ",(testByte >> i) & 0xFF);
    }*/
    /*
    printf ("testByte = %d, size = %\n", testByte, sizeof(testByte));
    testByte = testByte << 1;
    printf ("testByte = %d, size = %\n", testByte, sizeof(testByte));
    testByte = testByte << 1;
    printf ("testByte = %d, size = %\n", testByte, sizeof(testByte));
    */
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}