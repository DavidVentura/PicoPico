#include "main.cpp"
int main(int argc, char* args[] ) {
	return pico8();
}

volatile int suspended;

void HandleSuspend()
{
	suspended = 1;
}

void HandleResume()
{
	suspended = 0;
}
