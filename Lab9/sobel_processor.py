import os
import time
import numpy as np
from PIL import Image
import sys
import glob
os.environ['QUARTUS_ROOTDIR'] = '/opt/altera/17.1/quartus'
import intel_jtag_uart

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
    # Initialize JTAG UART communication
    print("Initializing JTAG UART...")
    ju = intel_jtag_uart.intel_jtag_uart()
    
    # Target and padded sizes
    target_size = (254, 254)
    padded_size = (256, 256)
    
    # Iterates over all PNGs in the test_images folder
    for image_path in sorted(glob.glob('test_images/*.png')):
        print(f"\n=== Testing {image_path} ===")

        # Load and prepare the image
        print(f"Loading and preparing image: {image_path}")
        img = load_and_prepare_image(image_path, target_size=target_size, padded_size=padded_size)

        # Convert image to bytes
        img_bytes = image_to_bytes(img)
        print(f"Image converted to bytes ({len(img_bytes)} bytes)")

        # Send image to FPGA
        print("Sending image to FPGA...")
        for b in img_bytes:
            ju.write(bytes([b]))
        
        # Wait for processing
        print("Waiting for FPGA processing...")
        time.sleep(10)
        
        # Receive processed image
        print("Receiving processed image...")
        expected_size = padded_size[0] * padded_size[1]  # Total bytes expected (256 * 256)
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
        
        # Extract only the file name (without directory or extension)
        base = os.path.splitext(os.path.basename(image_path))[0]
        # Constructs the output path in output/<name>.png
        output_path = os.path.join('output', f'{base}.png')
        processed_img.save(output_path)


if __name__ == '__main__':
    main()