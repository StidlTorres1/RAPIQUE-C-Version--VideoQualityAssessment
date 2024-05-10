#include "ImageReaderFactory.h"
#include "YUVReader.h"

std::unique_ptr<ImageReader> ImageReaderFactory::createImageReader(const std::string& type) {
    if (type == "YUV") {
        return std::make_unique<YUVReader>();
    }
    // Future conditions for other image types could be added here

    return nullptr;
}