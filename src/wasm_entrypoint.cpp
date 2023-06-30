#include "main.cpp"

int rand(int a, int b) {
	// FIXME
	return 0;
}
void __attribute__((export_name("HandleKey"))) HandleKey( int keycode, int bDown )
{
//	printf( keycode );
//	printf( bDown );
}

void __attribute__((export_name("HandleButton"))) HandleButton( int x, int y, int button, int bDown )
{
	//print( x );
	//print( y );
	//print( button );
	//print( bDown );
}

void __attribute__((export_name("HandleMotion"))) HandleMotion( int x, int y, int mask )
{
	//lastmousex = x;
	//lastmousey = y;
}
int __attribute__((export_name("main"))) main() {
	return pico8();
}

