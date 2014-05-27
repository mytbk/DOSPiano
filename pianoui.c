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

#define HALF 1.0594631

unsigned int raisehalf(unsigned int splits)
{
    unsigned long ss = splits*10000;
    ss /= 10595;
    return ss;
}
