#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define OFFSET 0xc780

int main(int argc, char ** argv)
{
    char buf[1024];
    int c = getc(stdin);

    while (c != EOF) {
        int i = 0;
        while ((c != EOF) && (c != '\n') && (i < 1023)) {
            buf[i++] = c;
            c = getc(stdin);
        }
        buf[i] = '\0';
        //printf("[%s]\n", buf);
        if (c == '\n') c = getc(stdin);
        if ((buf[0] == ';') && (strlen(buf)>=5)) {
            int k = buf[5];
            buf[5] = '\0';
            //printf("<%s>", buf);
            char *endptr;
            unsigned long a = strtoul(&buf[1], &endptr, 16);
            if (endptr == &buf[5]) {
                a += OFFSET;
                snprintf(&buf[1], 5, "%04x", a);
            }
            buf[5] = k;
        }
        printf("%s\n", buf);
    }
}
