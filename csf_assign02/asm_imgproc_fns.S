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
	# Prologue: Set up an ABI-compliant stack frame and reserve 48 bytes
	# for local variables:
	#   -4(%rbp)   : red component (32-bit)
	#   -8(%rbp)   : green component
	#   -12(%rbp)  : blue component
	#   -16(%rbp)  : alpha component
	#   -20(%rbp)  : original pixel value (32-bit) for quadrant A
	#   -24(%rbp)  : temporary storage for quadrant B index (in pixels)
	#   -28(%rbp)  : temporary storage for quadrant C index (in pixels)
	#   -32(%rbp)  : temporary storage for quadrant D index (in pixels)
	pushq   %rbp
	movq    %rsp, %rbp
	subq    $48, %rsp

	# Save callee-saved registers: rbx, r12, r13, r14, r15
	pushq   %rbx
	pushq   %r12
	pushq   %r13
	pushq   %r14
	pushq   %r15

	# Parameters:
	#   %rdi = pointer to input Image
	#   %rsi = pointer to output Image
	movq    %rdi, %r14        # r14 = input_img
	movq    %rsi, %r15        # r15 = output_img

	# Set new dimensions:
	# output width = 2 * input width; output height = 2 * input height.
	# The struct Image:
	#   offset 0: width (int32_t)
	#   offset 4: height (int32_t)
	#   offset 8: data pointer (uint32_t *)
	movl    0(%r14), %eax     # eax = input width
	movl    %eax, %r12d       # r12d = input width (save for later)
	imul    $2, %eax          # eax = 2 * input width
	movl    %eax, 0(%r15)     # output_img->width = new width

	movl    4(%r14), %eax     # eax = input height
	movl    %eax, %r13d       # r13d = input height (save for later)
	imul    $2, %eax          # eax = 2 * input height
	movl    %eax, 4(%r15)     # output_img->height = new height

	# Save new width in rbx for use in output index calculations.
	movl    0(%r15), %ebx     # ebx = new width

	# Allocate memory for the output image:
	# Total pixels = new_width * new_height; each pixel is 4 bytes.
	movl    0(%r15), %eax     # eax = new width
	imul    4(%r15), %eax     # eax = new width * new height
	shll    $2, %eax          # eax = total bytes required
	movq    %rax, %rdi        # argument for malloc
	call    malloc
	testq   %rax, %rax
	je      .imgproc_rgb_done    # if malloc returned NULL, exit
	movq    %rax, 8(%r15)     # output_img->data = pointer from malloc

	# Load pointers:
	movq    8(%r14), %r8      # r8 = input_img->data
	movq    8(%r15), %r9      # r9 = output_img->data

	# Outer loop: iterate over rows of input image (row index i in r10d)
	xorl    %r10d, %r10d      # r10d = 0 (i = 0)
.rgb_row_loop:
	cmpl    %r13d, %r10d      # Compare i with input height
	jge     .imgproc_rgb_done # if i >= input height, done

	# Inner loop: iterate over columns of input image (column index j in r11d)
	xorl    %r11d, %r11d      # r11d = 0 (j = 0)
.rgb_col_loop:
	cmpl    %r12d, %r11d      # Compare j with input width
	jge     .rgb_next_row     # if j >= input width, next row

	# Compute input pixel index = i * input_width + j.
	# Then compute byte offset = index * 4.
	movl    %r10d, %eax       # eax = i
	imull   %r12d, %eax       # eax = i * input_width
	addl    %r11d, %eax       # eax = i * input_width + j
	# For input pixel, multiply index by 4:
	movl    %eax, %edx        # edx = index (in pixels)
	shll    $2, %edx         # edx = index * 4 (byte offset)
	# Load input pixel from input image data.
	movl    (%r8, %rdx, 1), %ecx  # ecx = input pixel
	# Save original pixel for quadrant A.
	movl    %ecx, -20(%rbp)

	# Extract color components via helper functions.
	# Save red at -4(%rbp), green at -8(%rbp), blue at -12(%rbp),
	# alpha at -16(%rbp).
	# Get red:
	pushq   %rdi
	movl    %ecx, %edi
	call    get_r           # returns red in %eax
	movl    %eax, -4(%rbp)
	popq    %rdi

	# Get green:
	pushq   %rdi
	movl    %ecx, %edi
	call    get_g           # returns green in %eax
	movl    %eax, -8(%rbp)
	popq    %rdi

	# Get blue:
	pushq   %rdi
	movl    %ecx, %edi
	call    get_b           # returns blue in %eax
	movl    %eax, -12(%rbp)
	popq    %rdi

	# Get alpha:
	pushq   %rdi
	movl    %ecx, %edi
	call    get_a           # returns alpha in %eax
	movl    %eax, -16(%rbp)
	popq    %rdi

	# Quadrant A (upper-left): Copy original pixel.
	# Output coordinate: (j, i)
	# Compute index_A = i * new_width + j.
	movl    %r10d, %eax       # eax = i
	imull   %ebx, %eax        # eax = i * new_width (new width in ebx)
	addl    %r11d, %eax       # eax = i * new_width + j
	# Use scale factor 4 to compute byte offset in output.
	# Store the original pixel (from -20(%rbp)) into output.
	movl    -20(%rbp), %edx   # edx = original pixel
	movl    %edx, (%r9, %rax, 4)

	# Quadrant B (upper-right): Only red channel.
	# Output coordinate: (j + input_width, i)
	# Compute index_B = i * new_width + (j + input_width).
	movl    %r10d, %eax       # eax = i
	imull   %ebx, %eax        # eax = i * new_width
	addl    %r11d, %eax       # eax = i * new_width + j
	addl    %r12d, %eax       # add input width -> index_B
	# Save index_B in local variable.
	movl    %eax, -24(%rbp)
	# Build pixel for quadrant B: (red, 0, 0, alpha)
	movl    -4(%rbp), %edi    # red component in edi
	movl    $0, %esi          # green = 0
	movl    $0, %edx          # blue = 0
	movl    -16(%rbp), %ecx   # alpha in ecx
	call    make_pixel        # returns pixel in %eax
	# Retrieve index_B and store pixel.
	movl    -24(%rbp), %edx   # edx = index_B (in pixels)
	movl    %eax, (%r9, %rdx, 4)  # store quadrant B pixel

	# Quadrant C (lower-left): Only green channel.
	# Output coordinate: (j, i + input_height)
	# Compute index_C = (i + input_height) * new_width + j.
	movl    %r10d, %eax       # eax = i
	addl    %r13d, %eax       # eax = i + input_height
	imull   %ebx, %eax        # eax = (i + input_height) * new_width
	addl    %r11d, %eax       # add j -> index_C
	movl    %eax, -28(%rbp)   # save index_C
	# Build pixel for quadrant C: (0, green, 0, alpha)
	movl    $0, %edi          # red = 0
	movl    -8(%rbp), %esi    # green component
	movl    $0, %edx          # blue = 0
	movl    -16(%rbp), %ecx   # alpha
	call    make_pixel        # returns pixel in %eax
	# Retrieve index_C and store pixel.
	movl    -28(%rbp), %edx   # edx = index_C (in pixels)
	movl    %eax, (%r9, %rdx, 4)  # store quadrant C pixel

	# Quadrant D (lower-right): Only blue channel.
	# Output coordinate: (j + input_width, i + input_height)
	# Compute index_D = (i + input_height) * new_width + (j + input_width).
	movl    %r10d, %eax       # eax = i
	addl    %r13d, %eax       # eax = i + input_height
	imull   %ebx, %eax        # eax = (i + input_height) * new_width
	addl    %r11d, %eax       # add j
	addl    %r12d, %eax       # add input width -> index_D
	movl    %eax, -32(%rbp)   # save index_D
	# Build pixel for quadrant D: (0, 0, blue, alpha)
	movl    $0, %edi          # red = 0
	movl    $0, %esi          # green = 0
	movl    -12(%rbp), %edx   # blue component
	movl    -16(%rbp), %ecx   # alpha
	call    make_pixel        # returns pixel in %eax
	# Retrieve index_D and store pixel.
	movl    -32(%rbp), %edx   # edx = index_D (in pixels)
	movl    %eax, (%r9, %rdx, 4)  # store quadrant D pixel

	# End inner loop: increment column index (j).
	incl    %r11d
	jmp     .rgb_col_loop

.rgb_next_row:
	# End of row: increment row index (i) and restart inner loop.
	incl    %r10d
	jmp     .rgb_row_loop

.imgproc_rgb_done:
	# Epilogue: restore registers and stack frame.
	addq    $48, %rsp
	popq    %r15
	popq    %r14
	popq    %r13
	popq    %r12
	popq    %rbx
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
	/* Prologue */
	pushq %rbp                /* Save old base pointer */
	movq %rsp, %rbp           /* Set up new stack frame */
	subq $16, %rsp            /* Align stack and reserve space for local vars */
	pushq %r12                /* Save callee saved registers */
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	
	/* Store parameters in callee-saved registers */
	movq %rdi, %r14           /* r14 = input_img */
	movq %rsi, %r15           /* r15 = output_img */
	
	/* Copy dimensions */
	movl (%r14), %eax         /* Get input width */
	movl %eax, (%r15)         /* Set output width */
	movl 4(%r14), %eax        /* Get input height */
	movl %eax, 4(%r15)        /* Set output height */
	
	/* Calculate size for memory allocation */
	imull 4(%r15), %eax       /* width * height */
	movl %eax, %ebx           /* Save total pixels */
	shlq $2, %rax             /* Multiply by 4 (sizeof uint32_t) */
	
	/* Allocate memory */
	movq %rax, %rdi           /* Size to allocate */
	call malloc
	testq %rax, %rax          /* Check if malloc returned NULL */
	je .grayscale_done        /* If nill exit function */
	
	/* Store data pointer */
	movq %rax, 8(%r15)        /* output_img->data = allocated memory */
	
	/* Initialize loop counters */
	xorl %r12d, %r12d         /* i = 0 (start row counter) */
	
.grayscale_row_loop:
	cmpl 4(%r14), %r12d       /* Compare i with height */
	jge .grayscale_done       /* If i >= height, done */
	
	xorl %r13d, %r13d         /* j = 0 (startcolumn counter) */
	
.grayscale_col_loop:
	cmpl (%r14), %r13d        /* Compare j with width */
	jge .grayscale_next_row   /* If j >= width, next row */
	
	/* Calculate index = i * width + j */
	movq %r14, %rdi           /* input_img pointer */
	movl %r13d, %esi          /* column (j) */
	movl %r12d, %edx          /* row (i) */
	call compute_index
	movl %eax, -4(%rbp)       /* Store index in local variable */
	
	/* Get pixel from input image */
	movq 8(%r14), %rcx        /* Get input data pointer */
	movl -4(%rbp), %eax       /* Get index */
	movl (%rcx,%rax,4), %edi  /* Load pixel value */
	
	/* Convert to grayscale */
	call to_grayscale
	
	/* Store result in output image */
	movq 8(%r15), %rcx        /* Get output data pointer */
	movl -4(%rbp), %edx       /* Get index */
	movl %eax, (%rcx,%rdx,4)  /* Store grayscale pixel */
	
	incl %r13d                /* j++ */
	jmp .grayscale_col_loop   /* Continue column loop */
	
.grayscale_next_row:
	incl %r12d                /* i++ */
	jmp .grayscale_row_loop   /* Continue row loop */
	
.grayscale_done:
	/* Epilogue */
	popq %rbx                 /* Restore callee-saved registers */
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	addq $16, %rsp            /* Clean up  frame */
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

/*
vim:ft=gas:
*/