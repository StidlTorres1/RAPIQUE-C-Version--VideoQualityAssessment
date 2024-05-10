// ImageProcessorFactory.h
#pragma once
#include "ImageProcessor.h"
#include "CudaImageProcessor.h"
#include <memory>

class ImageProcessorFactory {
public:
    static std::unique_ptr<ImageProcessor> createImageProcessor() {
        return std::make_unique<CudaImageProcessor>();
    }
};