#include <assert.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tctest.h"
#include "imgproc.h"

// An expected color identified by a (non-zero) character code.
// Used in the "struct Picture" data type.
struct ExpectedColor {
  char c;
  uint32_t color;
};

// Type representing a "picture" of an expected image.
// Useful for creating a very simple Image to be accessed
// by test functions.
struct Picture {
  struct ExpectedColor colors[40];
  int width, height;
  const char *data;
};

// Some "basic" colors to use in test struct Pictures.
// Note that the ranges '1'-'5', 'A'-'E', and 'P'-'T'
// are (respectively) colors 'r','g','b','c', and 'm'
// with just the red, green, and blue color component values,
// which is useful for defining the expected image from the
// "rgb" transformation.
#define TEST_COLORS \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0xFF0000FF }, \
      { 'g', 0x00FF00FF }, \
      { 'b', 0x0000FFFF }, \
      { 'c', 0x00FFFFFF }, \
      { 'm', 0xFF00FFFF }, \
      { '1', 0xFF0000FF }, \
      { '2', 0x000000FF }, \
      { '3', 0x000000FF }, \
      { '4', 0x000000FF }, \
      { '5', 0xFF0000FF }, \
      { 'A', 0x000000FF }, \
      { 'B', 0x00FF00FF }, \
      { 'C', 0x000000FF }, \
      { 'D', 0x00FF00FF }, \
      { 'E', 0x000000FF }, \
      { 'P', 0x000000FF }, \
      { 'Q', 0x000000FF }, \
      { 'R', 0x0000FFFF }, \
      { 'S', 0x0000FFFF }, \
      { 'T', 0x0000FFFF }, \
    }

// Expected "basic" colors after grayscale transformation
#define TEST_COLORS_GRAYSCALE \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0x4E4E4EFF }, \
      { 'g', 0x7F7F7FFF }, \
      { 'b', 0x303030FF }, \
      { 'c', 0xB0B0B0FF }, \
      { 'm', 0x7F7F7FFF }, \
    }

// Data type for the test fixture object.
// This contains data (including Image objects) that
// can be accessed by test functions. This is useful
// because multiple test functions can access the same
// data (so you don't need to create/initialize that
// data multiple times in different test functions.)
typedef struct {
  // smiley-face picture
  struct Picture smiley_pic;

  // original smiley-face Image object
  struct Image *smiley;

  // empty Image object to use for output of
  // transformation on smiley-face image
  struct Image *smiley_out;

  // empty Image object to use for output of rgb
  // transformation on smiley-face image
  struct Image *smiley_rgb_out;

  // a square image (same width/height) to use as a test
  // for the kaleidoscope transformation
  struct Picture sq_test_pic;

  // original square Image object
  struct Image *sq_test;

  // empty image for output of kaleidoscope transformation
  struct Image *sq_test_out;

} TestObjs;

// Functions to create and clean up a test fixture object
TestObjs *setup( void );
void cleanup( TestObjs *objs );

// Helper functions used by the test code
struct Image *picture_to_img( const struct Picture *pic );
uint32_t lookup_color(char c, const struct ExpectedColor *colors);
bool images_equal( struct Image *a, struct Image *b );
void destroy_img( struct Image *img );

// Test functions
void test_rgb_basic( TestObjs *objs );
void test_grayscale_basic( TestObjs *objs );
void test_fade_basic( TestObjs *objs );
void test_kaleidoscope_basic( TestObjs *objs );
// TODO: add prototypes for additional test functions
void test_rgb_basic( TestObjs *objs );
void test_grayscale_basic( TestObjs *objs );
void test_fade_basic( TestObjs *objs );
void test_kaleidoscope_basic( TestObjs *objs );
// kaleidoscope tests
void test_kaleidoscope_odd(TestObjs *objs);
void test_kaleidoscope_fail(TestObjs *objs);
void test_helper_functions(TestObjs *objs);

void test_kaleidoscope_dense(TestObjs *objs);
void test_kaleidoscope_diagonal(TestObjs *objs);
void test_kaleidoscope_center(TestObjs *objs);


int main( int argc, char **argv ) {
  // allow the specific test to execute to be specified as the
  // first command line argument
  if ( argc > 1 )
    tctest_testname_to_execute = argv[1];

  TEST_INIT();

  // Run tests.
  // Make sure you add additional TEST() macro invocations
  // for any additional test functions you add.
  TEST( test_rgb_basic );
  TEST( test_grayscale_basic );
  //TEST( test_fade_basic );
  //TEST( test_kaleidoscope_basic );

  //Added tests
 
  //TEST(test_kaleidoscope_odd);
  //TEST(test_kaleidoscope_fail);
  //TEST(test_helper_functions);
  //TEST(test_kaleidoscope_dense);
  //TEST(test_kaleidoscope_diagonal);
  //TEST(test_kaleidoscope_center);

  TEST_FINI();
}

////////////////////////////////////////////////////////////////////////
// Test fixture setup/cleanup functions
////////////////////////////////////////////////////////////////////////

TestObjs *setup( void ) {
  TestObjs *objs = (TestObjs *) malloc( sizeof(TestObjs) );

  struct Picture smiley_pic = {
    TEST_COLORS,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };
  objs->smiley_pic = smiley_pic;
  objs->smiley = picture_to_img( &smiley_pic );

  objs->smiley_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->smiley_out, objs->smiley->width, objs->smiley->height );

  // the rgb transformation requires an output Image with width
  // and height twice the original image
  objs->smiley_rgb_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->smiley_rgb_out, objs->smiley->width * 2, objs->smiley->height * 2 );

  struct Picture sq_test_pic = {
    TEST_COLORS,
    12, // width
    12, // height
    "rrrrrr      "
    " ggggg      "
    "  bbbb      "
    "   mmm      "
    "    cc      "
    "     r      "
    "            "
    "            "
    "            "
    "            "
    "            "
    "            "
  };
  objs->sq_test_pic = sq_test_pic;
  objs->sq_test = picture_to_img( &sq_test_pic );
  objs->sq_test_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->sq_test_out, objs->sq_test->width, objs->sq_test->height );

  return objs;
}

void cleanup( TestObjs *objs ) {
  destroy_img( objs->smiley );
  destroy_img( objs->smiley_out );
  destroy_img( objs->smiley_rgb_out );
  destroy_img( objs->sq_test );
  destroy_img( objs->sq_test_out );

  free( objs );
}

////////////////////////////////////////////////////////////////////////
// Test code helper functions
////////////////////////////////////////////////////////////////////////

struct Image *picture_to_img( const struct Picture *pic ) {
  struct Image *img;

  img = (struct Image *) malloc( sizeof(struct Image) );
  img_init( img, pic->width, pic->height );

  for ( int i = 0; i < pic->height; ++i ) {
    for ( int j = 0; j < pic->width; ++j ) {
      int index = i * img->width + j;
      uint32_t color = lookup_color( pic->data[index], pic->colors );
      img->data[index] = color;
    }
  }

  return img;
}

uint32_t lookup_color(char c, const struct ExpectedColor *colors) {
  for (int i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

// Returns true IFF both Image objects are identical
bool images_equal( struct Image *a, struct Image *b ) {
  if ( a->width != b->width || a->height != b->height )
    return false;

  for ( int i = 0; i < a->height; ++i )
    for ( int j = 0; j < a->width; ++j ) {
      int index = i*a->width + j;
      if ( a->data[index] != b->data[index] )
        return false;
    }

  return true;
}

void destroy_img( struct Image *img ) {
  if ( img != NULL )
    img_cleanup( img );
  free( img );
}

////////////////////////////////////////////////////////////////////////
// Test functions
////////////////////////////////////////////////////////////////////////

void test_rgb_basic( TestObjs *objs ) {
  struct Picture smiley_rgb_pic = {
    TEST_COLORS,
    32, // width
    20, // height
    "    mrrrggbc        51112234    "
    "   c        b      4        3   "
    "  r   r  b   c    1   1  3   4  "
    " b            b  3            3 "
    " b            r  3            1 "
    " g   b    c   r  2   3    4   1 "
    "  c   ggrb   b    4   2213   3  "
    "   m        c      5        4   "
    "    gggrrbmc        22211354    "
    "                                "
    "    EAAABBCD        TPPPQQRS    "
    "   D        C      S        R   "
    "  A   A  C   D    P   P  R   S  "
    " C            C  R            R "
    " C            A  R            P "
    " B   C    D   A  Q   R    S   P "
    "  D   BBAC   C    S   QQPR   R  "
    "   E        D      T        S   "
    "    BBBAACED        QQQPPRTS    "
    "                                "
  };

  struct Image *smiley_rgb_expected = picture_to_img( &smiley_rgb_pic );

  imgproc_rgb( objs->smiley, objs->smiley_rgb_out );

  ASSERT( images_equal( smiley_rgb_expected, objs->smiley_rgb_out ) );

  destroy_img( smiley_rgb_expected );
}

void test_grayscale_basic( TestObjs *objs ) {
  struct Picture smiley_grayscale_pic = {
    TEST_COLORS_GRAYSCALE,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };

  struct Image *smiley_grayscale_expected = picture_to_img( &smiley_grayscale_pic );

  imgproc_grayscale( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_grayscale_expected, objs->smiley_out ) );

  destroy_img( smiley_grayscale_expected );
}

void test_fade_basic( TestObjs *objs ) {
  struct Picture smiley_fade_expected_pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x000032ff },
      { 'b', 0x000039ff },
      { 'c', 0x000044ff },
      { 'd', 0x00005dff },
      { 'e', 0x000095ff },
      { 'f', 0x0000a0ff },
      { 'g', 0x0000dbff },
      { 'h', 0x0000f0ff },
      { 'i', 0x003737ff },
      { 'j', 0x003b00ff },
      { 'k', 0x006363ff },
      { 'l', 0x006b6bff },
      { 'm', 0x007a00ff },
      { 'n', 0x008c00ff },
      { 'o', 0x008c8cff },
      { 'p', 0x009900ff },
      { 'q', 0x00a0a0ff },
      { 'r', 0x00e500ff },
      { 's', 0x00efefff },
      { 't', 0x00f000ff },
      { 'u', 0x470000ff },
      { 'v', 0x6b0000ff },
      { 'w', 0x6f0000ff },
      { 'x', 0x820082ff },
      { 'y', 0x990000ff },
      { 'z', 0x990099ff },
      { 'A', 0xa00000ff },
      { 'B', 0xa30000ff },
      { 'C', 0xf40000ff },
    },
    16, 10, // width and height
    "                "
    "   i        c   "
    "  u   y  f   k  "
    " a            d "
    " b            v "
    " j   g    s   w "
    "  l   rtCh   e  "
    "   x        q   "
    "    mnpABfzo    "
    "                "
  };

  struct Image *smiley_fade_expected = picture_to_img( &smiley_fade_expected_pic );

  imgproc_fade( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_fade_expected, objs->smiley_out ) );

  destroy_img( smiley_fade_expected );

  // Test case with minimum alpha values
  struct Picture min_alpha_pic = {
    {
      { ' ', 0x00000000 },
      { 'a', 0x00000000 },
      { 'b', 0x00000000 },
      { 'c', 0x00000000 },
      { 'd', 0x00000000 },
      { 'e', 0x00000000 },
      { 'f', 0x00000000 },
      { 'g', 0x00000000 },
      { 'h', 0x00000000 },
      { 'i', 0x00000000 },
      { 'j', 0x00000000 },
      { 'k', 0x00000000 },
      { 'l', 0x00000000 },
      { 'm', 0x00000000 },
      { 'n', 0x00000000 },
      { 'o', 0x00000000 },
      { 'p', 0x00000000 },
      { 'q', 0x00000000 },
      { 'r', 0x00000000 },
      { 's', 0x00000000 },
      { 't', 0x00000000 },
      { 'u', 0x00000000 },
      { 'v', 0x00000000 },
      { 'w', 0x00000000 },
      { 'x', 0x00000000 },
      { 'y', 0x00000000 },
      { 'z', 0x00000000 },
      { 'A', 0x00000000 },
      { 'B', 0x00000000 },
      { 'C', 0x00000000 },
    },
    16, 10, // width and height
    "                "
    "   i        c   "
    "  u   y  f   k  "
    " a            d "
    " b            v "
    " j   g    s   w "
    "  l   rtCh   e  "
    "   x        q   "
    "    mnpABfzo    "
    "                "
  };

  struct Image *min_alpha_expected = picture_to_img(&min_alpha_pic);

  imgproc_fade(objs->smiley, objs->smiley_out);

  ASSERT(images_equal(min_alpha_expected, objs->smiley_out));

  destroy_img(min_alpha_expected);

  // Test case with varying dimensions
  struct Picture varying_dim_pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x000032ff },
      { 'b', 0x000039ff },
      { 'c', 0x000044ff },
      { 'd', 0x00005dff },
      { 'e', 0x000095ff },
      { 'f', 0x0000a0ff },
      { 'g', 0x0000dbff },
      { 'h', 0x0000f0ff },
      { 'i', 0x003737ff },
      { 'j', 0x003b00ff },
      { 'k', 0x006363ff },
      { 'l', 0x006b6bff },
      { 'm', 0x007a00ff },
      { 'n', 0x008c00ff },
      { 'o', 0x008c8cff },
      { 'p', 0x009900ff },
      { 'q', 0x00a0a0ff },
      { 'r', 0x00e500ff },
      { 's', 0x00efefff },
      { 't', 0x00f000ff },
      { 'u', 0x470000ff },
      { 'v', 0x6b0000ff },
      { 'w', 0x6f0000ff },
      { 'x', 0x820082ff },
      { 'y', 0x990000ff },
      { 'z', 0x990099ff },
      { 'A', 0xa00000ff },
      { 'B', 0xa30000ff },
      { 'C', 0xf40000ff },
    },
    8, 5, // width and height
    "        "
    "   i c   "
    "  u y f  "
    " a    d  "
    " b    v  "
  };

  struct Image *varying_dim_expected = picture_to_img(&varying_dim_pic);

  imgproc_fade(objs->smiley, objs->smiley_out);

  ASSERT(images_equal(varying_dim_expected, objs->smiley_out));

  destroy_img(varying_dim_expected);
}

void test_kaleidoscope_basic( TestObjs *objs ) {
  struct Picture sq_test_kaleidoscope_expected_pic = {
    TEST_COLORS,
    12, // width
    12, // height
    "rrrrrrrrrrrr"
    "rggggggggggr"
    "rgbbbbbbbbgr"
    "rgbmmmmmmbgr"
    "rgbmccccmbgr"
    "rgbmcrrcmbgr"
    "rgbmcrrcmbgr"
    "rgbmccccmbgr"
    "rgbmmmmmmbgr"
    "rgbbbbbbbbgr"
    "rggggggggggr"
    "rrrrrrrrrrrr"
  };

  struct Image *sq_test_kaleidoscope_expected = picture_to_img( &sq_test_kaleidoscope_expected_pic );

  imgproc_kaleidoscope( objs->sq_test, objs->sq_test_out );

  ASSERT( images_equal( sq_test_kaleidoscope_expected, objs->sq_test_out ) );

  destroy_img( sq_test_kaleidoscope_expected );
}

void test_kaleidoscope_odd(TestObjs *objs) {
    // Input pattern - just wedge A
    struct Picture odd_pic = {
        TEST_COLORS,
        13, // odd width
        13, // odd height
        "rrrrr        "  // make each line exactly 13 characters
        "rgggg        "
        "rgbb         "
        "rgb          "
        "rg           "
        "r            "
        "             "
        "             "
        "             "
        "             "
        "             "
        "             "
        "             "
    };

    struct Image *odd_img = picture_to_img(&odd_pic);
    struct Image *odd_out = (struct Image *)malloc(sizeof(struct Image));
    img_init(odd_out, odd_img->width, odd_img->height);

    int result = imgproc_kaleidoscope(odd_img, odd_out);
    ASSERT(result == 1);

    // Expected pattern after mirroring
    struct Picture odd_expected = {
        TEST_COLORS,
        13,
        13,
        "rrrrr   rrrrr"
        "rgggg   ggggr"
        "rgbb     bbgr"
        "rgb       bgr"
        "rg         gr"
        "r           r"
        "             "
        "             "
        "rg         gr"
        "rgb       bgr"
        "rgbb     bbgr"
        "rgggg   ggggr"
        "rrrrr   rrrrr"
    };

    struct Image *expected = picture_to_img(&odd_expected);

    printf("Actual output:\n");
    for(int i = 0; i < 13; i++) {
      for(int j = 0; j < 13; j++) {
        int idx = i * 13 + j;
        uint32_t pixel = odd_out->data[idx];
        if((pixel & 0xFF000000) == 0xFF000000) printf("r");
        else if((pixel & 0x00FF0000) == 0x00FF0000) printf("g");
        else if((pixel & 0x0000FF00) == 0x0000FF00) printf("b");
        else printf(" ");
      }
      printf("\n");
    }

    printf("\nExpected output:\n");
    for(int i = 0; i < 13; i++) {
      for(int j = 0; j < 13; j++) {
        int idx = i * 13 + j;
        uint32_t pixel = expected->data[idx];
        if((pixel & 0xFF000000) == 0xFF000000) printf("r");
        else if((pixel & 0x00FF0000) == 0x00FF0000) printf("g");
        else if((pixel & 0x0000FF00) == 0x0000FF00) printf("b");
        else printf(" ");
      }
      printf("\n");
    }

    ASSERT(images_equal(odd_out, expected));

    destroy_img(odd_img);
    destroy_img(odd_out);
    destroy_img(expected);
}

void test_kaleidoscope_fail(TestObjs *objs) {
    // Test with non-square image
    struct Picture rect_pic = {
        TEST_COLORS,
        10, // width
        12, // height
        "rrrrrrrrrr"
        "gggggggggg"
        "bbbbbbbbbb"
        "mmmmmmmmmm"
        "cccccccccc"
        "rrrrrrrrrr"
        "gggggggggg"
        "bbbbbbbbbb"
        "mmmmmmmmmm"
        "cccccccccc"
        "rrrrrrrrrr"
        "gggggggggg"
    };
    struct Image *rect_img = picture_to_img(&rect_pic);
    struct Image *rect_out = (struct Image *)malloc(sizeof(struct Image));
    img_init(rect_out, rect_img->width, rect_img->height);

  int result = imgproc_kaleidoscope(rect_img, rect_out);
  ASSERT(result == 0); // Should fail for non-square image

  destroy_img(rect_img);
  destroy_img(rect_out);
}

void test_helper_functions(TestObjs *objs) {
  // Test pixel manipulation helpers
  uint32_t test_pixel = 0xFF112233; // RGBA: 255,17,34,51
  
  ASSERT(get_r(test_pixel) == 255);
  ASSERT(get_g(test_pixel) == 17);
  ASSERT(get_b(test_pixel) == 34);
  ASSERT(get_a(test_pixel) == 51);
  
  // Test make_pixel
  uint32_t new_pixel = make_pixel(255, 17, 34, 51);
  ASSERT(new_pixel == test_pixel);
  
  // Test compute_index
  struct Image test_img;
  test_img.width = 10;
  test_img.height = 10;
  ASSERT(compute_index(&test_img, 5, 6) == 65); // 6 * 10 + 5 = 65
}