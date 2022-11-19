#include <thread>
#include <stdio.h>
#include "Matrix.h"
#include "Frame.h"
#include "Voxel.h"

#include "Window.h"
#include "Color.h"
#include "Point.h"
#include "Particles.h"
#include "Kernel.cuh"
#include "Triangle.h"
#include "AxisAlinedCube.h"
#include "Gui.h"

// Jiamera::Frame* chief_frame;
int main(int argc, char* argv[]) {
	Jiamera::Gui* gl_system = new Jiamera::Gui();
	// // title: 1 rgb / 2 label / 3 instance
	Jiamera::Window* rgb_window = new Jiamera::Window("rgb", 100, 100, 640, 480);	
	Jiamera::Window* label_window = new Jiamera::Window(std::string("label"), 1000, 100, 640, 480);
	Jiamera::Window* instance_window = new Jiamera::Window(std::string("instance"), 500, 100, 640, 480);

	std::string rgb_intrinsic_file = "../data/ScanNet/all/scene0011_00/intrinsic/intrinsic_color.txt";

	std::string depth_intrinsic_file = "../data/ScanNet/all/scene0011_00/intrinsic/intrinsic_depth.txt";

	std::string panooptic_intrinsic_file = "../data/ScanNet/all/scene0011_00/intrinsic/intrinsic_color.txt";

	std::string base_pose_file = "../data/ScanNet/all/scene0011_00/pose/0.txt";

	std::string frame_path = "../data/ScanNet/all/scene0011_00/";

	Jiamera::Frame* chief_frame = new Jiamera::Frame(1296, 968, 640, 480, 1296, 968, 0, 0, 2374, frame_path, rgb_intrinsic_file, depth_intrinsic_file, panooptic_intrinsic_file, base_pose_file);

	std::vector<Jiamera::Frame*> frame_workers;

	for (size_t i = 0; i < FRAME_NUM_; ++i) {
		frame_workers.push_back(new Jiamera::Frame(1296, 968, 640, 480, 1296, 968, 0, 0, 2374, frame_path, rgb_intrinsic_file, depth_intrinsic_file, panooptic_intrinsic_file, base_pose_file));
	}

	Jiamera::Particles* voxel = new Jiamera::Particles(12.0f, 8.0f, 9.0f, 0.05);
	CudaPreWork(voxel, chief_frame);

	voxel->bind_belonged_gl_(gl_system);
	rgb_window->add_object(voxel);
	label_window->add_object(voxel);
	instance_window->add_object(voxel);

	// Windows 可以同时显示三个窗口，Linux 遇到了问题，暂时在 Particles.h line 154 修改 rgb_window 显示的属性
	gl_system->AddWindow(rgb_window);
	// gl_system->AddWindow(label_window);
	//gl_system->AddWindow(instance_window);


	gl_system->Display();
	//Sleep(2000);

	CudaInWork(voxel, chief_frame, frame_workers);
	CudaPostWork(voxel, chief_frame, frame_workers);

	//voxel->SaveCloud();
	//voxel->SaveParamaters();

	gl_system->Synchronize();

	return 0;
}
