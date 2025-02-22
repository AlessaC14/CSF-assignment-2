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
	shll $24, %eax        /* Shift red to bits 24-31 */
	movl %esi, %r10d      /* Get green value */
	shll $16, %r10d       /* Shift green to bits 16-23 */
	orl %r10d, %eax       /* Combine with result */
	movl %edx, %r10d      /* Get blue value */
	shll $8, %r10d        /* Shift blue to bits 8-15 */
	orl %r10d, %eax       /* Combine with result */
	orl %ecx, %eax        /* Add alpha (already in bits 0-7) */
	ret

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
	# Prologue
	pushq   %rbp
	movq    %rsp, %rbp
	subq    $48, %rsp
	
	# Save callee-saved registers
	pushq   %rbx
	pushq   %r12
	pushq   %r13
	pushq   %r14
	pushq   %r15

	# Store input/output pointers
	movq    %rdi, %r14          # r14 = input_img
	movq    %rsi, %r15          # r15 = output_img

	# Set output dimensions
	movl    (%r14), %eax        # input width
	movl    %eax, %r12d         # save input width
	shll    $1, %eax            # multiply by 2
	movl    %eax, (%r15)        # store output width
	movl    %eax, %ebx          # save output width
	
	movl    4(%r14), %eax       # input height  
	movl    %eax, %r13d         # save input height
	shll    $1, %eax            # multiply by 2
	movl    %eax, 4(%r15)       # store output height

	# Calculate memory size and allocate
	movl    (%r15), %eax        # output width
	imull   4(%r15), %eax       # multiply by height
	shll    $2, %eax            # multiply by 4 for bytes
	
	movq    %rax, %rdi          # size to allocate
	call    malloc
	testq   %rax, %rax          # check if malloc failed
	je      .rgb_done
	
	movq    %rax, 8(%r15)       # store data pointer
	movq    %rax, %r9           # r9 = output data
	movq    8(%r14), %r8        # r8 = input data

	# Process rows
	xorl    %r10d, %r10d        # r10d = row counter (i)
.rgb_row_loop:
	cmpl    %r13d, %r10d        # compare with input height
	jge     .rgb_done
	
	# Process columns
	xorl    %r11d, %r11d        # r11d = column counter (j)
.rgb_col_loop:
	cmpl    %r12d, %r11d        # compare with input width
	jge     .rgb_next_row

	# Calculate input index
	movl    %r10d, %eax         # row
	imull   %r12d, %eax         # multiply by input width
	addl    %r11d, %eax         # add column
	movl    (%r8,%rax,4), %ecx  # load input pixel
	movl    %ecx, -20(%rbp)     # save original pixel

	# Extract components
	movl    %ecx, %edi
	call    get_r
	movl    %eax, -4(%rbp)      # red
	
	movl    -20(%rbp), %edi
	call    get_g  
	movl    %eax, -8(%rbp)      # green
	
	movl    -20(%rbp), %edi
	call    get_b
	movl    %eax, -12(%rbp)     # blue
	
	movl    -20(%rbp), %edi
	call    get_a
	movl    %eax, -16(%rbp)     # alpha

	# Calculate base output index
	movl    %r10d, %eax         # row
	imull   %ebx, %eax          # multiply by output width
	addl    %r11d, %eax         # add column
	
	# Quadrant A: Original
	movl    -20(%rbp), %edx     # original pixel
	movl    %edx, (%r9,%rax,4)  # store in output
	
	# Quadrant B: Red only
	movl    -4(%rbp), %edi      # red
	xorl    %esi, %esi          # green = 0
	xorl    %edx, %edx          # blue = 0
	movl    -16(%rbp), %ecx     # alpha
	pushq   %rax                # save index
	call    make_pixel
	popq    %rdx                # restore index to rdx
	addl    %r12d, %edx         # add input width for B
	movl    %eax, (%r9,%rdx,4)  # store pixel
	
	# Quadrant C: Green only
	movl    %r10d, %eax         # recalculate base index
	addl    %r13d, %eax         # add input height for C
	imull   %ebx, %eax          # multiply by output width
	addl    %r11d, %eax         # add column
	
	xorl    %edi, %edi          # red = 0
	movl    -8(%rbp), %esi      # green
	xorl    %edx, %edx          # blue = 0
	movl    -16(%rbp), %ecx     # alpha
	pushq   %rax                # save index
	call    make_pixel
	popq    %rdx                # restore index
	movl    %eax, (%r9,%rdx,4)  # store pixel
	
	# Quadrant D: Blue only
	addl    %r12d, %edx         # add input width for D
	
	xorl    %edi, %edi          # red = 0
	xorl    %esi, %esi          # green = 0
	movl    -12(%rbp), %edx     # blue
	movl    -16(%rbp), %ecx     # alpha
	pushq   %rdx                # save index
	call    make_pixel
	popq    %rdx                # restore index
	movl    %eax, (%r9,%rdx,4)  # store pixel

	incl    %r11d               # next column
	jmp     .rgb_col_loop

.rgb_next_row:
	incl    %r10d               # next row
	jmp     .rgb_row_loop

.rgb_done:
	# Restore registers and stack
	popq    %r15
	popq    %r14  
	popq    %r13
	popq    %r12
	popq    %rbx
	movq    %rbp, %rsp
	popq    %rbp
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
	pushq   %rbp
	movq    %rsp, %rbp
	
	# Save callee-saved registers
	pushq   %rbx
	pushq   %r12
	pushq   %r13
	pushq   %r14
	pushq   %r15
	
	# Store parameters
	movq    %rdi, %r14          # input image
	movq    %rsi, %r15          # output image
	
	# Copy dimensions
	movl    (%r14), %eax        # width
	movl    %eax, (%r15)
	movl    4(%r14), %edx       # height
	movl    %edx, 4(%r15)
	
	# Calculate size
	imull   %edx, %eax          # width * height
	movl    %eax, %ebx          # save total pixels
	shll    $2, %eax            # multiply by 4 for bytes
	
	# Allocate memory
	movq    %rax, %rdi
	call    malloc
	testq   %rax, %rax          # check if malloc failed
	je      .grayscale_done
	
	movq    %rax, 8(%r15)       # store data pointer
	movq    8(%r14), %r12       # input data
	movq    %rax, %r13          # output data
	
	# Process pixels
	xorl    %ecx, %ecx          # pixel counter

.grayscale_loop:
	cmpl    %ebx, %ecx          # check if done
	jge     .grayscale_done
	
	movl    (%r12,%rcx,4), %edi # load input pixel
	call    to_grayscale        # convert to grayscale
	movl    %eax, (%r13,%rcx,4) # store result
	
	incl    %ecx                # next pixel
	jmp     .grayscale_loop

.grayscale_done:
	# Restore registers and stack
	popq    %r15
	popq    %r14
	popq    %r13
	popq    %r12
	popq    %rbx
	popq    %rbp
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

/*
vim:ft=gas:
*/