#define CUBIOS_EMULATOR
#include "cubios_abi.pwn"

/*
// first
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
// second
new level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ -1, -1, 15, 08, -1, -1],
    [ -1, -1, 14, 00, -1, -1],
    [ 14, 11, 24, 21, 14, 18],
    [ 06, 17, 22, 21, 20, 04],
    [ -1, -1, 02, 01, -1, -1],
    [ -1, -1, 08, 14, -1, -1],
    [ -1, -1, 00, 22, -1, -1],
    [ -1, -1, 04, 00, -1, -1]
];/*
// ideal level
new level [PROJECTION_MAX_X][PROJECTION_MAX_Y] = [
    [ -1, -1, 15, 08, -1, -1],
    [ -1, -1, 22, 11, -1, -1],
    [ 14, 04, 14, 24, 14, 18],
    [ 21, 17, 22, 00, 06, 14],
    [ -1, -1, 02, 08, -1, -1],
    [ -1, -1, 20, 00, -1, -1],
    [ -1, -1, 01, 21, -1, -1],
    [ -1, -1, 04, 00, -1, -1]
];
*/
//qwasw
public score = 0;
new color = 78;
//new levelWords [][] = [["abandon"], ["sun"], ["one"], ["banana"]];
new levelWords [][] = [["ilya"], ["osipov"], ["avail"], ["crew"], ["wowcube"], ["logic"]];
new gameField {24};

new faceColors []{} = [{0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0},
                      {0,0,0,0}, {0,0,0,0}, {0,0,0,0}];
                       
CalculateScore (scoreWord[]) {
    //for (new i = 0; i < wordsIndex; i++) {
    score += strlen(scoreWord);
    //}
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
    new letters{9};

    for (i = 0; i < 8; i++) {
        if (indexes[i] == -1){
            break;
        }
        new cube = coords[indexes[i]][0];
        new face = coords[indexes[i]][1];

        new number = cube * 3 + face;

        for (new j = 0; j < 4; j++) {
            if (faceColors[number]{j} == 0) {
                faceColors[number]{j} = color;
                break;
            }
        }
        letters{i} = gameField{number} + 97;
    }
    color++;
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

ConcatinateArrays(arr1{}, arr2{}){
    new doubleWord{17};
    for (new i = 0; i < 8; i++) {
        doubleWord{i} = arr1{i};
        doubleWord{i+8} = arr2{i};
    }
    return doubleWord;
}

ReverseWord(word{}) {
    new reverse {17};
    for (new i = 0; i < 16; i++){
        reverse{i} = word{15-i};
        //printf ("word = %s, reverse = %s\n", word{15-i}, reverse{i});
    }
    return reverse;
}

GetReverseIndex (index, length) {
    new normIndex = (8 - length) - index;
    if (normIndex < 0){
        normIndex += 8;
    }
    return normIndex
}

FindWordInDictionary (coords[][]) {
    new word{9};
    word = GetWord(coords);
    //printf ("%s\n", word);
    // If word is separated, i.e. we need word "ability"
    // input string is "litywabi", we add word again and get "litywabi litywabi"
    // and search whole word "ability" in it
    new doubleWord{17};
    new reverseWord {17};
    doubleWord = ConcatinateArrays(word, word);
    reverseWord = ReverseWord(doubleWord);
    //printf ("doubleword = %s, reverseword = %s\n", doubleWord, reverseWord);
    new currWord{8};
    new beginIndex;
    new isReverse = 0;
    for (new i = 0, smallWords = 0; i < sizeof(levelWords)/* && (smallWords != 2)*/; i++) {
        strpack(currWord, levelWords[i][0]);
        //printf("currWord = %s levelWords[i][0] = %s\n",currWord, levelWords[i][0]);
        beginIndex = strfind(doubleWord, currWord);
        if (beginIndex < 0){
            beginIndex = strfind(reverseWord, currWord);
            isReverse = 1;
        }
        //printf("beginIndex = %d\n",beginIndex);
        if (beginIndex >= 0) {
            new curWordLength = strlen(currWord);
            //printf ("word match: %s it's length: %d\n", currWord, curWordLength);
            smallWords++;
            if (isReverse) {
                beginIndex = GetReverseIndex(beginIndex, curWordLength);
            }
            //printf("beginIndex inside = %d\n",beginIndex);
            RememberWord (GetWordIndexes(beginIndex, curWordLength), coords);
        }
        isReverse = 0;
    }
    //printf ("End of search\n");
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
        FindWordInDictionary(coordinates);
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
        FindWordInDictionary(coordinates);
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
        FindWordInDictionary(coordinates);
    }
}

CheckRotationAxis() {
    color = 78;
    Check_X_Axis();
    Check_Y_Axis();
    Check_Z_Axis();
}

GetGameField() {
    for (new x = 0; x < 8; x++) {
        for (new y = 0; y < 6; y++) {
            new cubeID = abi_initial_pm[x][y][0];
            new faceID = abi_initial_pm[x][y][1];
            if (cubeID != -1) {
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
//sewaqd
//qaesd
onCubeAttach() {
    //printf("Cube attached\n");
    new faceN = 0;
    new colorN = 0;
    new lettersResIDOriginal[CUBES_MAX][FACES_PER_CUBE];    
    for (faceN = 0; faceN < FACES_PER_CUBE; faceN++) {
        // calculate faces and rotated bitmaps positions
        new faceIndex = abi_cubeN * 3 + faceN;
        new colors = strlen(faceColors[faceIndex]);
        new posX = 0, posY = 0;
        abi_CMD_BITMAP(0, 0, 0, 0);
        for (colorN = 0; colorN < colors; colorN++) {
            //printf ("number - %d colorN - %d\n",number, colorN);
            new curColor = faceColors[faceIndex]{colorN};
            //new positions{} = {0,25,50,0};
            //printf ("%d\n",color);
            //if (curColor != 0) {
            if (colorN > 0) {
                curColor += 6;
            }
            if (colors > 2) {
                if (colorN == 1) {
                    //printf ("colors = %d, faceIndex = %d\n",colors, faceIndex);
                    posX = 25;
                    posY = 25;
                }
                if (colorN == 2) {
                    //printf ("colors = %d, faceIndex = %d\n",colors, faceIndex);
                    posX = 0;
                    posY = 0;
                }
            }
            //printf("curColor = %d\n",curColor);
            abi_CMD_BITMAP(curColor, posX, posY, 0);
            // Reset color
            faceColors[faceIndex]{colorN} = 0;
        }
        abi_CMD_BITMAP(gameField{faceIndex} + 52, 0, 0, 0);
        abi_CMD_REDRAW(faceN);
        lettersResIDOriginal[abi_cubeN][faceN] = gameField{faceIndex} + 52;
    }
}

onCubeDetach() {
    //printf("Cube Detached\n");
  //abi_CMD_FILL(0,255,0,0);
  //abi_CMD_FILL(1,0,255,0);
  //abi_CMD_FILL(2,0,0,255);
}

run(const pkt[], size, const src[]) {
    //printf("run function! of cube: %d\n", abi_cubeN);
    //abi_LogRcvPkt(pkt, size, src); // debug

    switch(abi_GetPktByte(pkt, 0)) {
        case CMD_TICK: {
            //printf("[%s] CMD_TICK\n", src);
        }

        case CMD_ATTACH: {
            //printf("[%s] CMD_ATTACH\n", src);
            abi_attached = 1;
            abi_DeserializePositonsMatrix(pkt);
            abi_LogPositionsMatrix(); // DEBUG
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
    GetGameField();
    new opt{100};
    argindex(0, opt);
    abi_cubeN = strval(opt);
    printf("Cube %d logic. Listening on port: %d\n", abi_cubeN, (PAWN_PORT_BASE+abi_cubeN));
    listenport(PAWN_PORT_BASE+abi_cubeN);
}