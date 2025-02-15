// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"
#include "image.h"

// TODO: define your helper functions here

int64_t square(int64_t x) {
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
      output_img->data[i * input_img->width + j] = (b << 8) | a;
    }
  }
}

// calculates gradient of a pixel wrt to a row or column length for imgproc_fade()
int64_t gradient(int64_t x, int64_t n) {
  int64_t value = 1000000 - square(((2000000000 * x) / (1000000 * n)) - 1000);
  return (value < 0) ? 0 : value; // return 0 if value negative else return value
}

// calculates modified color component of a pixel for imgproc_fade()
int64_t modified_color_comp(int64_t t_r, int64_t t_c, uint32_t c) {
    int64_t c_new = (t_r * t_c * c) / 1000000000000;
    return (c_new > 255) ? 255 : (c_new < 0) ? 0 : (uint32_t) c_new; // checking to see if 0 < c_new < 255
}

// Extract red component (bits 24-31) from the pixel
uint32_t get_r(uint32_t pixel) {
    return (pixel >> 24) & 0xFF;
}

// Extract green component (bits 16-23) from the pixel
uint32_t get_g(uint32_t pixel) {
    return (pixel >> 16) & 0xFF;
}

// Extract blue component (bits 8-15) from the pixel
uint32_t get_b(uint32_t pixel) {
    return (pixel >> 8) & 0xFF;
}

// Extract alpha component (bits 0-7) from the pixel
uint32_t get_a(uint32_t pixel) {
    return pixel & 0xFF;
}

//  pixel from individual color components
uint32_t make_pixel(uint32_t r, uint32_t g, uint32_t b, uint32_t a) {
    return (r << 24) | (g << 16) | (b << 8) | a;
}

// Convert pixel to grayscale using the formula:
// y = (79 * r + 128 * g + 49 * b) / 256
uint32_t to_grayscale(uint32_t pixel) {
    uint32_t r = get_r(pixel);
    uint32_t g = get_g(pixel);
    uint32_t b = get_b(pixel);
    uint32_t a = get_a(pixel);
    
    uint32_t y = ((79 * r) + (128 * g) + (49 * b)) / 256;
    return make_pixel(y, y, y, a);
}

// Compute array index 
int32_t compute_index(struct Image *img, int32_t col, int32_t row) {
    return row * img->width + col;
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
  // TODO: use to_grayscale() in for loop

  output_img->width = input_img->width;
  output_img->height = input_img->height;

  output_img->data = (uint32_t*) malloc(output_img->height * output_img->width * sizeof(uint32_t));
  if (output_img->data == NULL) {
    return; // if memory allocation fails
  }

  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      uint32_t pixel = input_img->data[i * input_img->width + j];
      output_img->data[i * input_img->width + j] = to_grayscale(pixel); 
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
void imgproc_rgb(struct Image *input_img, struct Image *output_img) {
  // Set the dimensions of the output image
  output_img->height = 2 * input_img->height;
  output_img->width = 2 * input_img->width;

  // Allocate memory for the output image data
  output_img->data = (uint32_t *)malloc(output_img->width * output_img->height * sizeof(uint32_t));
  if (output_img->data == NULL) {
    // Handle memory allocation failure
    return;
  }

  // Initialize the red, green, and blue images
  struct Image red_image, green_image, blue_image;
  img_init(&red_image, input_img->width, input_img->height);
  img_init(&green_image, input_img->width, input_img->height);
  img_init(&blue_image, input_img->width, input_img->height);

  // Apply the color extraction functions
  imgproc_red(input_img, &red_image);
  imgproc_green(input_img, &green_image);
  imgproc_blue(input_img, &blue_image);

  // Copy the original image (A) to the top-left quadrant
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[i * output_img->width + j] = input_img->data[i * input_img->width + j];
    }
  }

  // Copy the red image (B) to the top-right quadrant
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[i * output_img->width + (j + input_img->width)] = red_image.data[i * red_image.width + j];
    }
  }

  // Copy the green image (C) to the bottom-left quadrant
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[(i + input_img->height) * output_img->width + j] = green_image.data[i * green_image.width + j];
    }
  }

  // Copy the blue image (D) to the bottom-right quadrant
  for (int j = 0; j < input_img->width; j++) {
    for (int i = 0; i < input_img->height; i++) {
      output_img->data[(i + input_img->height) * output_img->width + (j + input_img->width)] = blue_image.data[i * blue_image.width + j];
    }
  }

  // Clean up the temporary images
  img_cleanup(&red_image);
  img_cleanup(&green_image);
  img_cleanup(&blue_image);
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
      uint32_t pixel = input_img->data[i * input_img->width + j];
      uint32_t r = get_r(pixel), g = get_g(pixel), b = get_b(pixel), a = get_a(pixel);
      int64_t grad_row = gradient(i, input_img->height);
      int64_t grad_col = gradient(j, input_img->width);
      uint32_t new_r = modified_color_comp(grad_row, grad_col, r);
      uint32_t new_g = modified_color_comp(grad_row, grad_col, g);
      uint32_t new_b = modified_color_comp(grad_row, grad_col, b);
      output_img->data[i * input_img->width + j] = make_pixel(new_r, new_g, new_b, a);
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
int imgproc_kaleidoscope(struct Image *input_img, struct Image *output_img) {
  // first check if image is square
  if (input_img->width != input_img->height) {
      return 0;  
  }
  
  output_img->width = input_img->width;
  output_img->height = input_img->height;
  
  int size = input_img->width;
  // Handling of odd dimensions
  int effective_size = (size % 2 == 1) ? size + 1 : size;
  int half = effective_size / 2;

  // Allocate memory for output
  output_img->data = (uint32_t*) malloc(output_img->height * output_img->width * sizeof(uint32_t));
  if (output_img->data == NULL) {
    return 0;  
  }

  // Process each pixel
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      int src_x = x;
      int src_y = y;
      
      // Handle quadrants
      if (x >= half) {
        // Mirror horizontally for right half
        src_x = size - 1 - x;
      }
      if (y >= half) {
        // Mirror vertically for bottom half
        src_y = size - 1 - y;
      }

      //diagonal reflection 
      if (src_y > src_x) {
        // if it's below the diagonal then swap
        int temp = src_x;
        src_x = src_y;
        src_y = temp;
      }

      // Ensure we don't access out of bounds 
      if (src_x >= size || src_y >= size) {
        src_x = (src_x >= size) ? size - 1 : src_x;
        src_y = (src_y >= size) ? size - 1 : src_y;
      }

      // Get source pixel and copy 
      int src_index = compute_index(input_img, src_x, src_y);
      int dst_index = compute_index(output_img, x, y);
      
      uint32_t pixel = input_img->data[src_index];
      output_img->data[dst_index] = pixel;
    }
  }

  return 1; 
}