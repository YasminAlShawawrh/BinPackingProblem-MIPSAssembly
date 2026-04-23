#Yasmin Al Shawawrh 1220848
#Tasneem Shelleh 1220439
#This code is write the results on a file 
##########################################
.data
menu: .asciiz "\nBin Packing Solver\n1. Enter input file name\n2. Choose heuristic (FF or BF)\n3. Run algorithm and save output to file\nQ. Quit\nEnter your choice: "  # Defines the main menu string
choice: .space 4            # Allocates 4 bytes to store user's menu choice
filename: .space 100        # Allocates 100 bytes to store input file name
heuristic: .space 4         # Allocates 4 bytes to store chosen heuristic (FF or BF)
output_filename: .space 100 # Allocates 100 bytes to store output file name

filename_prompt: .asciiz "\nEnter the input file name: "  # Prompt for input file name
heuristic_prompt: .asciiz "\nChoose heuristic (FF or BF): "  # Prompt for selecting heuristic
output_filename_prompt: .asciiz "\nEnter the output file name: "  # Prompt for output file name
file_not_found: .asciiz "Error: File does not exist.\n"  # Error message for file not found
output_file_error: .asciiz "Error: Couldn't create output file.\n"  # Error message for output file issues
file_read_success: .asciiz "File read successfully!\n"  # Success message for file read
output_done_msg: .asciiz "Output written to file successfully.\n"  # Success message for file write
invalid_content: .asciiz "Error: File contains invalid data.\n"  # Error message for invalid file content
valid_content: .asciiz "All values are valid floats between 0 and 1.\n"  # Success message for valid file content
ff_message: .asciiz "\nPerforming First Fit heuristic...\n"  # Message when running First Fit
bf_message: .asciiz "\nPerforming Best Fit heuristic...\n"  # Message when running Best Fit
bin_count_msg: .asciiz "Total bins used: "  # Message prefix for bin count
total_bins_msg: .asciiz "Total bins used: "  # Another message prefix for bin count
newline: .asciiz "\n"  # Newline character string
print_items_msg: .asciiz "Parsed items:\n"  # Message prefix for displaying parsed items
one_float: .float 1.0  # Floating point constant 1.0
one_point_one: .float 1.1  # Floating point constant 1.1
buffer: .space 256  # Buffer for file I/O operations
file_descriptor: .word -1  # File descriptor for input file
output_descriptor: .word -1  # File descriptor for output file
bin_label: .asciiz "Bin "  # Label prefix for bins
colon: .asciiz ": "  # Colon string for formatting output
item_value: .asciiz "  "  # Spaces for formatting output
plus_sign: .asciiz " + "  # Plus sign for formatting output
equals_sign: .asciiz " = "  # Equals sign for formatting output
zero_float: .float 0.0  # Floating point constant 0.0
item_str: .asciiz "\nitem "  # Label for item in output
in_bin_str: .asciiz " in bin"  # Text for showing bin assignment
space_str: .asciiz " "  # Space character string
.align 2  # Align next data to word boundary
items: .space 1024  # Array to store item values (each 4 bytes)
bins: .space 1024  # Array to store bin fill levels (each 4 bytes)
bin_map: .space 400  # Array to map items to bins (each 4 bytes)
output_buffer: .space 1024  # Buffer for building output text

.text
main:  # Main program entry point
loop:  # Main program loop for menu
    li $v0, 4  # Load syscall code for print string
    la $a0, menu  # Load address of menu string
    syscall  # Display menu

    li $v0, 8  # Load syscall code for read string
    la $a0, choice  # Load address to store user's choice
    li $a1, 2  # Read max 2 characters (1 char + null)
    syscall  # Read user's choice

    lb $t0, choice  # Load the first byte of choice
    li $t1, 'q'  # Load ASCII value of 'q'
    li $t2, 'Q'  # Load ASCII value of 'Q'
    beq $t0, $t1, exit  # If choice is 'q', exit
    beq $t0, $t2, exit  # If choice is 'Q', exit

    li $t3, '1'  # Load ASCII value of '1'
    beq $t0, $t3, get_filename  # If choice is '1', go to get_filename

    li $t4, '2'  # Load ASCII value of '2'
    beq $t0, $t4, get_heuristic  # If choice is '2', go to get_heuristic
    
    li $t3, '3'  # Load ASCII value of '3'
    beq $t0, $t3, run_and_save  # If choice is '3', go to run_and_save

    j loop  # Invalid choice, loop back to menu

get_filename:  # Handle option 1: get input filename
    li $v0, 4  # Load syscall code for print string
    la $a0, filename_prompt  # Load address of filename prompt
    syscall  # Display prompt

    li $v0, 8  # Load syscall code for read string
    la $a0, filename  # Load address to store filename
    li $a1, 100  # Read max 100 characters
    syscall  # Read filename

    la $t0, filename  # Load address of filename
remove_newline_input:  # Remove newline from input
    lb $t1, 0($t0)  # Load byte from address in $t0
    beqz $t1, after_trim_input  # If byte is null, end of string reached
    li $t2, 10  # Load ASCII value of newline
    beq $t1, $t2, replace_null_input  # If byte is newline, replace with null
    addi $t0, $t0, 1  # Move to next byte
    j remove_newline_input  # Continue loop

replace_null_input:  # Replace newline with null terminator
    sb $zero, 0($t0)  # Store null byte at current position

after_trim_input:  # After trimming newline from input
    li $v0, 13  # Load syscall code for open file
    la $a0, filename  # Load address of filename
    li $a1, 0  # Open for reading (mode 0)
    li $a2, 0  # Ignored for reading
    syscall  # Open file
    move $s0, $v0  # Save file descriptor
    bltz $s0, file_error  # If descriptor negative, file error

    li $v0, 14  # Load syscall code for read file
    move $a0, $s0  # Move file descriptor to $a0
    la $a1, buffer  # Load address of buffer
    li $a2, 256  # Read max 256 bytes
    syscall  # Read from file
    move $s1, $v0  # Save number of bytes read

    li $v0, 16  # Load syscall code for close file
    move $a0, $s0  # Move file descriptor to $a0
    syscall  # Close file
    
    li $v0, 4  # Load syscall code for print string
    la $a0, file_read_success  # Load address of success message
    syscall  # Display success message

    la $a0, buffer  # Load address of buffer with file content
    move $a1, $s1  # Move number of bytes read to $a1
    jal validate_floats  # Jump to validate_floats function
    beqz $v0, invalid_data  # If returned 0, data invalid

    li $v0, 4  # Load syscall code for print string
    la $a0, valid_content  # Load address of valid content message
    syscall  # Display valid content message

    j loop  # Jump back to main loop

get_heuristic:  # Handle option 2: choose heuristic
    li $v0, 4  # Load syscall code for print string
    la $a0, heuristic_prompt  # Load address of heuristic prompt
    syscall  # Display prompt

    li $v0, 8  # Load syscall code for read string
    la $a0, heuristic  # Load address to store heuristic
    li $a1, 3  # Read max 3 characters (2 chars + null)
    syscall  # Read heuristic choice

    j loop  # Jump back to main loop

run_and_save:  # Handle option 3: run algorithm and save
    # First prompt for output filename
    li $v0, 4  # Load syscall code for print string
    la $a0, output_filename_prompt  # Load address of output filename prompt
    syscall  # Display prompt
    
    li $v0, 8  # Load syscall code for read string
    la $a0, output_filename  # Load address to store output filename
    li $a1, 100  # Read max 100 characters
    syscall  # Read output filename
    
    la $t0, output_filename  # Load address of output filename
remove_newline_output:  # Remove newline from output filename
    lb $t1, 0($t0)  # Load byte from address in $t0
    beqz $t1, after_trim_output  # If byte is null, end of string reached
    li $t2, 10  # Load ASCII value of newline
    beq $t1, $t2, replace_null_output  # If byte is newline, replace with null
    addi $t0, $t0, 1  # Move to next byte
    j remove_newline_output  # Continue loop

replace_null_output:  # Replace newline with null terminator
    sb $zero, 0($t0)  # Store null byte at current position

after_trim_output:  # After trimming newline from output filename
    # Now run algorithm based on chosen heuristic
    lb $t0, heuristic  # Load first byte of heuristic choice
    li $t1, 'F'  # Load ASCII value of 'F'
    li $t2, 'f'  # Load ASCII value of 'f'
    li $t3, 'B'  # Load ASCII value of 'B'
    li $t4, 'b'  # Load ASCII value of 'b'
    beq $t0, $t1, first_fit  # If 'F', go to first_fit
    beq $t0, $t2, first_fit  # If 'f', go to first_fit
    beq $t0, $t3, best_fit  # If 'B', go to best_fit
    beq $t0, $t4, best_fit  # If 'b', go to best_fit
    
    j loop  # Invalid choice, jump back to main loop

####################################
# VALIDATION                       #
####################################
validate_floats:  # Function to validate that input contains valid floats between 0 and 1
    add $t0, $a0, $zero  # Copy buffer address to $t0
    add $t1, $a0, $a1  # Calculate address of end of buffer

parse_next_char:  # Loop to parse next character in buffer
    beq $t0, $t1, all_valid  # If reached end of buffer, all values valid

    lb $t2, 0($t0)  # Load byte from current position
    li $t3, 32  # Load ASCII value of space
    li $t4, 10  # Load ASCII value of newline
    li $t5, 13  # Load ASCII value of carriage return
    beq $t2, $t3, skip  # If space, skip
    beq $t2, $t4, skip  # If newline, skip
    beq $t2, $t5, skip  # If carriage return, skip

    li $t6, '0'  # Load ASCII value of '0'
    beq $t2, $t6, check_dot  # If '0', check for decimal point
    j invalid_value  # Otherwise invalid value

check_dot:  # Check if next character is a decimal point
    lb $t8, 1($t0)  # Load next byte
    li $t9, '.'  # Load ASCII value of '.'
    bne $t8, $t9, invalid_value  # If not '.', invalid value

    lb $s0, 2($t0)  # Load byte after decimal point
    li $s1, '0'  # Load ASCII value of '0'
    li $s2, '9'  # Load ASCII value of '9'
    blt $s0, $s1, invalid_value  # If less than '0', invalid value
    bgt $s0, $s2, invalid_value  # If greater than '9', invalid value

    lb $s3, 3($t0)  # Load next byte after digit
    blt $s3, $s1, skip_ok  # If less than '0', skip to next token
    bgt $s3, $s2, skip_ok  # If greater than '9', skip to next token
    addi $t0, $t0, 1  # Move ahead one byte

skip_ok:  # Skip to next token after valid float
    addi $t0, $t0, 3  # Move ahead three bytes
    j parse_next_char  # Continue parsing

skip:  # Skip over whitespace or control characters
    addi $t0, $t0, 1  # Move to next byte
    j parse_next_char  # Continue parsing

invalid_value:  # Handle invalid value
    li $v0, 0  # Return 0 (false)
    jr $ra  # Return from function

all_valid:  # All values are valid
    li $v0, 1  # Return 1 (true)
    jr $ra  # Return from function

file_error:  # Handle file error
    li $v0, 4  # Load syscall code for print string
    la $a0, file_not_found  # Load address of error message
    syscall  # Display error message
    j loop  # Jump back to main loop

invalid_data:  # Handle invalid data
    li $v0, 4  # Load syscall code for print string
    la $a0, invalid_content  # Load address of error message
    syscall  # Display error message
    j loop  # Jump back to main loop

####################################
# PARSE & STORE ITEMS              #
####################################
parse_items:  # Parse items from input buffer
    la $t0, buffer  # Load address of buffer
    la $t1, items  # Load address of items array
    li $t2, 0  # Initialize item count to 0

parse_float_loop:  # Loop to parse each float
    lb $t3, 0($t0)  # Load byte from buffer
    beqz $t3, end_parse_items  # If null, end of buffer reached
    li $t4, '0'  # Load ASCII value of '0'
    bne $t3, $t4, skip_char  # If not '0', skip character

    lb $t5, 1($t0)  # Load next byte
    li $t6, '.'  # Load ASCII value of '.'
    bne $t5, $t6, skip_char  # If not '.', skip character

    lb $t7, 2($t0)  # Load digit after decimal point
    li $t8, '0'  # Load ASCII value of '0'
    li $t9, '9'  # Load ASCII value of '9'
    blt $t7, $t8, skip_char  # If less than '0', skip character
    bgt $t7, $t9, skip_char  # If greater than '9', skip character

    li $s0, 0  # Initialize accumulator
    li $s1, 10  # Load base 10
    sub $s2, $t7, $t8  # Convert digit to integer
    move $s3, $s2  # Copy value to $s3

    lb $s4, 3($t0)  # Load next byte after first digit
    blt $s4, $t8, store_float  # If not a digit, store float
    bgt $s4, $t9, store_float  # If not a digit, store float

    sub $s5, $s4, $t8  # Convert second digit to integer
    mul $s3, $s3, $s1  # Multiply first digit by 10
    add $s3, $s3, $s5  # Add second digit

store_float:  # Store parsed float in items array
    li $s6, 10  # Load divisor 10
    sub $s3, $t7, $t8  # Convert first digit to integer
    lb $s4, 3($t0)  # Load next byte after first digit
    blt $s4, $t8, one_digit  # If not a digit, it's one digit
    bgt $s4, $t9, one_digit  # If not a digit, it's one digit

    sub $s5, $s4, $t8  # Convert second digit to integer
    mul $s3, $s3, $s6  # Multiply first digit by 10
    add $s3, $s3, $s5  # Add second digit
    li $s6, 100  # Load divisor 100 (for two digits)
    j convert  # Jump to convert

one_digit:  # Handle one digit after decimal point
    li $s6, 10  # Load divisor 10 (for one digit)

convert:  # Convert integer to float
    mtc1 $s3, $f0  # Move integer to floating point register
    mtc1 $s6, $f1  # Move divisor to floating point register
    cvt.s.w $f0, $f0  # Convert integer to float
    cvt.s.w $f1, $f1  # Convert divisor to float
    div.s $f2, $f0, $f1  # Divide to get final float value

    sll $s7, $t2, 2  # Multiply item count by 4 for byte offset
    add $s7, $s7, $t1  # Add offset to items array address
    swc1 $f2, 0($s7)  # Store float in items array

    addi $t2, $t2, 1  # Increment item count
    addi $t0, $t0, 4  # Move ahead 4 bytes in buffer
    j parse_float_loop  # Continue parsing

skip_char:  # Skip over non-float characters
    addi $t0, $t0, 1  # Move to next byte
    j parse_float_loop  # Continue parsing

end_parse_items:  # End of parsing items
    jr $ra  # Return from function

####################################
# WRITE RESULTS TO FILE            #
####################################
write_to_file:  # Write results to output file
    # $s7 = total items
    # $t6 = total bins
    
    # Create or open output file
    li $v0, 13  # Load syscall code for open file
    la $a0, output_filename  # Load address of output filename
    li $a1, 1  # Open for writing (mode 1)
    li $a2, 0  # File permissions (ignored)
    syscall  # Open file
    
    move $s0, $v0  # Save file descriptor
    bltz $s0, output_file_error_handler  # If descriptor negative, handle error
    
    la $t0, output_buffer  # Load address of output buffer
    sw $zero, 0($t0)  # Initialize first word to zero
    
    # First write the bin count at the top of the file
    la $a0, output_buffer  # Load destination address
    la $a1, total_bins_msg  # Load string to append
    jal append_string  # Append string to buffer
    
    move $a0, $t6  # Move bin count to $a0
    la $a1, output_buffer  # Load buffer address
    jal append_number  # Append number to buffer
    
    # Add newline
    la $a0, output_buffer  # Load buffer address
    la $a1, newline  # Load newline string
    jal append_string  # Append newline to buffer
    
    # Write the assignment info to output file
    li $t1, 0  # Initialize item index
    
write_item_loop:  # Loop to write each item assignment
    beq $t1, $s7, finish_write  # If processed all items, finish
    
    # Add "item " to buffer
    la $a0, output_buffer  # Load buffer address
    la $a1, item_str  # Load item string
    jal append_string  # Append string to buffer
    
    # Add item number (1-based index)
    addi $a0, $t1, 1  # Item number is index + 1
    la $a1, output_buffer  # Load buffer address
    jal append_number  # Append number to buffer
    
    # Add " in bin"
    la $a0, output_buffer  # Load buffer address
    la $a1, in_bin_str  # Load string
    jal append_string  # Append string to buffer
    
    # Get bin number for this item
    la $t2, bin_map  # Load address of bin map
    sll $t3, $t1, 2  # Multiply item index by 4 for byte offset
    add $t2, $t2, $t3  # Add offset to bin map address
    lw $t4, 0($t2)  # Load bin number for this item
    
    # Add bin number (1-based index)
    addi $a0, $t4, 1  # Bin number is index + 1
    la $a1, output_buffer  # Load buffer address
    jal append_number  # Append number to buffer
    
    # Add space or newline
    la $a0, output_buffer  # Load buffer address
    la $a1, space_str  # Load space string
    jal append_string  # Append string to buffer
    
    addi $t1, $t1, 1  # Increment item index
    j write_item_loop  # Continue loop
    
finish_write:  # Finish writing output
    # Add final newline
    la $a0, output_buffer  # Load buffer address
    la $a1, newline  # Load newline string
    jal append_string  # Append string to buffer
    
    # Get length of output buffer
    la $t0, output_buffer  # Load buffer address
    li $t1, 0  # Initialize counter
    
buffer_length_loop:  # Loop to count buffer length
    lb $t2, 0($t0)  # Load byte from buffer
    beqz $t2, write_buffer  # If null, end of buffer reached
    addi $t1, $t1, 1  # Increment counter
    addi $t0, $t0, 1  # Move to next byte
    j buffer_length_loop  # Continue loop
    
write_buffer:  # Write buffer to file
    # Write buffer to file
    li $v0, 15  # Load syscall code for write file
    move $a0, $s0  # Move file descriptor to $a0
    la $a1, output_buffer  # Load buffer address
    move $a2, $t1  # Move buffer length to $a2
    syscall  # Write to file
    
    # Close file
    li $v0, 16  # Load syscall code for close file
    move $a0, $s0  # Move file descriptor to $a0
    syscall  # Close file
    
    # Print success message
    li $v0, 4  # Load syscall code for print string
    la $a0, output_done_msg  # Load success message
    syscall  # Display message
    
    j loop  # Jump back to main loop

####################################
# HELPER FUNCTIONS                 #
####################################
append_string:  # Append string to buffer
    # $a0 = destination buffer address
    # $a1 = source string address
    
    # Find end of destination buffer
    move $t9, $a0  # Copy destination address to $t9
find_end:  # Find end of buffer (null byte)
    lb $t8, 0($t9)  # Load byte from buffer
    beqz $t8, copy_string  # If null, found end of buffer
    addi $t9, $t9, 1  # Move to next byte
    j find_end  # Continue searching
    
copy_string:  # Copy source string to destination
    lb $t8, 0($a1)  # Load byte from source
    beqz $t8, end_append  # If null, end of source reached
    sb $t8, 0($t9)  # Store byte to destination
    addi $t9, $t9, 1  # Move to next destination byte
    addi $a1, $a1, 1  # Move to next source byte
    j copy_string  # Continue copying
    
end_append:  # End of append operation
    sb $zero, 0($t9)  # Add null terminator
    jr $ra  # Return from function
    
append_number:  # Append number to buffer
    # $a0 = number to append
    # $a1 = destination buffer
    
    # First find end of buffer
    move $t9, $a1  # Copy buffer address to $t9
find_end_num:  # Find end of buffer for number
    lb $t8, 0($t9)  # Load byte from buffer
    beqz $t8, convert_number  # If null, found end of buffer
    addi $t9, $t9, 1  # Move to next byte
    j find_end_num  # Continue searching
    
convert_number:  # Convert integer to string
    # Convert integer to string
    # We'll do it by pushing digits onto stack
    li $t8, 10  # Load divisor 10
    li $t7, 0  # Initialize digit count
    
    # Handle 0 specially
    bnez $a0, push_digits  # If not zero, push digits
    li $t6, '0'  # Load ASCII value of '0'
    sb $t6, 0($t9)  # Store '0' to buffer
    addi $t9, $t9, 1  # Move to next position
    sb $zero, 0($t9)  # Add null terminator
    jr $ra  # Return from function
    
push_digits:  # Push digits of number onto stack
    beqz $a0, pop_digits  # If number is zero, pop digits
    div $a0, $t8  # Divide number by 10
    mfhi $t6  # Get remainder (last digit)
    mflo $a0  # Get quotient (remaining digits)
    
    # Push digit onto stack
    addi $sp, $sp, -4  # Adjust stack pointer
    addi $t6, $t6, '0'  # Convert digit to ASCII
    sw $t6, 0($sp)  # Store digit on stack
    addi $t7, $t7, 1  # Increment digit count
    j push_digits  # Continue pushing digits
    
pop_digits:  # Pop digits from stack to buffer
    beqz $t7, finish_number  # If no more digits, finish
    lw $t6, 0($sp)  # Load digit from stack
    addi $sp, $sp, 4  # Adjust stack pointer
    sb $t6, 0($t9)  # Store digit to buffer
    addi $t9, $t9, 1  # Move to next buffer position
    addi $t7, $t7, -1  # Decrement digit count
    j pop_digits  # Continue popping digits
    
finish_number:  # Finish number conversion
    sb $zero, 0($t9)  # Add null terminator
    jr $ra  # Return from function

output_file_error_handler:  # Handle output file error
    li $v0, 4  # Load syscall code for print string
    la $a0, output_file_error  # Load error message
    syscall  # Display error message
    j loop  # Jump back to main loop

####################################
# FIRST FIT                        #
####################################
first_fit:  # First Fit algorithm entry point
    li $v0, 4  # Load syscall code for print string
    la $a0, ff_message  # Load FF message
    syscall  # Display message
    jal parse_items  # Parse items from buffer
    j run_ff  # Run First Fit algorithm

####################################
# BEST FIT                         #
####################################
best_fit:  # Best Fit algorithm entry point
    li $v0, 4  # Load syscall code for print string
    la $a0, bf_message  # Load BF message
    syscall  # Display message
    jal parse_items  # Parse items from buffer
    j run_bf  # Run Best Fit algorithm

####################################
# ACTUAL FF LOGIC                  #
####################################
run_ff:  # Run First Fit algorithm
    li $t3, 0  # Initialize item index
    la $t4, items  # Load address of items array
    la $t5, bins  # Load address of bins array
    li $t6, 0  # Initialize bin count
    
ff_item_loop:  # Loop through each item
    beq $t3, $t2, ff_done  # If processed all items, done
    sll $t7, $t3, 2  # Multiply item index by 4 for byte offset
    add $t8, $t4, $t7  # Add offset to items array address
    lwc1 $f4, 0($t8)  # Load current item value

    li $t9, 0  # Initialize bin index

ff_try_bin:  # Try to fit item in current bin
    beq $t9, $t6, new_bin  # If tried all bins, create new bin

    sll $s0, $t9, 2  # Multiply bin index by 4 for byte offset
    add $s1, $t5, $s0  # Add offset to bins array address
    lwc1 $f5, 0($s1)  # Load current bin fill level
    add.s $f6, $f5, $f4  # Add item to bin fill level

    lwc1 $f7, one_float  # Load 1.0
    c.le.s $f6, $f7  # Compare: if (bin + item <= 1.0)
    bc1f ff_try_next_bin  # If not less or equal, try next bin

    swc1 $f6, 0($s1)  # Update bin fill level
    
    la $s5, bin_map  # Load bin map address
    sll $s6, $t3, 2  # Multiply item index by 4
    add $s5, $s5, $s6  # Add offset to bin map
    sw $t9, 0($s5)  # Store bin number for this item

    addi $t3, $t3, 1  # Move to next item
    j ff_item_loop  # Continue with next item

ff_try_next_bin:  # Try next bin
    addi $t9, $t9, 1  # Increment bin index
    j ff_try_bin  # Try next bin
    
new_bin:  # Create new bin for item
    sll $s3, $t6, 2  # Multiply bin count by 4 for byte offset
    add $s4, $t5, $s3  # Add offset to bins array address
    swc1 $f4, 0($s4)  # Store item value as initial bin fill level
    
    la $s5, bin_map  # Load bin map address
    sll $s6, $t3, 2  # Multiply item index by 4 for byte offset
    add $s5, $s5, $s6  # Add offset to bin map address
    sw $t6, 0($s5)  # Store bin number for this item
    
    addi $t6, $t6, 1  # Increment bin count
    addi $t3, $t3, 1  # Move to next item
    j ff_item_loop  # Continue with next item
    
ff_done:  # First Fit algorithm finished
    move $s7, $t2  # Copy total number of items to $s7
    j write_to_file  # Jump to write results to file

####################################
# BEST FIT LOGIC                   #
####################################
run_bf:  # Run Best Fit algorithm
    la $t4, items  # Load address of items array
    la $t5, bins  # Load address of bins array
    li $t6, 0  # Initialize bin count
    li $t3, 0  # Initialize item index

bf_loop:  # Main Best Fit loop for each item
    beq $t3, $t2, bf_done  # If processed all items, done

    sll $t7, $t3, 2  # Multiply item index by 4 for byte offset
    add $t8, $t4, $t7  # Add offset to items array address
    lwc1 $f4, 0($t8)  # Load current item value

    li $t9, 0  # Initialize bin index
    li $s7, -1  # Initialize best bin to -1 (none found yet)
    lwc1 $f10, one_point_one  # Load 1.1 (larger than possible bin remainder)

bf_try_bin:  # Try to fit item in each bin to find best fit
    beq $t9, $t6, use_best_bin  # If tried all bins, use best one found
    sll $s0, $t9, 2  # Multiply bin index by 4 for byte offset
    add $s1, $t5, $s0  # Add offset to bins array address
    lwc1 $f5, 0($s1)  # Load current bin fill level
    add.s $f6, $f5, $f4  # Add item to bin fill level

    lwc1 $f7, one_float  # Load 1.0
    c.le.s $f6, $f7  # Compare: if (bin + item <= 1.0)
    bc1f bf_next_bin  # If not less or equal, try next bin

    sub.s $f8, $f7, $f6  # Calculate remaining space: 1.0 - (bin + item)
    c.lt.s $f8, $f10  # Compare: if (remaining < best_remaining)
    bc1f bf_next_bin  # If not less, try next bin

    mov.s $f10, $f8  # Update best remaining space
    move $s7, $t9  # Update best bin index

bf_next_bin:  # Try next bin
    addi $t9, $t9, 1  # Increment bin index
    j bf_try_bin  # Try next bin

use_best_bin:  # Use best bin found for item
    bltz $s7, bf_new_bin  # If no suitable bin found, create new bin
    sll $s0, $s7, 2  # Multiply best bin index by 4 for byte offset
    add $s1, $t5, $s0  # Add offset to bins array address
    lwc1 $f5, 0($s1)  # Load best bin fill level
    add.s $f6, $f5, $f4  # Add item to best bin fill level
    swc1 $f6, 0($s1)  # Update bin fill level
    
    la $s2, bin_map  # Load bin map address
    sll $s3, $t3, 2  # Multiply item index by 4 for byte offset
    add $s2, $s2, $s3  # Add offset to bin map address
    sw $s7, 0($s2)  # Store bin number for this item
    
    addi $t3, $t3, 1  # Move to next item
    j bf_loop  # Continue with next item

bf_new_bin:  # Create new bin for item
    sll $s0, $t6, 2  # Multiply bin count by 4 for byte offset
    add $s1, $t5, $s0  # Add offset to bins array address
    swc1 $f4, 0($s1)  # Store item value as initial bin fill level
    
    la $s2, bin_map  # Load bin map address
    sll $s3, $t3, 2  # Multiply item index by 4 for byte offset
    add $s2, $s2, $s3  # Add offset to bin map address
    sw $t6, 0($s2)  # Store bin number for this item
    
    addi $t6, $t6, 1  # Increment bin count
    addi $t3, $t3, 1  # Move to next item
    j bf_loop  # Continue with next item
    
bf_done:  # Best Fit algorithm finished
    move $s7, $t2  # Copy total number of items to $s7
    j write_to_file  # Jump to write results to file

exit:  # Program exit point
    li $v0, 10  # Load syscall code for exit
    syscall  # Exit program
