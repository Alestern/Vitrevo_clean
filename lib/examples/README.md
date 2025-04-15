# OCR Demo Example

This example demonstrates how to use the `MLKitOCRService` to recognize text from images.

## Features

- Capture images from camera or select from gallery
- Process images using ML Kit Text Recognition
- Display recognized text
- Handle errors and processing states

## Usage

To run this example:

1. Navigate to the main app
2. Click on the "OCR Demo" button on the homepage
3. Capture an image or select from gallery
4. View the recognized text

## Code Structure

The demo consists of a single page with the following key components:

- `MLKitOCRService` instance for text recognition
- Image picker for selecting images
- UI for displaying the image and recognized text
- Error handling for OCR failures

## Implementation Details

The demo shows best practices for OCR implementation:

- Proper resource management (disposing the OCR service)
- Loading states during processing
- Error handling and user feedback
- Clean UI for image and text display

## Nutritional Information Detection

The OCR service is specifically tuned for detecting nutritional information on food packaging. For best results:

- Ensure good lighting
- Capture the nutritional table clearly
- Position the camera perpendicular to the packaging

## Extending the Example

You can extend this example by:

- Adding text parsing for specific nutritional values
- Implementing language detection
- Adding support for different OCR models
- Building a custom UI for displaying structured nutritional data 