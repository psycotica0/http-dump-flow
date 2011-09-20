#include <stdlib.h>
#include <stdio.h>

void help() {
	fputs("This program expects two arguments. The first should be the request file, the second should be the response file.\n", stderr);
	fputs("It will then output to files of the format host/path in the current directory.\n", stderr);
}

int main(int argc, char *argv[]) {
	help();
	return 0;
}
