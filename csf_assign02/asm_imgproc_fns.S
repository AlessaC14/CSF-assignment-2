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
	shll $8, %eax         /* Shift left 8 bits to make room for green */
	orl %esi, %eax        /* Add green value */
	shll $8, %eax         /* Shift left 8 bits to make room for blue */
	orl %edx, %eax        /* Add blue value */
	shll $8, %eax         /* Shift left 8 bits to make room for alpha */
	orl %ecx, %eax        /* Add alpha value */
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