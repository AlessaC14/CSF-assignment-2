// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"

// TODO: define your helper functions here

int square( int x ) {
  return x * x;
}

// extracts the red component of an image
void imgproc_red( struct Image *input_img, struct Image *output_img ) {
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      uint32_t pixel = input_img->data[i * input_img->width + j];
      uint32_t r = (pixel >> 24) & 0xFF; // extracting bits 24 to 31, red component
      uint32_t a = pixel & 0xFF; // extracting bits 0 to 7, alpha component
      output_img->data[i * input_img->width + j] = (r << 24) | a;
    }
  }
}

// extracts the green component of an image
void imgproc_green( struct Image *input_img, struct Image *output_img ) {
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      uint32_t pixel = input_img->data[i * input_img->width + j];
      uint32_t g = (pixel >> 16) & 0xFF; // extracting bits 16 to 23, green component
      uint32_t a = pixel & 0xFF; // extracting bits 0 to 7, alpha component
      output_img->data[i * input_img->width + j] = (g << 16) | a;
    }
  }
}

// extracts the blue component of an image
void imgproc_blue( struct Image *input_img, struct Image *output_img ) {
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      uint32_t pixel = input_img->data[i * input_img->width + j];
      uint32_t b = (pixel >> 8) & 0xFF; // extracting bits 8 to 15, green component
      uint32_t a = pixel & 0xFF; // extracting bits 0 to 7, alpha component
      output_img->data[i * input_img->width + j] = (b << 16) | a;
    }
  }
}

// calculates gradient of a pixel wrt to a row or column length for imgproc_fade()
int gradient( int x, int n) {
  return 1000000 - square(((2000000000 * x) / (1000000 * n)) - 1000);
}

// calculates modified color component of a pixel for imgproc_fade()
int modified_color_comp ( int t_r, int t_c, uint32_t c) {
  int c_new = (t_r * t_c * c) / 1000000000000;
  return c_new;
}

// ---- End of helper functions ----

// Convert input pixels to grayscale.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_grayscale( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement

  output_img->width = input_img->width;
  output_img->height = input_img->height;

  output_img->data = (uint32_t*) malloc(output_img->height * output_img->width * sizeof(uint32_t));
  if (output_img->data == NULL) {
    return; // if memory allocation fails
  }

  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      uint32_t pixel = input_img->data[i * input_img->width + j];
      uint32_t r = (pixel >> 24) & 0xFF; // extracting bits 24 to 31, red component
      uint32_t g = (pixel >> 16) & 0xFF; // extracting bits 16 to 23, green component
      uint32_t b = (pixel >> 8) & 0xFF; // extracting bits 8 to 15, blue component
      uint32_t a = (pixel) & 0xFF; // extracting bits 0 to 7, alpha component
      // integer division will automatically floor the result, as required in guidelines
      uint32_t grayscale = ((79 * r) + (128 * g) + (49 * b))/256; 
      output_img->data[i * input_img->width + j] = (grayscale << 24) | (grayscale << 16) | (grayscale << 8) | a;
    }
  }
}

// Render an output image containing 4 replicas of the original image,
// refered to as A, B, C, and D in the following diagram:
//
//   +---+---+
//   | A | B |
//   +---+---+
//   | C | D |
//   +---+---+
//
// The width and height of the output image are (respectively) twice
// the width and height of the input image.
//
// A is an exact copy of the original input image. B has only the
// red color component values of the input image, C has only the
// green color component values, and D has only the blue color component
// values.
//
// Each of the copies (A-D) should use the same alpha values as the
// original image.
//
// This transformation always succeeds.
//
// Parameters:
//   input_img - pointer to the input Image
//   output_img - pointer to the output Image (which will have
//                width and height twice the width/height of the
//                input image)
void imgproc_rgb( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement
  output_img->height = 2 * input_img->height;
  output_img->width = 2 * input_img->width;

  output_img->data = (uint32_t*) malloc(output_img->height * output_img->width * sizeof(uint32_t));
  if (output_img->data == NULL) {
    return; // if memory allocation fails
  }
  
  struct Image *red_image, *green_image, *blue_image;
  img_init(red_image, input_img->width, input_img->height);
  img_init(green_image, input_img->width, input_img->height);
  img_init(blue_image, input_img->width, input_img->height);

  imgproc_red(input_img, red_image);
  imgproc_red(input_img, green_image);
  imgproc_red(input_img, blue_image);

  
  for (int j = 0; j < input_img->width; j++) { // copying the original image into the output_img first
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[i * input_img->width + j] = input_img->data[i * input_img->width + j];
    }
  }

  for (int j = input_img->width; j < output_img->width; j++) { // copying the red image into the output_img first
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[i * red_image->width + j] = red_image->data[i * red_image->width + (j - red_image->width)];
    }
  }

  for (int j = 0; j < input_img->width; j++) { // copying the green image into the output_img first
    for (int i = input_img->height; i < output_img->height; i++) {
      output_img->data[i * green_image->width + j] = green_image->data[(i - input_img->height) * green_image->width + j];
    }
  }

  for (int j = input_img->width; j < output_img->width; j++) { // copying the blue image into the output_img first
    for (int i = input_img->height; i < output_img->height; i++) {
      output_img->data[i * blue_image->width + j] = blue_image->data[(i - blue_image->height) * blue_image->width + (j - blue_image->width)];
    }
  }

  img_cleanup(red_image);
  img_cleanup(green_image);
  img_cleanup(blue_image);

}

// Render a "faded" version of the input image.
//
// See the assignment description for an explanation of how this transformation
// should work.
//
// This transformation always succeeds.
//
// Parameters:
//   input_img - pointer to the input Image
//   output_img - pointer to the output Image
void imgproc_fade( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement

  output_img->width = input_img->width;
  output_img->height = input_img->height;

  output_img->data = (uint32_t*) malloc(output_img->height * output_img->width * sizeof(uint32_t));
  if (output_img->data == NULL) {
    return; // if memory allocation fails
  }

  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {

    }
  }
}

// Render a "kaleidoscope" transformation of input_img in output_img.
// The input_img must be square, i.e., the width and height must be
// the same. Assume that the input image is divided into 8 "wedges"
// like this:
//
//    +----+----+
//    |\ A |   /|
//    | \  |  / |
//    |  \ | /  |
//    | B \|/   |
//    +----+----+
//    |   /|\   |
//    |  / | \  |
//    | /  |  \ |
//    |/   |   \|
//    +----+----+
//
// The wedge labeled "A" is the one that will be replicated 8 times
// in the output image. In the output image,
//
//    Wedge A will have exactly the same pixels as wedge A in
//    the input image, in the same positions.
//
//    Wedge B will have exactly the same pixels as wedge A, but the
//    column and row are transposed. (I.e., it is a reflection across
//    the diagonal.)
//
//    All other wedges are mirrored versions of A such that the overall
//    image is symmetrical across all four lines dividing the image
//    (vertical split, horizontal split, and the two diagonal splits.)
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
//
// Returns:
//   1 if successful, 0 if the transformation fails because the
//   width and height of input_img are not the same.
int imgproc_kaleidoscope( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement
  return 0;
}
