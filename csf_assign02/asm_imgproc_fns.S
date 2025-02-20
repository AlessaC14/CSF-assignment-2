

/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

/*
 * Implementations of API functions
 */

/*
 * Render an output image containing 4 copies of the original image,
 * refered to as A, B, C, and D in the following diagram:
 *
 *   +---+---+
 *   | A | B |
 *   +---+---+
 *   | C | D |
 *   +---+---+
 *
 * The width and height of the output image are (respectively) twice
 * the width and height of the input image.
 *
 * A is an exact copy of the original input image. B has only the
 * red color component values of the input image, C has only the
 * green color component values, and D has only the blue color component
 * values.
 *
 * Each of the copies (A-D) should use the same alpha values as the
 * original image.
 *
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to the input Image
 *   %rsi - pointer to the output Image (which will have
 *          width and height twice the width/height of the
 *          input image)
 */
	.globl imgproc_rgb
imgproc_rgb:
	/* TODO: implement */
	ret

/*
 * void imgproc_grayscale( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by converting each pixel to grayscale.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	    .globl imgproc_grayscale
imgproc_grayscale:
    # Prologue
    pushq %rbp           # Save old base pointer
    movq %rsp, %rbp      # Create stack frame
    pushq %r12           # Save callee-saved registers
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r14      # r14 = input_img pointer
    movq %rsi, %r15      # r15 = output_img pointer

    movl (%r14), %r12d   # r12 = width
    movl 4(%r14), %r13d  # r13 = height

    xor %r8d, %r8d       # i = 0 (row counter)
.loop_rows: 
    cmp %r13d, %r8d      # if i >= height, exit loop
    jge .done

    xor %r9d, %r9d       # j = 0 (column counter)
.loops_cols:
    cmp %r12d, %r9d      # if j >= width, go to next row
    jge .next_row

    # Compute index = (i * width) + j
    imul %r12d, %r8d, %eax  # i * width
    add %r9d, %eax          # (i * width) + j

    # Load pixel from input image
    movl (%r14, %rax, 4), %edx  # pixel = input_img->data[index]

    # Extract R, G, B values
    movl %edx, %ecx     # Copy pixel 
    shr $24, %ecx       # Extract Red
    movl %edx, %ebx     # Copy pixel 
    shr $16, %ebx
    and $0xFF, %ebx     # Extract green
    movl %edx, %edi     # Copy pixel 
    shr $8, %edi
    and $0xFF, %edi     # Extract Blue

    # Compute grayscale value y = (79 * R + 128 * G + 49 * B) / 256
    imul $79, %ecx, %ecx  # 79 * R
    imul $128, %ebx, %ebx # 128 * G
    imul $49, %edi, %edi  # 49 * B
    add %ebx, %ecx        # (79 * R) + (128 * G)
    add %edi, %ecx        # + (49 * B)
    shr $8, %ecx          # Diviision by 256

    # Preserve alpha
    and $0xFF, %edx       # Extract alpha
    shl $24, %edx         # Move alpha back
    shl $16, %ecx         # Shift grayscale value to red position
    or %ecx, %edx         # merge Red
    shl $8, %ecx
    or %ecx, %edx         # Merge green and blue

    # Store new grayscale pixel in output_img
    movl %edx, (%r15, %rax, 4)

    inc %r9d             # j++
    jmp .loops_cols

.next_row:
    inc %r8d             # i++
    jmp .loop_rows

.done:
    # Restore callee-saved registers
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    ret

/*
 * Render a "kaleidoscope" transformation of input_img in output_img.
 * The input_img must be square, i.e., the width and height must be
 * the same. Assume that the input image is divided into 8 "wedges"
 * like this:
 *
 *    +----+----+
 *    |\ A |   /|
 *    | \  |  / |
 *    |  \ | /  |
 *    | B \|/   |
 *    +----+----+
 *    |   /|\   |
 *    |  / | \  |
 *    | /  |  \ |
 *    |/   |   \|
 *    +----+----+
 *
 * The wedge labeled "A" is the one that will be replicated 8 times
 * in the output image. In the output image,
 *
 *    Wedge A will have exactly the same pixels as wedge A in
 *    the input image, in the same positions.
 *
 *    Wedge B will have exactly the same pixels as wedge A, but the
 *    column and row are transposed. (I.e., it is a reflection across
 *    the diagonal.)
 *
 *    All other wedges are mirrored versions of A such that the overall
 *    image is symmetrical across all four lines dividing the image
 *    (vertical split, horizontal split, and the two diagonal splits.)
 *
 * Parameters:
 *   input_img  - pointer to the input Image
 *   output_img - pointer to the output Image (in which the transformed
 *                pixels should be stored)
 *
 * Returns:
 *   1 if successful, 0 if the transformation fails because the
 *   width and height of input_img are not the same.
 */
	.globl imgproc_kaleidoscope
imgproc_kaleidoscope:
	/* TODO: implement */
	ret

	/* This avoids linker warning about executable stack */
.section .note.GNU-stack,"",@progbits

/*
vim:ft=gas:
*/
