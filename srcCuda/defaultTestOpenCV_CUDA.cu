#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/cudaimgproc.hpp>


int mainTest_openCV_CUDA() {

	cv::cuda::setDevice(0);
	cv::VideoCapture cap(0);
	cv::Mat frame;
	cv::cuda::GpuMat Gframe;

	if (!cap.isOpened())
	{
		std::cout << "No camera exist\n";
		return -1;
	}

	while (1) {
		cap >> frame;
		Gframe.upload(frame);
		cv::cuda::cvtColor(Gframe, Gframe, cv::COLOR_BGR2GRAY);
		Gframe.download(frame);
		cv::imshow("Gray webcam", frame);
		if (cv::waitKey(1) == 27) { // Press esc
			std::cout << "End camera loop\n";
			return 1;
		}
	}
	return 0;
}