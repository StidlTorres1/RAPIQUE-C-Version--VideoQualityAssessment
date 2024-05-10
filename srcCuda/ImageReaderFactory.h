#pragma once
#include "ImageReader.h"
#include <memory>
#include <string>

class ImageReaderFactory {
public:
    static std::unique_ptr<ImageReader> createImageReader(const std::string& type);
};