import os
import time
import numpy as np
from PIL import Image
import intel_jtag_uart
import sys


def load_and_prepare_image(image_path: str, target_size: tuple[int, int] = (254, 254), 
                         padded_size: tuple[int, int] = (256, 256)) -> Image.Image:
    """
    Loads an image, resizes it to the target size, converts it to grayscale, and adds padding to reach the padded size.
    
    Parameters
    ----------
    image_path : str
        Path to the input image file.
    target_size : tuple[int, int], optional
        Desired size (width, height) for resizing the image (default is (254, 254)).
    padded_size : tuple[int, int], optional
        Final size (width, height) after adding zero-padding (default is (256, 256)).
    
    Return
    ------
    Image.Image
        A PIL Image object in grayscale mode ('L') with the specified padded size.
    """
    # Load the image
    img = Image.open(image_path)
    
    # Resize to target size if necessary
    if img.size != target_size:
        img = img.resize(target_size, Image.BICUBIC)
    
    # Convert to grayscale
    img = img.convert('L')
    
    # Add padding to reach padded size
    padded_img = Image.new('L', padded_size, 0)
    offset = ((padded_size[0] - target_size[0]) // 2, (padded_size[1] - target_size[1]) // 2)
    padded_img.paste(img, offset)
    
    return padded_img


def image_to_bytes(img: Image.Image) -> bytes:
    """
    Converts a PIL Image to a bytes object for transmission over JTAG UART.
    
    Parameters
    ----------
    img : Image.Image
        PIL Image object in grayscale mode ('L').
    
    Return
    ------
    bytes
        A bytes object containing the pixel values of the image.
    """
    img_array = np.array(img)
    return img_array.tobytes()


def bytes_to_image(byte_data: bytes, size: tuple[int, int]) -> Image.Image:
    """
    Converts a bytes object received from the FPGA into a PIL Image.
    
    Parameters
    ----------
    byte_data : bytes
        Bytes containing pixel values of the processed image.
    size : tuple[int, int]
        Size (width, height) of the image to reconstruct.
    
    Return
    ------
    Image.Image
        A PIL Image object in grayscale mode ('L') reconstructed from the bytes.
    """
    img_array = np.frombuffer(byte_data, dtype=np.uint8).reshape(size)
    return Image.fromarray(img_array, 'L')


def main() -> None:
    # Path to the test image
    image_path = 'test_images/checkerboard_254x254.png'
    
    # Target and padded sizes
    target_size = (254, 254)
    padded_size = (256, 256)
    
    # Load and prepare the image
    print(f"Loading and preparing image: {image_path}")
    img = load_and_prepare_image(image_path, target_size=target_size, padded_size=padded_size)
    
    # Convert image to bytes
    img_bytes = image_to_bytes(img)
    print(f"Image converted to bytes ({len(img_bytes)} bytes)")
    
    try:
        # Initialize JTAG UART communication
        print("Initializing JTAG UART...")
        ju = intel_jtag_uart.intel_jtag_uart()
        
        # Send image to FPGA
        print("Sending image to FPGA...")
        ju.write(img_bytes)
        
        # Wait for processing
        print("Waiting for FPGA processing...")
        time.sleep(10)  # Adjust based on actual processing time
        
        # Receive processed image
        print("Receiving processed image...")
        expected_size = padded_size[0] * padded_size[1]
        received_bytes = b""
        start_time = time.time()
        while len(received_bytes) < expected_size and time.time() - start_time < 20:
            received_bytes += ju.read()
        
        # Check if received data is complete
        if len(received_bytes) != expected_size:
            print(f"Error: Received {len(received_bytes)} bytes, expected {expected_size} bytes")
            sys.exit(1)
        
        # Convert received bytes to image
        processed_img = bytes_to_image(received_bytes, padded_size)
        
        # Display and save processed image
        print("Displaying processed image...")
        processed_img.show()
        processed_img.save('test_images/processed_output.png')
        
    except Exception as e:
        print(f"Error during FPGA communication: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
