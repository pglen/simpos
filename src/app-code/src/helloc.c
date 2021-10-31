// helloc.c -- Output a 'hello world' message

// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o helloc.o helloc.c
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -o libBareMetal.o libBareMetal.c
// ld -T c.ld -o helloc.app helloc.o libBareMetal.o

#include "libsimpos.h"

static void callb();
static int strlen2(const char* str);

void itoa2(int val, char *mem, int room);
int strsum2(char *strsum, const char* str, const char* str2, int maxlen);


char tmp[25] = "";
char tmp2[45] = "";

int counter = 0;

// Make sure this is the first function; data before is OK

int main(void)

{
    int aa;
	b_output("Hello, world1\n", 14);
	b_dummy(0, 0, 0);
    b_config(CLOCKCALLBACK_SET, (unsigned long)callb);

    itoa2(counter, tmp, 24);
    strsum2(tmp2, tmp, "\n", sizeof(tmp2));

    b_output(tmp2, strlen2(tmp2));

    while(1==1)
        {
        itoa2(counter, tmp, 24);
        strsum2(tmp2, "\ncounter ", tmp, sizeof(tmp2));

        b_output(tmp2, strlen2(tmp2));

        for(int aa=0; aa < 100000000; aa++)
            ;
        }
    b_output("Hello, world2\n", 14);
	return 0;
}

int strlen2(const char* str) {
	int len = 0;
	while (str[len])
		len++;
	return len;
}

int strsum2(char *strsum, const char* str, const char* str2, int maxlen) {

	int len = strlen2(str);
    int len2 = strlen2(str2);
    int len3 = 0; int len4 = 0;

    while(1)
        {
        if(len3 >= maxlen -1)
            {
            strsum[len3] = '\0';
            break;
            }
        strsum[len3] = str[len4];
        if(strsum[len3] == '\0')
            {
            break;
            }
        len3++; len4++;
        }
    len4 = 0;
    while(1)
        {
        if(len3 >= maxlen -1)
            {
            strsum[len3] = '\0';
            break;
            }
        strsum[len3] = str2[len4];
        if(strsum[len3] == '\0')
            break;
        len3++; len4++;
        }
	return len3;
}

void itoa2(int val, char *mem, int room)

{
    int idx = 0;
    for(int aa  = 0; aa < room; aa++)
        {
        mem[idx] = (val % 10) + '0';
        val /= 10;
        idx++;
        mem[idx] = 0;
        if(val == 0)
            break;
        if(idx >= room-1)
            break;
        }
    // Reverse
    #if 1
    for(int bb = 0; bb < (idx-1) / 2; bb++)
        {
        char tch = mem[bb];         // Temporary char
        mem[bb] = mem[(idx-1) - bb];
        mem[(idx-1) - bb] = tch;
        }
    #endif
}

void callb()

{
    // Not reentrent
    //b_output("Clock Callback\n", 15);

    counter++;
}


