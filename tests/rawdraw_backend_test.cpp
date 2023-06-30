#include "src/main.c"

typedef struct {
	uint16_t x;
	uint16_t y;
} coords;

const coords button_coords[] = {
	{  0, 1000}, 
	{  0, 1000}, 
	{300, 1000}, 
	{  0, 1300}, 

	{650, 1200}, 
	{800, 1050}, 
};

const coords button_sizes[] = {
	{500, 200}, 
	{200, 500}, 
	{200, 500}, 
	{500, 200}, 

	{250, 250}, 
	{250, 250}, 
};
void HandleButton( int x, int y, int button, int bDown ) {
	printf("down %d,%d b:%d down:%d\n", x,y,button,bDown);

	if(!bDown) {
		for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(coords); i++) {
			buttons[i] &= ~(1 << button);
		}
	} else {
		for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(coords); i++) {
			if (x>=button_coords[i].x && x<=button_coords[i].x+button_sizes[i].x && y>=button_coords[i].y && y<=button_coords[i].y+button_sizes[i].y) {
				//buttons_frame[i] = bDown && !buttons[i];
				buttons[i] |= (1 << button);
			}
		}
	}
	for(uint8_t i = 0; i<sizeof(button_coords)/ sizeof(coords); i++) {
		printf("%x ", buttons[i]);
	}
	printf("\n");
}

void _normal_click() {
	assert(buttons[0] == 0);
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 0 );
	assert(buttons[0] == 0);
	// finger 0:  click in button
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 1 );
	assert(buttons[0] == 1);
	// finger 0:  release in button
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 0 );
	assert(buttons[0] == 0);
}

void two_finger_click() {
	assert(buttons[0] == 0);
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 0 );
	assert(buttons[0] == 0);
	// finger 0:  click in button
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 1 );
	assert(buttons[0] == 1);
	// finger 1:  click in button
	HandleButton(button_coords[0].x, button_coords[0].y, 1, 1 );
	assert(buttons[0] == 3);
	// finger 0:  release in button
	HandleButton(button_coords[0].x, button_coords[0].y, 0, 0 );
	assert(buttons[0] == 2);
	// finger 1:  release in button
	HandleButton(button_coords[0].x, button_coords[0].y, 1, 0 );
	assert(buttons[0] == 0);
}

int main(int argc, char** argv) {
	_normal_click();
	two_finger_click();
	return 0;
}

bool handle_input() {
    static uint8_t queryCounter = 0;
    return queryCounter++ == 5; // wants to quit
}
