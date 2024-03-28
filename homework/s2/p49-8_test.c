#include <stdio.h>
int main()
{
    printf("0 == 0U:Answer is=%d\n", 0 == 0U);
    printf("-1<0:Answer is=%d\n", -1 < 0);
    printf("-1<0U:Answer is=%d\n", -1 < 0U);
    printf("2147483647>-2147483647-1:Answer is=%d\n", 2147483647 > -2147483647 - 1);
    printf("2147483647U>-2147483647-1:Answer is=%d\n", 2147483647U > -2147483647 - 1);
    printf("2147483647>(int)2147483648U:Answer is=%d\n", 2147483647 > (int)2147483648U);
    printf("2147483647>(int)2147483648U:Answer is=%d\n", (int)2147483648U);
    printf("-1>-2:Answer is=%d\n", -1 > -2);
    printf("(unsigned)-1>-2:Answer is=%d\n", (unsigned)-1 > -2);

    return 0;
}