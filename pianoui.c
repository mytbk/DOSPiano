enum TUNE{
    LOW=0, MEDIUM=(1<<3), HIGH=(2<<3)
};

int transkey(unsigned int index)
{
    int note, tune;

    note = index%7;
    index /= 7;
    switch(index){
    case 0:
        tune = HIGH;
        break;
    case 1:
        tune = MEDIUM;
        break;
    case 2:
        tune = LOW;
        break;
    default:
        return -1;
    }
    return note|tune;
}

int get_showcode(unsigned int note, int raise)
{
    int idx;
    if (note<=2){
        idx = note*2;
    }
    else{
        idx = note*2-1;
    }
    idx += raise;
    if (idx>=12){
        idx -= 12;
    }
    return idx+'a';
}





