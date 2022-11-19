#include "Voxel.h"

namespace Jiamera {

    Voxel::Voxel() {
        std::cout << "Creating Voxel Class -----------------------------------------\n";

        grid_num_x_ = k_space_x / k_grid_size_;
        grid_num_y_ = k_space_y / k_grid_size_;
        grid_num_z_ = k_space_z / k_grid_size_;
        grid_num_ = grid_num_y_ * grid_num_y_ * grid_num_z_;

        truncation_margin_ = k_grid_size_ * 5;
    }

    /*
    x
    原点 偏左 0.7 0.5 0.4 合适 0.3 偏右
    尺寸 偏小 10 合适 15 偏大

    y
    原点 偏上 0.7 合适 0.71 0.72 0.725 0.75 0.8 偏下
    尺寸 偏小 合适 8 偏大

    z (左视图)
    原点 偏左 0.75 0.5 0.3 合适 0.2 偏右
    尺寸 偏小 8 合适 10 偏大
    */


    Voxel::Voxel(float x, float y, float z, float size) :
        k_space_x(x), k_space_y(y), k_space_z(z), k_grid_size_(size),
        k_origin_x_(-x*0.35), k_origin_y_(-y * 0.705), k_origin_z_(-z*0.25) {

        std::cout << "Setting Voxel Class -----------------------------------------\n";

        grid_num_x_ = k_space_x / k_grid_size_;
        grid_num_y_ = k_space_y / k_grid_size_;
        grid_num_z_ = k_space_z / k_grid_size_;

        grid_num_ = grid_num_x_ * grid_num_y_ * grid_num_z_;

        truncation_margin_ = k_grid_size_ * 3;

        data_init();

        gl_data_init();

        //VoxelHashInterface(ceil(grid_num_x_ / 8.0), ceil(grid_num_y_ / 8.0), ceil(grid_num_z_ / 8.0));

        gl_data_update();   // 向 OpenGL 渲染数组传输点云，本次传输界面为空

    }

    void Voxel::data_init() {
        //data_ = (float*)malloc(grid_num_ * attrib_num_ * sizeof(float));
        //memset(data_, 0, grid_num_ * attrib_num_ * sizeof(float));

        color_b_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(color_b_, 0, grid_num_ * sizeof(float));

        color_g_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(color_g_, 0, grid_num_ * sizeof(float));

        color_r_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(color_r_, 0, grid_num_ * sizeof(float));

        instance_ = (int*)malloc(grid_num_ * sizeof(int));
        memset(instance_, 0, grid_num_ * sizeof(int));

        label_ = (int*)malloc(grid_num_ * sizeof(int));
        std::fill(label_, label_ + grid_num_, -1);
        //memset(label_, 0, grid_num_ * sizeof(int));

        tsdf_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(tsdf_, 0, grid_num_ * sizeof(float));

        bgr_weight_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(bgr_weight_, 0, grid_num_ * sizeof(float));

        label_weight_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(label_weight_, 0, grid_num_ * sizeof(float));

        instance_weight_ = (float*)malloc(grid_num_ * sizeof(float));
        memset(instance_weight_, 0, grid_num_ * sizeof(float));

        int grid_index = 0;
        for (int j = 0; j < grid_num_z_; ++j) {
            for (int k = 0; k < grid_num_y_; ++k) {
                for (int i = 0; i < grid_num_x_; ++i) {

                    // 初始化三个 weight = 0
                    // r g b tsdf 第0帧不会用到

                    // 初始化 x y z
                    //data_[grid_index * attrib_num_ + x_offset_] = k_origin_x_ + (float)i * k_grid_size_;
                    //data_[grid_index * attrib_num_ + y_offset_] = k_origin_y_ + (float)k * k_grid_size_;
                    //data_[grid_index * attrib_num_ + z_offset_] = k_origin_z_ + (float)j * k_grid_size_;

                    // 初始化 label
                    //data_[grid_index * attrib_num_ + label_offset_] = -1.0f;

                    //bool flag1 = (i == 0 || i == grid_num_x_ - 1);
                    //bool flag2 = (j == 0 || j == grid_num_z_ - 1);
                    //bool flag3 = (k == 0 || k == grid_num_y_ - 1);
                    //if ((!flag1 && flag2 && flag3) || (!flag1 && flag2 && flag3) || (!flag1 && flag2 && flag3)) {

                    // 显示边框
                    {
                        //bool flag1 = (i == 0);
                        //bool flag2 = (j == 0);
                        //bool flag3 = (k == 0);

                        //bool flag4 = (i == grid_num_x_ - 1);
                        //bool flag5 = (j == grid_num_z_ - 1);
                        //bool flag6 = (k == grid_num_y_ - 1);

                        //if (flag1 && flag2 && !flag3 && !flag4 && !flag5 && !flag6 ||   // 12
                        //    flag1 && !flag2 && flag3 && !flag4 && !flag5 && !flag6 ||   // 13

                        //    flag1 && !flag2 && !flag3 && flag4 && !flag5 && !flag6 ||   // 14

                        //    flag1 && !flag2 && !flag3 && !flag4 && flag5 && !flag6 ||   // 15
                        //    flag1 && !flag2 && !flag3 && !flag4 && !flag5 && flag6 ||   // 16

                        //    !flag1 && flag2 && flag3 && !flag4 && !flag5 && !flag6 ||   // 23
                        //    !flag1 && flag2 && !flag3 && flag4 && !flag5 && !flag6 ||   // 24
                        //    !flag1 && flag2 && !flag3 && !flag4 && !flag5 && flag6 ||   // 26

                        //    !flag1 && !flag2 && flag3 && flag4 && !flag5 && !flag6 ||   // 34
                        //    !flag1 && !flag2 && flag3 && !flag4 && flag5 && !flag6 ||   // 35

                        //    !flag1 && !flag2 && !flag3 && flag4 && flag5 && !flag6 ||   // 45
                        //    !flag1 && !flag2 && !flag3 && flag4 && !flag5 && flag6 ||   // 46

                        //    !flag1 && !flag2 && !flag3 && !flag4 && flag5 && flag6    // 56
                        //    ) {
                        //    data_[grid_index * attrib_num_ + rgb_weight_offset] = 1.0f;

                        //}
                    }

                    ++grid_index;
                }
            }
        }
        std::cout << grid_index << " points\n";
    }


    /*
    void Voxel::SaveCloud() {
        std::string file_name = "tsdf.ply";
        std::cout << "Saving surface point cloud." << std::endl;

        float tsdf_thresh = 0.2f;
        float weight_thresh = 0.0f;

        int num_pts = 0;
        for (int i = 0; i < grid_num_; i++)
            if (std::abs(data_[i * attrib_num_ + tsdf_offset_]) < tsdf_thresh && 
                data_[i * attrib_num_ + rgb_weight_offset] > weight_thresh) {

                num_pts++;
            }

        std::cout << num_pts << "points\n";

        // Create header for .ply file
        FILE* fp = fopen(file_name.c_str(), "w");
        fprintf(fp, "ply\n");
        fprintf(fp, "format binary_little_endian 1.0\n");
        fprintf(fp, "element vertex %d\n", num_pts);
        fprintf(fp, "property float x\n");
        fprintf(fp, "property float y\n");
        fprintf(fp, "property float z\n");
        fprintf(fp, "element face 7\n");
        fprintf(fp, "end_header\n");

        // Create point cloud content for ply file
        for (int i = 0; i < grid_num_; ++i) {

            // If TSDF value of voxel is less than some threshold, 
            // add voxel coordinates to point cloud
            if (std::abs(data_[i * attrib_num_ + tsdf_offset_]) < tsdf_thresh && 
                data_[i * attrib_num_ + rgb_weight_offset] > weight_thresh) {

                float x = data_[i * attrib_num_ + x_offset_];
                float y = data_[i * attrib_num_ + y_offset_];
                float z = data_[i * attrib_num_ + z_offset_];

                fprintf(fp, "%f %f %f\n", x, y, z);
            }
        }
        fclose(fp);
    }

    void Voxel::SaveParamaters() {
        std::string file_name = "tsdf.bin";
        std::cout << "Saving TSDF voxel grid values to disk." << std::endl;

        std::ofstream outFile(file_name, std::ios::binary | std::ios::out);

        float voxel_grid_dim_xf = (float)grid_num_x_;
        float voxel_grid_dim_yf = (float)grid_num_y_;
        float voxel_grid_dim_zf = (float)grid_num_z_;

        outFile.write((char*)&voxel_grid_dim_xf, sizeof(float));
        outFile.write((char*)&voxel_grid_dim_yf, sizeof(float));
        outFile.write((char*)&voxel_grid_dim_zf, sizeof(float));
        outFile.write((char*)&k_origin_x_, sizeof(float));
        outFile.write((char*)&k_origin_y_, sizeof(float));
        outFile.write((char*)&k_origin_z_, sizeof(float));
        outFile.write((char*)&k_grid_size_, sizeof(float));
        outFile.write((char*)&truncation_margin_, sizeof(float));

        for (int i = 0; i < grid_num_; ++i)
            outFile.write((char*)&data_[long long(i * attrib_num_) + tsdf_offset_],
                          sizeof(float));
        outFile.close();
    }
    */


}