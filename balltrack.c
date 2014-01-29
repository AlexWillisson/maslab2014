#include <stdio.h>
#include <unistd.h>
#include <limits.h>
#include <fcntl.h>
#include <opencv2/core/core_c.h>
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h>

#define DEBUG_VALUES 1

#define DASH_WINDOW "balltrack"
#define DASH_HEIGHT 2
#define DASH_WIDTH 2

#define FRAME_WIDTH 640
#define FRAME_HEIGHT 480

#define SCREEN_WIDTH DASH_WIDTH * FRAME_WIDTH
#define SCREEN_HEIGHT DASH_HEIGHT * FRAME_HEIGHT

#define MOVE_THRESH 50
#define MIN_SIZE 20

CvCapture *capture;
IplImage *frame, *raw, *screen, *hsv, *tmp_panel;
IplImage *dash_panels[DASH_HEIGHT][DASH_WIDTH];

int mouse_x, mouse_y, botfd;
double target_x;

struct ball {
	struct ball *next;
	double x, y, r;
	double pred_x, pred_y, pred_r;
	double vel_x, vel_y, vel_r;
	CvScalar color;
};

struct ball *head_dot;

struct blob {
	struct blob *next;
	double x, y, r;
};

struct blob *head_blob;

void *
xcalloc (int a, int b)
{
	void *p;

	if ((p = calloc (a, b)) == NULL) {
		fprintf (stderr, "memory error\n");
		exit (1);
	}

	return (p);
}

void
on_mouse (int event, int x, int y, int flags, void *param)
{
	mouse_x = x;
	mouse_y = y;
}

void
find_colors (IplImage *img, IplImage *res)
{
	int x, y, h, s;
	unsigned char *row_hsv, *row_bgr_dst;

	hsv = cvCreateImage (cvSize (FRAME_WIDTH, FRAME_HEIGHT), 8, 3);
	cvCopy (img, res, NULL);
	cvCvtColor (img, hsv, CV_BGR2HSV);

	row_hsv = &CV_IMAGE_ELEM (hsv, uchar, 5, 10);

	for (y = 0; y < FRAME_HEIGHT / 3; y++) {
		row_hsv = &CV_IMAGE_ELEM (hsv, uchar, y, 0);
		row_bgr_dst = &CV_IMAGE_ELEM (res, uchar, y, 0);

		for (x = 0; x < FRAME_WIDTH * 3; x += 3) {
			row_bgr_dst[x] = 0;
			row_bgr_dst[x+1] = 0;
			row_bgr_dst[x+2] = 0;
		}
	}

	for (y = 0; y < FRAME_HEIGHT; y++) {
		row_hsv = &CV_IMAGE_ELEM (hsv, uchar, y, 0);
		row_bgr_dst = &CV_IMAGE_ELEM (res, uchar, y, 0);

		for (x = 0; x < FRAME_WIDTH * 3; x += 3) {
			h = row_hsv[x];
			s = row_hsv[x+1];
			/* v = row_hsv[x+2]; */

			if (y < FRAME_HEIGHT / 2) {
				h = 0;
				s = 0;
			}				

			if ((42 <= h && h <= 90)
			    && (s > 15)) {
				row_bgr_dst[x] = 255;
				row_bgr_dst[x+1] = 0;
				row_bgr_dst[x+2] = 0;
			} else if (((160 <= h && h <= 180)
				    || (0 <= h && h <= 10))
				   && (s > 70)) {
				if (1) {
					row_bgr_dst[x] = 255;
				} else {
					row_bgr_dst[x] = 0;
				}
				row_bgr_dst[x+1] = 0;
				row_bgr_dst[x+2] = 0;
			} else {
				row_bgr_dst[x] = 0;
				row_bgr_dst[x+1] = 0;
				row_bgr_dst[x+2] = 0;
			}
		}
	}
}

void
clean_noise (IplImage *img, IplImage *res)
{
	CvMat *mat_gray, *mat_gray_shrunk;

	mat_gray = cvCreateMat (FRAME_HEIGHT, FRAME_WIDTH, CV_8UC1);
	cvCvtColor (img, mat_gray, CV_BGR2GRAY);

	mat_gray_shrunk = cvCreateMat (FRAME_HEIGHT, FRAME_WIDTH, CV_8UC1);

	cvErode (mat_gray, mat_gray_shrunk, NULL, 5);
	cvDilate (mat_gray_shrunk, mat_gray, NULL, 5);

	cvCvtColor (mat_gray_shrunk, res, CV_GRAY2BGR);
}

struct ball *
track_dot (double center_x, double center_y)
{
	struct ball *dp1, *dp2;
	static int found;

	found = 0;
	dp2 = NULL;

	for (dp1 = head_dot; dp1; dp1 = dp1->next) {
		if (hypot (center_x - dp1->x,
			   center_y - dp1->y) < MOVE_THRESH) {
			dp2 = dp1;
			found = 1;
			break;
		}
	}

	if (!found) {
		found = 1;
		dp2 = xcalloc (1, sizeof *dp2);

		dp2->color = cvScalar (random () & 0xc0,
				      random () & 0xc0,
				      random () & 0xc0,
				      0);

		if (head_dot == NULL) {
			head_dot = dp2;
		} else {
			dp2->next = head_dot;
			head_dot = dp2;
		}
	}

	dp2->x = center_x;
	dp2->y = center_y;

	return (dp2);
}

void
track_balls (IplImage *img, IplImage *res)
{
	CvMat *mat_gray;
	CvMemStorage *storage;
	CvSeq *contours, *cp, *blob_poly;
	CvMoments moments;
	CvPoint2D32f mid;
	float r;
	double blob_area, contour_area, top_area;
	struct ball *ballp, *top_ball;
	struct blob *bp1, *bp2;

	mat_gray = cvCreateMat (FRAME_HEIGHT, FRAME_WIDTH, CV_8UC1);
	cvCvtColor (img, mat_gray, CV_BGR2GRAY);

	storage = cvCreateMemStorage (0);
	if (0) {
		cvFindContours (mat_gray, storage, &contours, sizeof (CvContour),
				CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE, cvPoint (0, 0));
	} else {
		cvFindContours (mat_gray, storage, &contours, sizeof (CvContour),
				CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cvPoint (0, 0));
	}
	cvCopy (img, res, 0);

	top_ball = 0;

	for (cp = contours; cp; cp = cp->h_next) {
		cvMoments (cp, &moments, 0); 

		if (fabs (moments.m00) < 1e-6) {
			continue;
		}

		contour_area = cvContourArea (cp, CV_WHOLE_SEQ, 0);

		if (contour_area < MIN_SIZE)
			continue;

		blob_poly = cvApproxPoly (cp, sizeof (CvContour), storage,
					 CV_POLY_APPROX_DP, 3, 0);

		cvMinEnclosingCircle (blob_poly, &mid, &r);
		blob_area = M_PI * r * r;

		if (1) {
			if (fabs (blob_area / contour_area) > 1.7)
				continue;
		}

		bp1 = xcalloc (1, sizeof *bp1);

		bp1->x = mid.x;
		bp1->y = mid.y;
		bp1->r = r;

		if (head_blob == NULL) {
			head_blob = bp1;
		} else {
			bp1->next = head_blob;
			head_blob = bp1;
		}

		if (1) {
			ballp = track_dot (moments.m10 / moments.m00,
					moments.m01 / moments.m00);

			cvDrawContours (res, cp, ballp->color, ballp->color,
					INT_MAX, 1, 8, cvPoint (0, 0));

			cvCircle (res, cvPoint (ballp->x, ballp->y),
				  2, ballp->color, 3, 8, 0);
		}

		if (blob_area > top_area) {
			top_area = blob_area;
			top_ball = ballp;
		}
	}

	if (top_ball)
		target_x = top_ball->x - (FRAME_WIDTH / 2);

	for (bp1 = head_blob; bp1; bp1 = bp2) {
		bp2 = bp1->next;

		free (bp1);
	}

	head_blob = NULL;
}

void
command_bot (void)
{
	if (target_x == 0) {
		write (botfd, "a", 1);
	}

	if (-100 < target_x && target_x < 100) {
		write (botfd, "w", 1);
	} else if (target_x >= -100) {
		write (botfd, "a", 1);
	} else if (target_x <= 100) {
		write (botfd, "d", 1);
	}
}

int
main (int argc, char **argv)
{
	int c, idx, jdx, running;

	running = 1;
	head_dot = NULL;
	head_blob = NULL;

	if ((capture = cvCreateCameraCapture (1)) == NULL) {
		fprintf (stderr, "can't open camera\n");
		exit (1);
	}
		
	for (idx = 0; idx < DASH_HEIGHT; idx++) {
		for (jdx = 0; jdx < DASH_WIDTH; jdx++) {
			dash_panels[idx][jdx]
				= cvCreateImage (cvSize (FRAME_WIDTH,
							 FRAME_HEIGHT),
						 8, 3);
			cvSet (dash_panels[idx][jdx],
			       cvScalar (random () & 0xff,
					 random () & 0xff,
					 random () & 0xff,
					 0),
				NULL);
		}
	}

	cvNamedWindow (DASH_WINDOW, 0);
	cvResizeWindow (DASH_WINDOW, SCREEN_WIDTH, SCREEN_HEIGHT);

	frame = cvCreateImage (cvSize (FRAME_WIDTH, FRAME_HEIGHT), 8, 3);
	screen = cvCreateImage (cvSize (SCREEN_WIDTH, SCREEN_HEIGHT), 8, 3);
	tmp_panel = cvCreateImage (cvSize (FRAME_WIDTH, FRAME_HEIGHT), 8, 3);

	cvSetMouseCallback (DASH_WINDOW, on_mouse, NULL);

	botfd = open ("/dev/ttyACM0", O_RDWR);
	sensorfd = open ("/dev/ttyACM3", O_RDWR);

	while (1) {
		if (running) {
			raw = cvQueryFrame (capture);

			cvFlip (raw, frame, 1);
		}

		cvCopy (frame, dash_panels[0][0], 0);

		find_colors (dash_panels[0][0], dash_panels[0][1]);

		cvCopy (dash_panels[0][1], tmp_panel, 0);
		clean_noise (dash_panels[0][1], tmp_panel);

		cvCopy (tmp_panel, dash_panels[1][0], 0);
		track_balls (tmp_panel, dash_panels[1][0]);

		for (idx = 0; idx < DASH_HEIGHT; idx++) {
			for (jdx = 0; jdx < DASH_WIDTH; jdx++) {
				int row, to_row, to_col;
				unsigned char *from, *to;
				IplImage *panel;

				panel = dash_panels[idx][jdx];

				to_row = idx * FRAME_HEIGHT;
				to_col = jdx * FRAME_WIDTH;

				for (row = 0; row < FRAME_HEIGHT; row++) {
					from = &CV_IMAGE_ELEM (panel,
							       uchar,
							       row, 0);
					to = &CV_IMAGE_ELEM (screen, uchar,
							     to_row + row, 0);
					memcpy (to + to_col * 3, from,
						FRAME_WIDTH * 3);
				}
			}
		}

		cvShowImage (DASH_WINDOW, screen);

		command_bot ();

		unsigned char *img1, *img2;
 		img1 = &CV_IMAGE_ELEM (hsv, uchar, mouse_y, mouse_x * 3);
		img2 = &CV_IMAGE_ELEM (dash_panels[0][0], uchar, mouse_y, mouse_x * 3);
		if (DEBUG_VALUES) {
			printf ("%3d, %3d: %3d,%3d,%3d\t%02x%02x%02x\n",
				mouse_x, mouse_y,
				img1[0], img1[1], img1[2],
				img2[0], img2[1], img2[2]);
		}

		c = cvWaitKey (10);
		if (c == ' ') {
			running ^= 1;
		} else if (c == 033) {
			return (0);
		} else if (c == 1048603) {
			return (0);
		} else if (c > 0) {
			printf ("%d\n", c);
		}
	}

	return (0);
}
