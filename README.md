# RAPIQUEC++ Project README

## Overview
RAPIQUEC is a sophisticated C++ project designed for processing a large volume of videos to extract relevant features for image/video quality assessment. It is a C++ re-implementation of the RAPIQUE (Rapid and Accurate Image Quality Estimation) algorithm, an advanced model for image quality evaluation based on machine learning techniques. The project efficiently handles extensive video datasets and leverages FFmpeg for format conversion and temporary file management.

## System Requirements
- Windows
- GPU NVIDIA- More Details [here](https://es.wikipedia.org/wiki/CUDA#Tarjetas_Soportadas)
- CUDA Toolkit
- Visual Studio 2022
- C++17 compatible environment 
- OpenCV 4.8.0
- Python 3.8.10 
- FFmpeg for format conversion (installation guide [here](https://www.youtube.com/watch?v=IECI72XEox0))

## Installation Guide

This installation guide was made following the steps from [here](https://medium.com/@chinssk/build-opencv-on-windows-with-cuda-f880270eadb0), but some steps were added to be more complete.

### 1. Visual Studio
Download and install **Visual Studio 2022 Community** (tested with version 17.8.4) from [here](https://visualstudio.microsoft.com/es/downloads/). When installing, select the `Visual C++ tools for CMake` workload.

### 2. CUDA Toolkit
Download and install **CUDA Toolkit 11.8.0** from [CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive). In **Windows** add the folowwing paths to environmental variables:

- `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\bin`
- `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\lib`
- `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\lib\x64`
- `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\include`

### 3. cuDNN
Download **cuDNN v8.9.6 for CUDA 11.x** from [cuDNN Archive](https://developer.nvidia.com/rdp/cudnn-archive). In **Windows** download the zip and copy the content to `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8`

### 4. CMake
Install **CMake 3.28.1** from [here](https://cmake.org/download/) msi download. 

### 5. OpenCV
Download **OpenCV 4.9.0** from the official [repo](https://github.com/opencv/opencv/releases). In **Windows**, the installer will extract a folder named `opencv`, cut that folder and paste into `C:\Program Files`. Download **opencv_contrib-4.9.0** (is a library with extra modules for OpenCV) from [here](https://github.com/opencv/opencv_contrib/tags), extract `opencv_contrib-4.9.0` en paste de content inside `C:\Program Files\opencv\sources`.

### 6. Python
install Python 3.8.10  from [here](https://www.python.org/downloads/release/python-3810/) Note: Install with debug binaries and debugging symbols. 
Then execute
pip install numpy==1.24.4 
In case you want to modify the resnet50 and run the file model_generator.py or model_avg. Execute:
pip install torch torchvision
versions:
torch-2.2.1
torchvision-0.17.1
sympy-1.12
fsspec-2024.2.0
networkx-3.1
Jinja2-3.1.3
filelock-3.13.1
typing_extensions-4.10.0
pillow-10.2.0
MarkupSafe-2.1.5
mpmath-1.3.0

### 7. Build OpenCV library and add it to Visual Studio

Then open CMake, set the field for `Where is teh source code` to `C:/Program Files/opencv/sources`, create the folder `buildCUDA` inside `C:/Program Files/opencv`, set the field `Where to build the binaries` to `C:/Program Files/opencv/buildCUDA`, then press the button `Configure`. In the search field write `world` and enable the option `BUILD_opencv_world`, then press the button `Configure`. To enable CUDA support for OpenCV, in the search field, write `extra`, then set the field with name `OPENCV_EXTRA_MODULES_PATH` to the value `C:/Program Files/opencv/sources/opencv_contrib-4.9.0/modules` and press the button `Configure`. (optional) in the search field, write `CUDA`, set the checkbox for `WITH_CUDA` and for `OPENCV_DNN_CUDA` and set the field with name `CUDA_ARCH_BIN` to your GPU Compute Capability (look [here](https://developer.nvidia.com/cuda-gpus) to know which GPU Compute Capability your GPU support) and press the button `Configure`. **Finally**, click the button `Generate`. Once is done, you should get `Configuring done` in the output of CMake. Here is the general configuration of CMake thas was get for the testing environment used:

```
General configuration for OpenCV 4.9.0 =====================================
  Version control:               unknown

  Extra modules:
    Location (extra):            C:/Program Files/opencv/sources/opencv_contrib-4.9.0/modules
    Version control (extra):     unknown

  Platform:
    Timestamp:                   2024-01-17T05:00:12Z
    Host:                        Windows 10.0.22621 AMD64
    CMake:                       3.28.1
    CMake generator:             Visual Studio 17 2022
    CMake build tool:            C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/amd64/MSBuild.exe
    MSVC:                        1938
    Configuration:               Debug Release

  CPU/HW features:
    Baseline:                    SSE SSE2 SSE3
      requested:                 SSE3
    Dispatched code generation:  SSE4_1 SSE4_2 FP16 AVX AVX2 AVX512_SKX
      requested:                 SSE4_1 SSE4_2 AVX FP16 AVX2 AVX512_SKX
      SSE4_1 (18 files):         + SSSE3 SSE4_1
      SSE4_2 (2 files):          + SSSE3 SSE4_1 POPCNT SSE4_2
      FP16 (1 files):            + SSSE3 SSE4_1 POPCNT SSE4_2 FP16 AVX
      AVX (9 files):             + SSSE3 SSE4_1 POPCNT SSE4_2 AVX
      AVX2 (38 files):           + SSSE3 SSE4_1 POPCNT SSE4_2 FP16 FMA3 AVX AVX2
      AVX512_SKX (8 files):      + SSSE3 SSE4_1 POPCNT SSE4_2 FP16 FMA3 AVX AVX2 AVX_512F AVX512_COMMON AVX512_SKX

  C/C++:
    Built as dynamic libs?:      YES
    C++ standard:                11
    C++ Compiler:                C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe  (ver 19.38.33134.0)
    C++ flags (Release):         /DWIN32 /D_WINDOWS /W4 /GR  /D _CRT_SECURE_NO_DEPRECATE /D _CRT_NONSTDC_NO_DEPRECATE /D _SCL_SECURE_NO_WARNINGS /Gy /bigobj /Oi  /fp:precise     /EHa /wd4127 /wd4251 /wd4324 /wd4275 /wd4512 /wd4589 /wd4819 /MP  /O2 /Ob2 /DNDEBUG 
    C++ flags (Debug):           /DWIN32 /D_WINDOWS /W4 /GR  /D _CRT_SECURE_NO_DEPRECATE /D _CRT_NONSTDC_NO_DEPRECATE /D _SCL_SECURE_NO_WARNINGS /Gy /bigobj /Oi  /fp:precise     /EHa /wd4127 /wd4251 /wd4324 /wd4275 /wd4512 /wd4589 /wd4819 /MP  /Zi /Ob0 /Od /RTC1 
    C Compiler:                  C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe
    C flags (Release):           /DWIN32 /D_WINDOWS /W3  /D _CRT_SECURE_NO_DEPRECATE /D _CRT_NONSTDC_NO_DEPRECATE /D _SCL_SECURE_NO_WARNINGS /Gy /bigobj /Oi  /fp:precise     /MP   /O2 /Ob2 /DNDEBUG 
    C flags (Debug):             /DWIN32 /D_WINDOWS /W3  /D _CRT_SECURE_NO_DEPRECATE /D _CRT_NONSTDC_NO_DEPRECATE /D _SCL_SECURE_NO_WARNINGS /Gy /bigobj /Oi  /fp:precise     /MP /Zi /Ob0 /Od /RTC1 
    Linker flags (Release):      /machine:x64  /INCREMENTAL:NO 
    Linker flags (Debug):        /machine:x64  /debug /INCREMENTAL 
    ccache:                      NO
    Precompiled headers:         NO
    Extra dependencies:          cudart_static.lib nppc.lib nppial.lib nppicc.lib nppidei.lib nppif.lib nppig.lib nppim.lib nppist.lib nppisu.lib nppitc.lib npps.lib cublas.lib cudnn.lib cufft.lib -LIBPATH:C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.8/lib/x64
    3rdparty dependencies:

  OpenCV modules:
    To be built:                 aruco bgsegm bioinspired calib3d ccalib core cudaarithm cudabgsegm cudacodec cudafeatures2d cudafilters cudaimgproc cudalegacy cudaobjdetect cudaoptflow cudastereo cudawarping cudev datasets dnn dnn_objdetect dnn_superres dpm face features2d flann fuzzy gapi hfs highgui img_hash imgcodecs imgproc intensity_transform line_descriptor mcc ml objdetect optflow phase_unwrapping photo plot python3 quality rapid reg rgbd saliency shape stereo stitching structured_light superres surface_matching text tracking ts video videoio videostab wechat_qrcode world xfeatures2d ximgproc xobjdetect xphoto
    Disabled:                    -
    Disabled by dependency:      -
    Unavailable:                 alphamat cannops cvv freetype hdf java julia matlab ovis python2 python2 sfm viz
    Applications:                tests perf_tests apps
    Documentation:               NO
    Non-free algorithms:         NO

  Windows RT support:            NO

  GUI: 
    Win32 UI:                    YES
    VTK support:                 NO

  Media I/O: 
    ZLib:                        build (ver 1.3)
    JPEG:                        build-libjpeg-turbo (ver 2.1.3-62)
      SIMD Support Request:      YES
      SIMD Support:              NO
    WEBP:                        build (ver encoder: 0x020f)
    PNG:                         build (ver 1.6.37)
    TIFF:                        build (ver 42 - 4.2.0)
    JPEG 2000:                   build (ver 2.5.0)
    OpenEXR:                     build (ver 2.3.0)
    HDR:                         YES
    SUNRASTER:                   YES
    PXM:                         YES
    PFM:                         YES

  Video I/O:
    DC1394:                      NO
    FFMPEG:                      YES (prebuilt binaries)
      avcodec:                   YES (58.134.100)
      avformat:                  YES (58.76.100)
      avutil:                    YES (56.70.100)
      swscale:                   YES (5.9.100)
      avresample:                YES (4.0.0)
    GStreamer:                   NO
    DirectShow:                  YES
    Media Foundation:            YES
      DXVA:                      YES

  Parallel framework:            Concurrency

  Trace:                         YES (with Intel ITT)

  Other third-party libraries:
    Intel IPP:                   2021.11.0 [2021.11.0]
           at:                   C:/Program Files/opencv/buildCUDA/3rdparty/ippicv/ippicv_win/icv
    Intel IPP IW:                sources (2021.11.0)
              at:                C:/Program Files/opencv/buildCUDA/3rdparty/ippicv/ippicv_win/iw
    Lapack:                      NO
    Eigen:                       NO
    Custom HAL:                  NO
    Protobuf:                    build (3.19.1)
    Flatbuffers:                 builtin/3rdparty (23.5.9)

  NVIDIA CUDA:                   YES (ver 11.8, CUFFT CUBLAS)
    NVIDIA GPU arch:             86
    NVIDIA PTX archs:            90

  cuDNN:                         YES (ver 8.9.6)

  OpenCL:                        YES (NVD3D11)
    Include path:                C:/Program Files/opencv/sources/3rdparty/include/opencl/1.2
    Link libraries:              Dynamic load

  Python 3:
    Interpreter:                 C:/Program Files/Python38/python.exe (ver 3.8.10)  or binaries/debug route
    Libraries:                   C:/Program Files/Python38/libs/python310.lib (ver 3.8.10) or binaries/debug route
    numpy:                       C:/Program Files/Python38/lib/site-packages/numpy/core/include (ver 1.24.1)
    install path:                C:/Program Files/Python38/Lib/site-packages/cv2/python-3.10

  Python (for build):            C:/Program Files/Python310/python.exe

  Java:                          
    ant:                         NO
    Java:                        NO
    JNI:                         NO
    Java wrappers:               NO
    Java tests:                  NO

  Install to:                    C:/Program Files/opencv/buildCUDA/install
-----------------------------------------------------------------

Configuring done (17.6s)
Generating done (32.1s)
```

Now, open `C:\Program Files\opencv\buildCUDA\OpenCV.sln` in Visual Studio, change the compilation mode from `Release` to `Debug`. Then in Visual Studio, go to `Solution Explorer`, look for the folder `CMakeTargets`, rigth click in `ALL_BUILD` and select build, this may take a long time to finish. Once is done, rigth click in `INSTALL` and select build. After that you should have the folder `C:\Program Files\opencv\buildCUDA\install` with all the compiled files to use OpenCV with CUDA and cuDNN support. Add `C:\Program Files\opencv\buildCUDA\install\x64\vc17\bin` to the working path

To use OpenCV DNN in C++ you must include it in the Visual Studio project, if you follow all the steps above this should be already done, but if you customize some steps, then: open visual studio with the project `srcVS` that is in the main repo, once is open, right click in `srcVS` that is in the `Solution Explorer` window, select `Project Properties`, go to `VC++ Directories -> External Include Directories`, the path for the default installation is set to `C:\Program Files\opencv\buildCUDA\install\include`. Next go to `Linker -> Additional Library Directories`, the path for the default installation is set to `C:\Program Files\opencv\buildCUDA\install\x64\vc17\lib`

### 8. Install LibTorch

Download the **LibTorch 2.2.0 debug version for cuda 11.8** from [here](https://download.pytorch.org/libtorch/cu118/libtorch-win-shared-with-deps-debug-2.2.0%2Bcu118.zip), uncompress the zip in `C:\Program Files\LibTorch2.2.0`, then add `C:\Program Files\LibTorch2.2.0\libtorch\lib` to the system PATH. Follow [this](https://medium.com/@weikang_liu/integrating-pytorch-c-libtorch-2-1-2-in-ms-visual-studio-2022-f971012371b3) tutorial if you found any issue when building pytorch.

## Project Setup in Visual Studio

### Opening the Project in Visual Studio
- First, ensure you are running Visual Studio as an Administrator. This can be done by right-clicking on the Visual Studio icon and selecting "Run as administrator".
- Within Visual Studio, navigate to File -> Open -> Project/Solution, or use the shortcut Ctrl+Shift+O.
- Browse to the location of your project and find the solution file located at "srcCuda/srcCuda.sln".
- Select the srcCuda.sln file and click "Open" to load your project into Visual Studio.

### Configuring the Project
- Before building your project, ensure that Visual Studio is configured correctly for your development needs. This includes setting up any necessary build configurations and ensuring that all project dependencies are correctly linked.
- Check the Solution Explorer to verify that all project files have been loaded correctly.

### Building the Project
- To build the project, right-click on the solution name in Solution Explorer and select "Build Solution", or use the shortcut F7.
- Ensure that the build completes without errors. Review the Output window for any build messages or warnings.

### Running the Project
- After successfully building the project, you can run it by clicking on the "Local Windows Debugger" button on the toolbar, or by pressing F5. This starts the application with debugging enabled.
If you prefer to run without debugging, use Ctrl+F5 instead.

### The test branch
This branch allows you to test different properties on the functions. When running, the console displays which tests passed or failed. In order to run it, you must install Google Test dependencies following the steps below:
* Go to Project > Manage NuGet packages
* Search for google test and google mock packages
* Install by clicking on the arror and follow the steps


# Tests suite and it's properties
## 1. CudaImageProcessorTest
Total Tests: 3
Total Time: 811 ms
### Test
### ApplyFilter

Description: Test the application of a filter to an image using CUDA.
Parameters:
Filter type: 5
Filter size: [3 x 3]
Input and result image size: [256 x 256]
Results: The application of the filter was validated by comparing the input and output images. Both matched, indicating the filter was applied correctly.
Execution Time: 754 ms

### Multiply
Description: Test the multiplication operation on images using CUDA.
Execution Time: 34 ms

### CircularShift
Description: Test the circular shift operation on images using CUDA.
Execution Time: 16 ms

## 2. RAPIQUESpatialFeaturesTest
Total Tests: 2
Total Time: 1078 ms

### ValidImageInput
Description: Test the extraction of spatial features from a valid image.
Execution Time: 1067 ms

### EmptyImageInput
Description: Test the behavior when an empty image is provided as input.
Result: An appropriate message was recorded, indicating the correct handling of the empty input.
Execution Time: 7 ms

## 3. EstGGDParamTest
Total Tests: 3
Total Time: 13 ms

### NonEmptyInput
Description: Test the estimation of parameters from a non-empty input.
Execution Time: 4 ms

### EmptyInput
Description: Test the estimation of parameters from an empty input.
Execution Time: 0 ms

### SingleValueInput
Description: Test the estimation of parameters from a single-value input.
Execution Time: 1 ms

## 4. GenDoGTest
Total Tests: 2
Total Time: 64 ms

### ValidInput
Description: Test the generation of DoG (Difference of Gaussian) with valid input.
Execution Time: 54 ms

### InvalidInput
Description: Test the generation of DoG with invalid input.
Execution Time: 5 ms

## 5. CalcRAPIQUEFeaturesTest
Total Tests: 1
Total Time: 35358 ms

### CalcRAPIQUEFeatures
Description: Test the calculation of RAPIQUE features from video frames.
Details:
Feature vector size: 3884
Execution includes loading models and calculating feature vectors for multiple frames.
Execution Time: 35354 ms

## 6. EstAGGDParamTestSuite
Total Tests: 3
Total Time: 71 ms

### CalculateStdDev
Description: Test the calculation of standard deviations.
Results: The calculated standard deviations matched the expected values.
Execution Time: 30 ms

### GenerateGam
Description: Test the generation of GAM (Generalized Autoregressive Model).
Execution Time: 3 ms

### EstAGGDParam
Description: Test the estimation of AGGD (Asymmetric Generalized Gaussian Distribution) parameters.
Execution Time: 20 ms

## 7. NakafitTest
Total Tests: 3
Total Time: 28 ms

### NonEmptyInput
Description: Test parameter fitting with non-empty input.
Execution Time: 0 ms

### EmptyInput
Description: Test parameter fitting with empty input.
Execution Time: 0 ms

### SingleValueInput
Description: Test parameter fitting with single-value input.
Execution Time: 0 ms

## 8. RapiqueBasicExtractorTest
Total Tests: 2
Total Time: 147 ms

### ValidImageInput
Description: Test the extraction of features from a valid image.
Execution Time: 132 ms

### EmptyImageInput
Description: Test the handling of an empty image.
Execution Time: 5 ms

## 9. TimerTest
Total Tests: 4
Total Time: 564 ms

### ImmediateStart
Description: Test the timer with an immediate start.
Execution Time: 111 ms

### ManualStartStop
Description: Test the timer with manual start and stop.
Execution Time: 105 ms

### ElapsedWhileRunning
Description: Test the calculation of elapsed time while the timer is running.
Execution Time: 104 ms

### ElapsedAfterStop
Description: Test the calculation of elapsed time after stopping the timer.
Execution Time: 217 ms

## 10. YUVReaderTest
Total Tests: 3
Total Time: 74 ms


### ReadImage_ValidFrame
Description: Test reading a valid frame from a YUV image.
Execution Time: 28 ms

### ReadImage_FrameOutOfBounds
Description: Test reading a frame out of bounds.
Result: An appropriate error message was recorded.
Execution Time: 11 ms

### ReadImage_FileNotFound
Description: Test reading an image from a nonexistent file.
Result: An appropriate error message was recorded.
Execution Time: 15 ms


# Nvidia Nsight
## Installation guide
Go to https://developer.nvidia.com/nsight-visual-studio-edition and follow the installing instructions.

## Use guide
* Go to Extensions > Nsight > Nsight Compute > Profile
* Click in ok and specify the path to your .exec, your working dir, any arguments needed for running (if applies) and environment (if applies).
* In common, specify the output folder for the logs and then click "Launch" to start profiling.

### Recommendations
- It is strongly recommended to run Visual Studio in administrator mode to avoid any permission-related issues during the build or run phases of your project.
- Pay close attention to the Output and Error List windows in Visual Studio for any warnings or errors that may need to be addressed.

### Troubleshooting
- If you encounter issues while opening, building, or running the project, ensure that all Visual Studio updates are applied and that you have the correct versions of any required SDKs or libraries installed.
- For specific build errors or runtime issues, consulting the detailed error messages provided in the Output window can provide valuable insights into the cause of the problem.

# UI
## Installation
- conda create -n video_processing python=3.9
- conda activate video_processing
- pip install psutil
- python ui.py
- Move the .dll libtorch(pytorch) files into the root directory (rapique_ui)
- Replace the mainRAPIQUEE.cu in srcCuda project by mainRAPIQUEE_.cu located in the rapique_ui and re compile it.
- Copy the .exec file generated in srcCuda/x64/Debug/srcCuda.exec  and paste it into the rapique_ui folder.

## Usage
- Load .mp4 videos with the Load Videos button
- Load your metadata (mos files) with the Load Metadata button
- Select the output folder
- Press the Start Program button and wait for processing
- After finished, check your output folder
## Usage
- The results of this project can be found in the folder or path 'RAPIQUE-main (Matlab) and All Results', the extracted features can be found in 'RAPIQUE-main (Matlab) and All Results\feat_files' and the other video quality assessment metrics in 'Others Metrics VQA'.
## Additional Notes
- Regularly updating Visual Studio and your project's dependencies can help prevent compatibility issues and ensure access to the latest features and security improvements.
- Utilize Visual Studio's extensive documentation and community forums for additional support and guidance on using advanced features or troubleshooting more complex issues.
