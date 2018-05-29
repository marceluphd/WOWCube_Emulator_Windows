#include "cubios_abi.pwn"
#include <float>
#include <file>
/*
new const level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ 0,  0, 01, 01,  0,  0],
    [ 0,  0, 01, 01,  0,  0],
    [ 05,05, 02, 02, 00, 00],
    [ 05,05, 02, 02, 00, 00],
    [ 0,  0, 03, 03,  0,  0],
    [ 0,  0, 03, 03,  0,  0],
    [ 0,  0, 04, 04,  0,  0],
    [ 0,  0, 04, 04,  0,  0]
];
*
new const level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ 0,  0, 00, 01,  0,  0],
    [ 0,  0, 02, 03,  0,  0],
    [ 04,05, 06, 07, 08, 09],
    [ 10,11, 12, 13, 14, 15],
    [ 0,  0, 16, 17,  0,  0],
    [ 0,  0, 18, 19,  0,  0],
    [ 0,  0, 20, 21,  0,  0],
    [ 0,  0, 22, 23,  0,  0]
];
*/
new level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ -1, -1, 23, 04, -1, -1],
    [ -1, -1, 23, 23, -1, -1],
    [ 03, 14, 13, 23, 23, 00],
    [ 23, 23, 23, 01, 23, 23],
    [ -1, -1, 23, 00, -1, -1],
    [ -1, -1, 23, 23, -1, -1],
    [ -1, -1, 23, 23, -1, -1],
    [ -1, -1, 13, 23, -1, -1]
];

public score = 0;
public wordsIndex; // For availableWords array. It's workaround cause lack of generic array.
new letters[9];
new allWords[5000][9];// = [[0, ...], ...];
new gameField[8][3];
new faces2Change[8][3];// = [ [0, ... ], ... ];
//new faces2Change[3] = [-1, ...];

rotateFigureBitwise(figure, angle) {
  new r = figure;
  switch(angle) {
    case  -90: { r =   90; } // 90
    case -180: { r =  180; } // 180
    case -270: { r =  270; } // 270
    case   90: { r =  -90; } // -90
    case  180: { r = -180; } // -180
    case  270: { r = -270; } // -270
  }
  return r;
}

CalculateScore (scoreWord[]) {
    //for (new i = 0; i < wordsIndex; i++) {
    score += strlen(scoreWord);
    //}
}

// Change letters of founded word to new random one
ChangeLetters () {
    for (new i = 0; i < CUBES_MAX; i++) {
        for (new j = 0; j < FACES_PER_CUBE; j++) {
            if (faces2Change[i][j] == 1) {
                gameField[i][j] = random(26);
                faces2Change[i][j] = -1;
            }
        }
    }

    /*
    // Plan B if random won't generate same numbers on each cube
    for (new j = 0; j < FACES_PER_CUBE; j++) {
        if (faces2Change[j] == 1) {
            gameField[abi_cubeN][j] = random(26);
            faces2Change[j] = -1;
        }
    }
    */
}

// Get letters in order to form word on the faces of the cube
GetWordIndexes(begin, length) {
    new indexes[9] = [-1, ...];
    new j = 0;
    for (new i = begin; (i < 8) && (length > 0); i++, j++, length--) {
        indexes[j] = i;
        if (i == 8 - 1) {
            i = -1;
        }
    }
    return indexes;
}

RememberWord (indexes[], coords[][]) {
    new i = 0;
    for (i = 0; i < 8; i++) {
        if (indexes[i] == -1){
            break;
        }
        new cube = coords[indexes[i]][0];
        new face = coords[indexes[i]][1];
        /*if (cube == abi_cubeN) {
            faces2Change[face] = 1;
        }*/
        faces2Change[cube][face] = 1;
        letters[i] = gameField[cube] [face] + 97;
    }
    letters[i] = EOS;
    CalculateScore(letters);
    // If the word on other side of the cube and player doesn't see it, play a sound (for example)
    printf("Word: %s - remembered\n",letters);
}

GetWord (coords[][]) {
    new word[9];
    for (new i = 0; i < CUBES_MAX; i++) {
        //printf("%d-%d|",coords[i][0],coords[i][1]);
        word[i] = gameField[coords[i][0]] [coords[i][1]] + 97;
    }
    word[8] = EOS;
    return word;
}

ConcatinateArrays(arr1[], arr2[]){
    new doubleWord[17];
    for (new i = 0; i < 8; i++) {
        doubleWord[i] = arr1[i];
        doubleWord[i+8] = arr2[i];
    }
    doubleWord[16] = EOS;
    return doubleWord;
}

FindWordInDictionary (coords[][]) {
    new word[9];
    word = GetWord(coords);
    printf ("%s\n", word);
    // If word is separated, i.e. we need word "ability"
    // input string is "litywabi", we add word again and get "litywabilitywabi"
    // and search whole word "ability" in it
    new doubleWord[17];
    doubleWord = ConcatinateArrays(word, word);
    printf ("%s\n", doubleWord);

    for (new i = 0, smalWords = 0; allWords[i][0] && (smalWords != 2); i++) {
        new beginIndex = strfind(doubleWord, allWords[i][0]);
        if (beginIndex > 0) {
            new curWordLength = strlen(allWords[i][0]);
            printf ("word match: %s it's length: %d\n", allWords[i][0], curWordLength);
            smalWords++;
            if (curWordLength > 4) {
                RememberWord (GetWordIndexes(beginIndex, curWordLength), coords);
                break;
            }
            RememberWord (GetWordIndexes(beginIndex, curWordLength), coords);
        }
    }
    //printf ("End of search\n");
}

Check_X_Axis() {
    printf("Axis X\n");
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
        FindWordInDictionary(coordinates);
    }
}

Check_Y_Axis() {
    printf("Axis Y\n");
    new coordinates [8][2];
    for (new y = 2; y < 4; y++ ) {
        for (new x = 0; x < CUBES_MAX; x++) {
            //printf("C=%d F=%d-",abi_pm[x][y][0],abi_pm[x][y][1]);
            coordinates [x][0] = abi_pm[x][y][0];
            coordinates [x][1] = abi_pm[x][y][1];
        }
        //printf("\n");
        FindWordInDictionary(coordinates);
    }
}

Check_Z_Axis() {
    printf("Axis Z\n");
    new coordinates [8][2];
    // I know that it's look horrible but in loop it will take more time
    for (new i = 0; i < 2; i++) {
        new r = 1-i;
        new c = 4+i;
        // First iteration it's inner ring (letters around debug red dot, !NOT! face with red dot!)
        // and second is outer ring
        coordinates [0][0] = abi_pm[r][2][0];
        coordinates [0][1] = abi_pm[r][2][1];
        coordinates [1][0] = abi_pm[r][3][0];
        coordinates [1][1] = abi_pm[r][3][1];

        coordinates [2][0] = abi_pm[2][c][0];
        coordinates [2][1] = abi_pm[2][c][1];
        coordinates [3][0] = abi_pm[3][c][0];
        coordinates [3][1] = abi_pm[3][c][1];

        coordinates [4][0] = abi_pm[c][3][0];
        coordinates [4][1] = abi_pm[c][3][1];
        coordinates [5][0] = abi_pm[c][2][0];
        coordinates [5][1] = abi_pm[c][2][1];

        coordinates [6][0] = abi_pm[3][r][0];
        coordinates [6][1] = abi_pm[3][r][1];
        coordinates [7][0] = abi_pm[2][r][0];
        coordinates [7][1] = abi_pm[2][r][1];            
        FindWordInDictionary(coordinates);
    }
}

CheckRotationAxis() {
    wordsIndex = 0;

    Check_X_Axis();
    Check_Y_Axis();
    Check_Z_Axis();

    ChangeLetters();
}

GetGameField() {
    for (new x = 0; x < 8; x++) {
        for (new y = 0; y < 6; y++) {
            new cubeID = abi_initial_pm[x][y][0];
            new faceID = abi_initial_pm[x][y][1];
            if (cubeID != -1) {
                gameField[cubeID][faceID] = level[x][y];
            }
        }
    }

    /*
    // Get random letter to each face
    for (new faceID = 0; faceID < FACES_PER_CUBE; faceID++) {
        gameField[abi_cubeN][faceID] = random(26);
    }
    */
}

ReadDictionary(){
    printf("ReadDictionary\n");
    new File:dictionary = fopen("words3-8.txt", io_read);
    if (dictionary) {
        printf("file exist\n");
        new string[256];
        new i = 0;
        new in = 0;
        while ( fread(dictionary, string) ) {
            in = strlen(string);
            strdel(string, in-1, in+1);
            strcat(allWords[i++][0], string, in);
        }
    }
    fclose (dictionary);
}

onCubeAttach() {
    printf("Cube attached\n");
    new faceN = 0;
    //new x = 0; // projection X
    //new y = 0; // projection Y
    //new a = 0; // projection Angle (face rotated at)
    new lettersResIDOriginal[CUBES_MAX][FACES_PER_CUBE];

    for (faceN = 0; faceN < FACES_PER_CUBE; faceN++) {
        // calculate faces and rotated bitmaps positions
        //abi_InitialFacePositionAtProjection(abi_cubeN, faceN, x, y, a);
        lettersResIDOriginal[abi_cubeN][faceN] = gameField[abi_cubeN][faceN];
    }

    // Draw a part of level on this cube's face 0-2
    for (faceN = 0; faceN < FACES_PER_CUBE; faceN++) {
        abi_CMD_BITMAP (faceN, lettersResIDOriginal[abi_cubeN][faceN], 0, 0);
    }
}

onCubeDetach() {
    printf("Cube Detached\n");
  //abi_CMD_FILL(0,255,0,0);
  //abi_CMD_FILL(1,0,255,0);
  //abi_CMD_FILL(2,0,0,255);
}

run(const pkt[], size, const src[]) {
    printf("run function! of cube: %d\n", abi_cubeN);
    abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_PAWN_DEBUG: {
            printf("[%s] CMD_PAWN_DEBUG\n", src);
        }

        case CMD_TICK: {
            printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            printf("[%s] CMD_ATTACH\n", src);
            abi_attached = 1;
            //if (size == 97) {
            abi_DeserializePositonsMatrix(pkt);
            abi_LogPositionsMatrix(); // DEBUG
            /*} else {
                printf("final attach!!!\n");
                if (openDictionary == 0) {
                    GetGameField();
                    ReadDictionary();
                    openDictionary = 1;
                }
                CheckRotationAxis();
            }*/
            CheckRotationAxis();
            onCubeAttach();
        }

        case CMD_DETACH: {
            printf("[%s] CMD_DETACH\n", src);
            abi_attached = 0;
            onCubeDetach();
        }
    }
}

main() {
    /*
    // Random is generate numbers same for all cubes
    // like muskiters "all for one and one for all"
    for (new i = 0; i < 8; i++) 
        printf("%d\n", random(26));
    return;
    */
    GetGameField();
    ReadDictionary();
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}