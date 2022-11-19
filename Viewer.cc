#include "Viewer.h"

namespace Jiamera {
	Viewer::Viewer(int width, int height, const std::string& intrinsics, 
		           const std::string& file) {
		//std::cout << "Creating Viewer Class -----------------------------------------\n";

		intrinsics_ = new Matrix<float>(3, 3);
		intrinsics_->read_txt(intrinsics, 4, 4);
		//intrinsics_->view_dim2();

		base_pose_ = new Matrix<float>(4, 4);
		base_pose_->read_txt(file, 4, 4);

		base_pose_inverse_ = base_pose_->get_inverse_4x4();

		delta_pose_ = new Matrix<float>(4, 4);
		current_pose_ = new Matrix<float>(4, 4);
	}

	void Viewer::update_pose_file(const std::string& pose) {
		delta_pose_->read_txt(pose, 4, 4);

		current_pose_ = matrix_multiply_2d(base_pose_inverse_, delta_pose_);
	}
}
