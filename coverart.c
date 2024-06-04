#define GL_GLEXT_PROTOTYPES
#ifdef __APPLE__
#include <GLUT/glut.h>
#else
#include <GL/glut.h>
#endif
#include <math.h>

double x = 0.6;
double y = 0.9;
double z = 0.6;

void drawScene()
{

 glClearColor(0.4, 0.4, 0.4, 0.1);
 glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
 glLoadIdentity();


 // Six wall segments
 glBegin(GL_QUADS); // this is the upper left wall
	glColor3f(0.2,0.2,0.2);
		glVertex3f(-x-0.3,y,-z); // top left
		glVertex3f(-x-0.2,y,-z); // top right
		glVertex3f(-x-0.2,-y+0.4,-z);
		glVertex3f(-x-0.3,-y+0.4,-z);
 glEnd();

 glBegin(GL_QUADS); // this is the lower left wall
	glColor3f(0.2,0.2,0.2);
		glVertex3f(-x-0.3,-y+0.3,-z); // top left
		glVertex3f(-x-0.2,-y+0.3,-z); // top right
		glVertex3f(-x-0.2,-y,-z);
		glVertex3f(-x-0.3,-y,-z);
 glEnd();

 glBegin(GL_QUADS); // this is the upper wall
	glColor3f(0.2,0.2,0.2);
		glVertex3f(-x-0.2,y,-z); // top left
		glVertex3f(-x-0.2,y-0.1,-z); // bottom left
		glVertex3f(x+0.2,y-0.1,-z);
		glVertex3f(x+0.2,y,-z); 
 glEnd();

 glBegin(GL_QUADS); // this is the upper right wall
	glColor3f(0.2,0.2,0.2);
		glVertex3f(x+0.3,y,-z); // top left
		glVertex3f(x+0.2,y,-z); // top right
		glVertex3f(x+0.2,-y+0.4,-z);
		glVertex3f(x+0.3,-y+0.4,-z);
 glEnd();

 glBegin(GL_QUADS); // this is the lower right wall
	glColor3f(0.2,0.2,0.2);
		glVertex3f(x+0.3,-y+0.3,-z); // top left
		glVertex3f(x+0.2,-y+0.3,-z); // top right
		glVertex3f(x+0.2,-y,-z);
		glVertex3f(x+0.3,-y,-z);
 glEnd();

 
 // Paddle
 glBegin(GL_QUADS); // this is the lower right wall
	glColor3f(0.0,0.5,0.3);
		glVertex3f(-0.2,-y+0.4,-z); // top left
		glVertex3f(+0.2,-y+0.4,-z); // top right
		glVertex3f(+0.2,-y+0.3,-z);
		glVertex3f(-0.2,-y+0.3,-z);
 glEnd();

 // Bricks
 double r;
 double g;
 double b;
 int checkerInt = 0;

 for (double y_i=0.0;y_i<0.6;y_i=y_i+0.1)
 {
	for (double x_i=0.0;x_i<1.6;x_i=x_i+0.0889) //might need to do x_i<1.6002
	{
	 if (y_i==0.0 && checkerInt==0) {r=0.4;g=0.0;b=0.0;checkerInt=1;}
	 else if (y_i==0.0 && checkerInt==1) {r=0.35;g=0.0;b=0.0;checkerInt=0;}
	 else if (y_i==0.1 && checkerInt==0) {r=0.0;g=0.0;b=0.4;checkerInt=1;}
	 else if (y_i==0.1 && checkerInt==1) {r=0.0;g=0.0;b=0.35;checkerInt=0;}
	 else if (y_i==0.2 && checkerInt==0) {r=0.2;g=0.4;b=0.0;checkerInt=1;}
	 else if (y_i==0.2 && checkerInt==1) {r=0.2;g=0.35;b=0.0;checkerInt=0;}
	 else if (y_i==0.3 && checkerInt==0) {r=0.8;g=0.6;b=0.6;checkerInt=1;}
	 else if (y_i==0.3 && checkerInt==1) {r=0.85;g=0.6;b=0.6;checkerInt=0;}
	 else if (y_i==0.4 && checkerInt==0) {r=1.0;g=1.0;b=1.0;checkerInt=1;}
	 else if (y_i==0.4 && checkerInt==1) {r=0.9;g=0.9;b=0.9;checkerInt=0;}
	 else if (y_i==0.5 && checkerInt==0) {r=0.0;g=0.4;b=0.0;checkerInt=1;}
	 else if (y_i==0.5 && checkerInt==1) {r=0.0;g=0.35;b=0.0;checkerInt=0;}
	 else if (checkerInt==1){r=0.8;g=0.6;b=0.6;checkerInt=0;}
	 else {r=0.85;g=0.6;b=0.6;checkerInt=1;}
	 glBegin(GL_QUADS);
	 glColor3f(r,g,b);
		glVertex3f(-x-0.2+x_i,y-0.2-y_i,-z); // top left
		glVertex3f(-x-0.2+x_i+0.0889,y-0.2-y_i,-z); // top right
		glVertex3f(-x-0.2+x_i+0.0889,y-0.2-y_i-0.1,-z); // bottom right
	 	glVertex3f(-x-0.2+x_i,y-0.2-y_i-0.1,-z); // bottom left
 	 glEnd();
	}
 }

 // The ball
 glBegin(GL_QUADS);
	 glColor3f(1.0,1.0,1.0);
		glVertex3f(-0.05,-0.2,-z); // top left
		glVertex3f(0.05,-0.2,-z); // top right
		glVertex3f(0.05,-0.25,-z); // bottom right
	 	glVertex3f(-0.05,-0.25,-z); // bottom left
 	 glEnd();

 glFlush();
 glutSwapBuffers();

}

int main(int argc, char **argv)
{
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);

	glutInitWindowSize(700,700);
	glutInitWindowPosition(100,100);

	glutCreateWindow("Darcy Mazloum 260987312");

	glEnable(GL_DEPTH_TEST);

	glutDisplayFunc(drawScene);

	glutMainLoop();

	return 0;
}
