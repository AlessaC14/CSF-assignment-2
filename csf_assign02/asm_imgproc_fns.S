/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * Helper functions implementation
 */

/*
 * Extract red component (bits 24-31) from the pixel
 * 
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   %eax - red component (0-255)
 */
	.globl get_r
get_r:
	movl %edi, %eax       /* Copy pixel to result register */
	shrl $24, %eax        /* Shift right 24 bits to get red in lowest byte */
	andl $0xFF, %eax      /* Mask to ensure only lowest byte remains */
	ret

/*
 * Extract green component (bits 16-23) from the pixel
 * 
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   %eax - green component (0-255)
 */
	.globl get_g
get_g:
	movl %edi, %eax       /* Copy pixel to result register */
	shrl $16, %eax        /* Shift right 16 bits to get green in lowest byte */
	andl $0xFF, %eax      /* Mask to ensure only lowest byte remains */
	ret

/*
 * Extract blue component (bits 8-15) from the pixel
 * 
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   %eax - blue component (0-255)
 */
	.globl get_b
get_b:
	movl %edi, %eax       /* Copy pixel to result register */
	shrl $8, %eax         /* Shift right 8 bits to get blue in lowest byte */
	andl $0xFF, %eax      /* Mask to ensure only lowest byte remains */
	ret

/*
 * Extract alpha component (bits 0-7) from the pixel
 * 
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   %eax - alpha component (0-255)
 */
	.globl get_a
get_a:
	movl %edi, %eax       /* Copy pixel to result register */
	andl $0xFF, %eax      /* Mask to ensure only lowest byte remains */
	ret

/*
 * Create pixel from individual color components
 * 
 * Parameters:
 *   %edi - red component (0-255)
 *   %esi - green component (0-255)
 *   %edx - blue component (0-255)
 *   %ecx - alpha component (0-255)
 *
 * Returns:
 *   %eax - combined RGBA pixel
 */
	.globl make_pixel
make_pixel:
    movl %edi, %eax       /* Start with red value */
    shll $24, %eax        /* Shift left 24 bits to get red in position */
    movl %esi, %edx       /* Get green value */
    shll $16, %edx        /* Shift left 16 bits for green */
    orl %edx, %eax        /* Add green */
    movl %edx, %edx       /* Get blue value - THIS IS WRONG */
    shll $8, %edx         /* Shift left 8 bits for blue */
    orl %edx, %eax        /* Add blue */
    orl %ecx, %eax        /* Add alpha (already in position 0-7) */

/*
 * Convert pixel to grayscale using formula:
 * y = (79 * r + 128 * g + 49 * b) / 256
 * 
 * Parameters:
 *   %edi - RGBA pixel
 *
 * Returns:
 *   %eax - grayscale pixel with same alpha
 */
	.globl to_grayscale
to_grayscale:
	/* Save callee-saved registers */
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx            /* Save rbx as we'll use it */
	pushq %r12            /* Save r12 as we'll use it */
	
	/* Save original pixel */
	movl %edi, %r12d
	
	/* Get red component */
	call get_r
	movl %eax, %ebx       /* Save red in ebx */
	
	/* Get green component */
	movl %r12d, %edi
	call get_g
	movl %eax, %r10d      /* Save green in r10d */
	
	/* Get blue component */
	movl %r12d, %edi
	call get_b
	movl %eax, %r11d      /* Save blue in r11d */
	
	/* Get alpha component */
	movl %r12d, %edi
	call get_a
	movl %eax, %r12d      /* Save alpha in r12d */
	
	/* Calculate y = (79 * r + 128 * g + 49 * b) / 256 */
	imull $79, %ebx, %ebx   /* 79 * red */
	imull $128, %r10d, %r10d/* 128 * green */
	imull $49, %r11d, %r11d /* 49 * blue */
	
	addl %r10d, %ebx        /* Add green component */
	addl %r11d, %ebx        /* Add blue component */
	shrl $8, %ebx           /* Divide by 256 */
	
	/* Create new grayscale pixel */
	movl %ebx, %edi       /* Set red to y */
	movl %ebx, %esi       /* Set green to y */
	movl %ebx, %edx       /* Set blue to y */
	movl %r12d, %ecx      /* Set original alpha */
	call make_pixel
	
	/* Restore callee-saved registers */
	popq %r12
	popq %rbx
	popq %rbp
	ret

/*
 * Compute index in pixel array for a given column and row
 *
 * Parameters:
 *   %rdi - pointer to Image struct
 *   %esi - column index
 *   %edx - row index
 *
 * Returns:
 *   %eax - computed index (row * width + col)
 */
	.globl compute_index
compute_index:
	movl %edx, %eax       /* Start with row */
	imull (%rdi), %eax    /* Multiply by width */
	addl %esi, %eax       /* Add column */
	ret


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
    # Prologue with correct alignment
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    subq    $48, %rsp        # Local vars space
    subq    $8, %rsp         # Extra alignment

    # Save parameters
    movq    %rdi, %r14        # r14 = input_img
    movq    %rsi, %r15        # r15 = output_img

    # Set dimensions
    movl    (%r14), %eax      # input width
    movl    %eax, %r12d       # save input width
    imul    $2, %eax          # double width
    movl    %eax, (%r15)      # store output width

    movl    4(%r14), %eax     # input height
    movl    %eax, %r13d       # save input height
    imul    $2, %eax          # double height
    movl    %eax, 4(%r15)     # store output height

    # Save new width for indexing
    movl    (%r15), %ebx      # new width

    # Allocate memory
    movl    (%r15), %eax      # width
    imull   4(%r15), %eax     # multiply by height
    shll    $2, %eax          # multiply by 4 for bytes
    movq    %rax, %rdi        # setup malloc arg
    call    malloc
    testq   %rax, %rax        # check if malloc failed
    je      .imgproc_rgb_done

    # Store allocated pointer
    movq    %rax, 8(%r15)     # store allocated pointer

    # Get data pointers
    movq    8(%r14), %r8      # input data
    movq    8(%r15), %r9      # output data

    # Row loop
    xorl    %r10d, %r10d      # row = 0
.rgb_row_loop:
    cmpl    %r13d, %r10d      # compare with height
    jge     .imgproc_rgb_done

    # Column loop
    xorl    %r11d, %r11d      # col = 0
.rgb_col_loop:
    cmpl    %r12d, %r11d      # compare with width
    jge     .rgb_next_row

    # Get input pixel
    movl    %r10d, %eax       # row
    imull   %r12d, %eax       # multiply by width
    addl    %r11d, %eax       # add column
    movl    %eax, %edx        # save index
    shll    $2, %edx          # multiply by 4 for bytes
    movl    (%r8,%rdx), %ecx  # load pixel
    movl    %ecx, -20(%rbp)   # save original pixel

    # Extract color components safely
    movq    %rdi, %r13        # Save original rdi
    
    movl    %ecx, %edi        # Setup for color extraction
    call    get_r             # Get red
    movl    %eax, -4(%rbp)    # Save red

    movl    %ecx, %edi        # Restore pixel value
    call    get_g             # Get green
    movl    %eax, -8(%rbp)    # Save green

    movl    %ecx, %edi        # Restore pixel value
    call    get_b             # Get blue
    movl    %eax, -12(%rbp)   # Save blue

    movl    %ecx, %edi        # Restore pixel value
    call    get_a             # Get alpha
    movl    %eax, -16(%rbp)   # Save alpha

    movq    %r13, %rdi        # Restore original rdi

    # Store quadrant A (original)
    movl    %r10d, %eax       # row
    imull   %ebx, %eax        # multiply by new width
    addl    %r11d, %eax       # add column
    movl    -20(%rbp), %edx   # get original pixel
    movl    %edx, (%r9,%rax,4)

    # Store quadrant B (red)
    movl    %r10d, %eax       # row
    imull   %ebx, %eax        # multiply by new width
    addl    %r11d, %eax       # add column
    addl    %r12d, %eax       # offset by input width
    movl    %eax, -24(%rbp)   # save index
    movl    -4(%rbp), %edi    # red
    xorl    %esi, %esi        # green = 0
    xorl    %edx, %edx        # blue = 0
    movl    -16(%rbp), %ecx   # alpha
    call    make_pixel
    movl    -24(%rbp), %edx
    movl    %eax, (%r9,%rdx,4)

    # Store quadrant C (green)
    movl    %r10d, %eax       # row
    addl    %r13d, %eax       # offset by input height
    imull   %ebx, %eax        # multiply by new width
    addl    %r11d, %eax       # add column
    movl    %eax, -28(%rbp)   # save index
    xorl    %edi, %edi        # red = 0
    movl    -8(%rbp), %esi    # green
    xorl    %edx, %edx        # blue = 0
    movl    -16(%rbp), %ecx   # alpha
    call    make_pixel
    movl    -28(%rbp), %edx
    movl    %eax, (%r9,%rdx,4)

    # Store quadrant D (blue)
    movl    %r10d, %eax       # row
    addl    %r13d, %eax       # offset by input height
    imull   %ebx, %eax        # multiply by new width
    addl    %r11d, %eax       # add column
    addl    %r12d, %eax       # offset by input width
    movl    %eax, -32(%rbp)   # save index
    xorl    %edi, %edi        # red = 0
    xorl    %esi, %esi        # green = 0
    movl    -12(%rbp), %edx   # blue
    movl    -16(%rbp), %ecx   # alpha
    call    make_pixel
    movl    -32(%rbp), %edx
    movl    %eax, (%r9,%rdx,4)

    # Next column
    incl    %r11d
    jmp     .rgb_col_loop

.rgb_next_row:
    incl    %r10d
    jmp     .rgb_row_loop

.imgproc_rgb_done:
    # Epilogue
    addq    $8, %rsp          # Remove alignment padding
    addq    $48, %rsp         # Remove local vars space
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret

# imgproc_grayscale
# Converts input pixels to grayscale using the formula:
# y = (79 * r + 128 * g + 49 * b) / 256
#
# Parameters:
#   %rdi - pointer to struct Image (input_img)
#   %rsi - pointer to struct Image (output_img)
        .globl imgproc_grayscale
imgproc_grayscale:
    # Standard function prologue
    pushq %rbp
    movq %rsp, %rbp

    # Save callee-saved registers
    pushq %rbx            # column counter
    pushq %r12            # row counter
    pushq %r13            # store pixel index
    pushq %r14            # input_img pointer
    pushq %r15            # output_img pointer
    subq $8, %rsp        # maintain 16-byte alignment

    # Save function parameters
    movq %rdi, %r14       # r14 = input_img
    movq %rsi, %r15       # r15 = output_img

    # Copy dimensions from input to output
    movl (%r14), %eax     # input width
    movl %eax, (%r15)     # output width
    movl 4(%r14), %eax    # input height
    movl %eax, 4(%r15)    # output height

    # Calculate size for malloc (width * height * 4 bytes per pixel)
    movl (%r15), %eax     # width
    imull 4(%r15), %eax   # width * height
    movl %eax, %r13d      # store total pixels
    shll $2, %eax         # multiply by 4 (each pixel is 4 bytes)

    # Allocate memory for output image
    movq %rax, %rdi       # argument to malloc (size)
    call malloc 
    testq %rax, %rax      # check if malloc failed
    je .grayscale_error   # if malloc failed, jump to error handler

    # Store allocated pointer in output_img->data
    movq %rax, 8(%r15)

    # Initialize row counter (i = 0)
    xorl %r12d, %r12d     # r12d = row = 0

.row_loop:
    cmpl 4(%r14), %r12d   # compare row with height
    jge .grayscale_done   # if row >= height, exit loop

    # Initialize column counter (j = 0)
    xorl %ebx, %ebx       # ebx = col = 0

.col_loop:
    cmpl (%r14), %ebx     # compare col with width
    jge .next_row         # if col >= width, go to next row

    # Compute pixel index = i * width + j
    movq %r14, %rdi       # input_img pointer
    movl %ebx, %esi       # col (j)
    movl %r12d, %edx      # row (i)
    call compute_index    # compute index
    movl %eax, %r13d      # store index in r13d

    # Load pixel from input image
    movq 8(%r14), %rsi    # input data pointer
    movl (%rsi,%r13,4), %edi  # load pixel into edi

    # Convert to grayscale
    pushq %rax            # save index
    call to_grayscale     # convert pixel
    popq %rdx             # restore index (to different register)

    # Store grayscale pixel in output image
    movq 8(%r15), %rsi    # output data pointer
    movl %eax, (%rsi,%rdx,4)  # store transformed pixel

    # Move to next column
    incl %ebx
    jmp .col_loop

.next_row:
    incl %r12d            # increment row counter
    jmp .row_loop

.grayscale_error:
    # Handle allocation failure
    xorl %eax, %eax       # clear return value
    jmp .grayscale_cleanup

.grayscale_done:
    movl $1, %eax         # return success

.grayscale_cleanup:
    # Restore stack and registers (function epilogue)
    addq $8, %rsp         # restore stack alignment
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

 

/*
 * Stub implementation for imgproc_fade (to be implemented )
 */
.globl imgproc_fade
imgproc_fade:
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

/* vim: set ft=gas: */

