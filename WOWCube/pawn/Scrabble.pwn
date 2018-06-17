#include "cubios_abi.pwn"

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
/*/
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
/*
// ideal level
new level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ -1, -1, 01, 23, -1, -1],
    [ -1, -1, 00, 23, -1, -1],
    [ 18, 20, 13, 14, 23, 23],
    [ 00, 01, 00, 13, 03, 14],
    [ -1, -1, 13, 04, -1, -1],
    [ -1, -1, 00, 23, -1, -1],
    [ -1, -1, 23, 13, -1, -1],
    [ -1, -1, 23, 23, -1, -1]
];
*/
//qwasw
public score = 0;
new color = 78;
new levelWords [][] = [["abandon"], ["sun"], ["one"], ["banana"]];
new gameField {24};
//new colorsInUse {} = {0,0,0, 0,0,0, 0,0,0, 0,0,0};
new faceColors []{} = [{0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0}];
                       
randomInterval(min, max) {    
    new rand = random(max - min ) + min;  
    return rand;
}

CalculateScore (scoreWord[]) {
    //for (new i = 0; i < wordsIndex; i++) {
    score += strlen(scoreWord);
    //}
}
/*
// Change letters of founded word to new random one
LightupLetters () {
    new letter;
    for (new i = 0; i < CUBES_MAX; i++) {
        for (new j = 0; j < FACES_PER_CUBE; j++) {
            if (faces2Change[i][j] == 1) {
                gameField[i][j] += 26;//random(26);
                faces2Change[i][j] = -1;
            }
            letter = gameField[i][j];
            if (letter > 25) {
                letter -= 26;
            }
            if (faces2Change{i * 3 + j} == 1) {
                letter += 26;//random(26);
                faces2Change{i * 3 + j} = 0;
            }
            gameField[i][j] = letter;
        }
    }

    
    // Plan B if random won't generate same numbers on each cube
    for (new j = 0; j < FACES_PER_CUBE; j++) {
        if (faces2Change[j] == 1) {
            gameField[abi_cubeN][j] = random(26);
            faces2Change[j] = -1;
        }
    }
    
}*/

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
    new letters{9};
    color++;
    //new randColor = randomInterval (79, 84);

    for (i = 0; i < 8; i++) {
        if (indexes[i] == -1){
            break;
        }
        new cube = coords[indexes[i]][0];
        new face = coords[indexes[i]][1];

        new number = cube * 3 + face;

        for (new j = 0; j < 4; j++) {
            printf ("j is: %d\n",j);
            if (faceColors[number]{j} == 0) {
                faceColors[number]{j} = color;//randColor;
                break;
            }
        }
        letters{i} = gameField{number} + 97;
    }
    letters{i} = EOS;
    CalculateScore(letters);
    // If the word on other side of the cube and player doesn't see it, play a sound (for example)
    printf("Word: %s - remembered\n",letters);
}

GetWord (coords[][]) {
    new word{9};
    for (new i = 0; i < CUBES_MAX; i++) {
        //printf("%d-%d|",coords[i][0],coords[i][1]);
        //word{i} = gameField[coords[i][0]] [coords[i][1]] + 97;
        word{i} = gameField{coords[i][0] * 3 + coords[i][1]} + 97;
    }
    word{8} = EOS;
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
    new word{9};
    word = GetWord(coords);
    printf ("%s\n", word);
    // If word is separated, i.e. we need word "ability"
    // input string is "litywabi", we add word again and get "litywabilitywabi"
    // and search whole word "ability" in it
    /*new doubleWord[17];
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
    }*/
    new currWord{8};
    for (new i = 0, smallWords = 0; i < 4/*i < sizeof(levelWords[i][0])*/ && (smallWords != 2); i++) {
        strpack(currWord, levelWords[i][0]);
        //printf("currWord = %s levelWords[i][0] = %s\n",currWord, levelWords[i][0]);
        new beginIndex = strfind(word,currWord);
        //printf("%d\n",beginIndex);
        if (beginIndex >= 0) {
            new curWordLength = strlen(currWord);
            printf ("word match: %s it's length: %d\n", currWord, curWordLength);
            smallWords++;
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
        FindWordInDictionary(coordinates);
    }
}

CheckRotationAxis() {
    color = 78;
    Check_X_Axis();
    Check_Y_Axis();
    Check_Z_Axis();

    //LightupLetters();
}

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
    /*for (new cubeID = 0; cubeID < CUBES_MAX; cubeID++){
        for (new faceID = 0; faceID < FACES_PER_CUBE; faceID++) {
            printf ("%d\n",gameField{cubeID * 3 + faceID});
        }
    }*/
    /*
    // Get random letter to each face
    for (new faceID = 0; faceID < FACES_PER_CUBE; faceID++) {
        gameField[abi_cubeN][faceID] = random(26);
    }
    */
}
/*
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
*/
onCubeAttach() {
    //printf("Cube attached\n");
    new faceN = 0;
    new colorN = 0;
    //new x = 0; // projection X
    //new y = 0; // projection Y
    //new a = 0; // projection Angle (face rotated at)
    new lettersResIDOriginal[CUBES_MAX][FACES_PER_CUBE];

    for (faceN = 0; faceN < FACES_PER_CUBE; faceN++) {
        // calculate faces and rotated bitmaps positions
        //abi_InitialFacePositionAtProjection(abi_cubeN, faceN, x, y, a);
        //lettersResIDOriginal[abi_cubeN][faceN] = gameField[abi_cubeN][faceN];
        new number = abi_cubeN * 3 + faceN;
        abi_CMD_BITMAP(faceN, 0, 0, 0);
        for (colorN = 0; colorN < 4; colorN++) {
            //printf ("number - %d colorN - %d\n",number, colorN);
            new curColor = faceColors[number]{colorN};
            //printf ("%d\n",color);
            if (curColor != 0) {
                if (colorN > 0) {
                    curColor += 6;
                }
                abi_CMD_BITMAP(faceN, curColor, 0, 0);
                // Reset color
                faceColors[number]{colorN} = 0;
            }
            else {
                break;
            }
        }
        /*if (faces2Change{number} == 1) {
            //abi_CMD_FILL(faceN, 34,177, 76);
        } else {
            
        }*/
        //lettersResIDOriginal[abi_cubeN][faceN] = letter;
        lettersResIDOriginal[abi_cubeN][faceN] = gameField{number} + 52;
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
    //printf("run function! of cube: %d\n", abi_cubeN);
    abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_PAWN_DEBUG: {
            //printf("[%s] CMD_PAWN_DEBUG\n", src);
        }

        case CMD_TICK: {
            //printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            //printf("[%s] CMD_ATTACH\n", src);
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
            //printf("[%s] CMD_DETACH\n", src);
            abi_attached = 0;
            onCubeDetach();
        }
    }
}

main() {
    /*
    // Random is generate numbers same for all cubes
    // like musketeers "all for one and one for all"
    for (new i = 0; i < 8; i++) 
        printf("%d\n", random(26));
    return;
    */
    /*new str{} = {27,34,57,123};
    //new str{} = {"abandon", "sun", "one", "banana"};
    for (new i = 0; levelWords[i][0] ; i++) {
        //strunpack(str, levelWords[i]);
        //if (strfind(levelWords,"sun")){
            //printf("%s\n",str{i});
            printf("%s\n",levelWords[i][0]);
        //}
        
    }*/
   /* new huy{} = {"huy"}
    new huyna{} = {"adahuyna"};
    printf("%d\n",strfind(huyna, huy));*/
    //printf("%d\n",sizeof(faceColors));
    GetGameField();
    //ReadDictionary();
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}